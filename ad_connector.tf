## Here will be the main tf code for AD Connector related resources
## This file will be configuring and creating the following resources: 
## 1- AD Connector in WorkSpaces VPC
## 2- Security Group for AD Connector in WorkSpaces VPC
## 3- Security Group for WorkSpaces instances

# Data source to retrieve AD Connector service account credentials from Secrets Manager
data "aws_secretsmanager_secret_version" "ad_connector_sa" {
  secret_id = var.ad_connector_creds_secret_arn
}

#####################################################################################
################          CONFIGURING AD CONNECTOR             ######################
#####################################################################################

resource "aws_directory_service_directory" "ad_connector" {
  name        = var.domain_name
  short_name  = var.domain_short_name
  description = "AD Connector for WorkSpaces"
  size        = "Large"
  type        = "ADConnector"
  password    = jsondecode(data.aws_secretsmanager_secret_version.ad_connector_sa.secret_string)["ad_connector_password"]
  connect_settings {
    vpc_id            = aws_vpc.workspaces.id
    subnet_ids        = aws_subnet.workspaces_vpc_subnets[*].id
    customer_dns_ips  = var.ad_dns_ips
    customer_username = jsondecode(data.aws_secretsmanager_secret_version.ad_connector_sa.secret_string)["ad_connector_username"]
  }
  tags = merge(
    {
      Name        = "WorkSpaces-AD-Connector"
      Environment = var.environment
    },
    var.map_tag
  )
}

# Wait for AD Connector to be activated
resource "time_sleep" "wait_for_ad_connector" {
  depends_on      = [aws_directory_service_directory.ad_connector]
  create_duration = "420s" # Wait 7 minutes for AD Connector to be ready
}

#####################################################################################
################         SECURITY GROUP FOR AD CONNECTOR       ######################
#####################################################################################
resource "aws_ec2_tag" "ad_connector_sg_name" {
  depends_on  = [time_sleep.wait_for_ad_connector]
  resource_id = aws_directory_service_directory.ad_connector.security_group_id
  key         = "Name"
  value       = "workspaces-ad-connector-sg"
}

# Egress rules for AD Connector security group
# DNS TCP to EVS VPC
resource "aws_security_group_rule" "ad_connector_dns_tcp" {
  depends_on        = [time_sleep.wait_for_ad_connector]
  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  cidr_blocks       = [var.evs_vpc_cidr]
  security_group_id = aws_directory_service_directory.ad_connector.security_group_id
  description       = "DNS to EVS VPC"
}

# DNS UDP to EVS VPC
resource "aws_security_group_rule" "ad_connector_dns_udp" {
  depends_on        = [time_sleep.wait_for_ad_connector]
  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = [var.evs_vpc_cidr]
  security_group_id = aws_directory_service_directory.ad_connector.security_group_id
  description       = "DNS UDP to EVS VPC"
}

# Kerberos TCP to EVS VPC
resource "aws_security_group_rule" "ad_connector_kerberos_tcp" {
  depends_on        = [time_sleep.wait_for_ad_connector]
  type              = "egress"
  from_port         = 88
  to_port           = 88
  protocol          = "tcp"
  cidr_blocks       = [var.evs_vpc_cidr]
  security_group_id = aws_directory_service_directory.ad_connector.security_group_id
  description       = "Kerberos to EVS VPC"
}

# Kerberos UDP to EVS VPC
resource "aws_security_group_rule" "ad_connector_kerberos_udp" {
  depends_on        = [time_sleep.wait_for_ad_connector]
  type              = "egress"
  from_port         = 88
  to_port           = 88
  protocol          = "udp"
  cidr_blocks       = [var.evs_vpc_cidr]
  security_group_id = aws_directory_service_directory.ad_connector.security_group_id
  description       = "Kerberos UDP to DC in EVS VPC"
}

# Network time protocol
resource "aws_security_group_rule" "ad_connector_ntp" {
  depends_on        = [time_sleep.wait_for_ad_connector]
  type              = "egress"
  from_port         = 123
  to_port           = 123
  protocol          = "udp"
  cidr_blocks       = [var.evs_vpc_cidr]
  security_group_id = aws_directory_service_directory.ad_connector.security_group_id
  description       = "Network time protocol to DC in EVS VPC"
}

# RPC Endpoint Mapper to EVS VPC
resource "aws_security_group_rule" "ad_connector_rpc" {
  depends_on        = [time_sleep.wait_for_ad_connector]
  type              = "egress"
  from_port         = 135
  to_port           = 135
  protocol          = "tcp"
  cidr_blocks       = [var.evs_vpc_cidr]
  security_group_id = aws_directory_service_directory.ad_connector.security_group_id
  description       = "RPC Endpoint Mapper to DC in EVS VPC"
}

# LDAP TCP to EVS VPC
resource "aws_security_group_rule" "ad_connector_ldap_tcp" {
  depends_on        = [time_sleep.wait_for_ad_connector]
  type              = "egress"
  from_port         = 389
  to_port           = 389
  protocol          = "tcp"
  cidr_blocks       = [var.evs_vpc_cidr]
  security_group_id = aws_directory_service_directory.ad_connector.security_group_id
  description       = "LDAP to DC in EVS VPC"
}

# LDAP UDP to EVS VPC
resource "aws_security_group_rule" "ad_connector_ldap_udp" {
  depends_on        = [time_sleep.wait_for_ad_connector]
  type              = "egress"
  from_port         = 389
  to_port           = 389
  protocol          = "udp"
  cidr_blocks       = [var.evs_vpc_cidr]
  security_group_id = aws_directory_service_directory.ad_connector.security_group_id
  description       = "LDAP UDP to DC in EVS VPC"
}

# SMB to EVS VPC
resource "aws_security_group_rule" "ad_connector_smb_445_tcp" {
  depends_on        = [time_sleep.wait_for_ad_connector]
  type              = "egress"
  from_port         = 445
  to_port           = 445
  protocol          = "tcp"
  cidr_blocks       = [var.evs_vpc_cidr]
  security_group_id = aws_directory_service_directory.ad_connector.security_group_id
  description       = "SMB to DC in EVS VPC"
}

resource "aws_security_group_rule" "ad_connector_smb_445_udp" {
  depends_on        = [time_sleep.wait_for_ad_connector]
  type              = "egress"
  from_port         = 445
  to_port           = 445
  protocol          = "udp"
  cidr_blocks       = [var.evs_vpc_cidr]
  security_group_id = aws_directory_service_directory.ad_connector.security_group_id
  description       = "SMB to DC in EVS VPC"
}

# Kerberos Change Password to EVS VPC
resource "aws_security_group_rule" "ad_connector_kerberos_change_pwd_tcp" {
  depends_on        = [time_sleep.wait_for_ad_connector]
  type              = "egress"
  from_port         = 464
  to_port           = 464
  protocol          = "tcp"
  cidr_blocks       = [var.evs_vpc_cidr]
  security_group_id = aws_directory_service_directory.ad_connector.security_group_id
  description       = "Kerberos Change Password "
}

resource "aws_security_group_rule" "ad_connector_kerberos_change_pwd_udp" {
  depends_on        = [time_sleep.wait_for_ad_connector]
  type              = "egress"
  from_port         = 464
  to_port           = 464
  protocol          = "udp"
  cidr_blocks       = [var.evs_vpc_cidr]
  security_group_id = aws_directory_service_directory.ad_connector.security_group_id
  description       = "Kerberos Change Password"
}

# LDAPS to EVS VPC
resource "aws_security_group_rule" "ad_connector_ldaps" {
  depends_on        = [time_sleep.wait_for_ad_connector]
  type              = "egress"
  from_port         = 636
  to_port           = 636
  protocol          = "tcp"
  cidr_blocks       = [var.evs_vpc_cidr]
  security_group_id = aws_directory_service_directory.ad_connector.security_group_id
  description       = "LDAPS to DC in EVS VPC"
}

# Global Catalog to EVS VPC
resource "aws_security_group_rule" "ad_connector_global_catalog" {
  depends_on        = [time_sleep.wait_for_ad_connector]
  type              = "egress"
  from_port         = 3268
  to_port           = 3269
  protocol          = "tcp"
  cidr_blocks       = [var.evs_vpc_cidr]
  security_group_id = aws_directory_service_directory.ad_connector.security_group_id
  description       = "Global Catalog to DC in EVS VPC"
}

# Dynamic RPC to EVS VPC
resource "aws_security_group_rule" "ad_connector_dynamic_rpc" {
  depends_on        = [time_sleep.wait_for_ad_connector]
  type              = "egress"
  from_port         = 1024
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = [var.evs_vpc_cidr]
  security_group_id = aws_directory_service_directory.ad_connector.security_group_id
  description       = "Dynamic RPC to DC in EVS VPC"
}

resource "aws_security_group_rule" "ad_connector_vpc_clients_access" {
  depends_on        = [time_sleep.wait_for_ad_connector]
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.workspaces_vpc_cidr]
  security_group_id = aws_directory_service_directory.ad_connector.security_group_id
  description       = "Allow all traffic from WorkSpaces VPC"
}

