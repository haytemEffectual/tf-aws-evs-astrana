################### IAM Role for WorkSpaces Service
# AWS WorkSpaces requires this specific role name to exist in the account
resource "aws_iam_role" "workspaces_default" {
  name = "workspaces_DefaultRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "workspaces.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "WorkSpaces Default Service Role"
    Environment = var.environment
  }
}

# Attach AWS managed policy for WorkSpaces self-service access
resource "aws_iam_role_policy_attachment" "workspaces_default_service_access" {
  role       = aws_iam_role.workspaces_default.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonWorkSpacesServiceAccess"
}

# Attach AWS managed policy for WorkSpaces self-service permissions
resource "aws_iam_role_policy_attachment" "workspaces_default_self_service_access" {
  role       = aws_iam_role.workspaces_default.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonWorkSpacesSelfServiceAccess"
}

################### Security Group for WorkSpaces
resource "aws_security_group" "workspaces" {
  name_prefix = "workspaces-"
  description = "Security group for WorkSpaces instances"
  vpc_id      = aws_vpc.workspaces.id
  tags = {
    Name        = "WorkSpaces-SG"
    Environment = "Production"
  }
}

# Ingress: allow WorkSpaces management within VPC
resource "aws_security_group_rule" "workspaces_ingress_management" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = [var.workspaces_vpc_cidr]
  security_group_id = aws_security_group.workspaces.id
  description       = "WorkSpaces Management"
}

# Egress: allow traffic to AD Connector SG
resource "aws_security_group_rule" "workspaces_egress_to_ad_connector" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.ad_connector.id
  security_group_id        = aws_security_group.workspaces.id
  description              = "To AD Connector"
}

# TODO: uncomment this after testing workspaces registrations throug AD to allow egress traffic to other destinations as needed
# # Egress: allow traffic to EVS VPC (for domain controllers and other resources)
# resource "aws_security_group_rule" "workspaces_egress_to_evs_vpc" {
#   type              = "egress"
#   from_port         = 0
#   to_port           = 65535
#   protocol          = "-1"  # All protocols
#   cidr_blocks       = [var.evs_vpc_cidr]
#   security_group_id = aws_security_group.workspaces.id
#   description       = "To EVS VPC resources"
# }

# # Egress: allow all internet access (if needed)
# resource "aws_security_group_rule" "workspaces_egress_internet" {
#   type              = "egress"
#   from_port         = 0
#   to_port           = 65535
#   protocol          = "-1"
#   cidr_blocks       = ["0.0.0.0/0"]
#   security_group_id = aws_security_group.workspaces.id
#   description       = "All internet access"
# }

# Egress: allow HTTPS outbound
# trivy:ignore:AVD-AWS-0104
resource "aws_security_group_rule" "workspaces_egress_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.workspaces.id
  description       = "HTTPS outbound"
}


#######################  Register Directory with WorkSpaces
resource "aws_workspaces_directory" "main" {
  depends_on = [
    time_sleep.wait_for_ad_connector,
    aws_iam_role.workspaces_default,
    aws_iam_role_policy_attachment.workspaces_default_service_access,
    aws_iam_role_policy_attachment.workspaces_default_self_service_access
  ]
  directory_id = aws_directory_service_directory.ad_connector.id
  subnet_ids   = aws_subnet.workspaces_vpc_subnets[*].id
  #TODO: need to review with Astrana team about actual settings for selfe service permissions on what users can do
  self_service_permissions {
    change_compute_type  = true
    increase_volume_size = true
    rebuild_workspace    = true
    restart_workspace    = true
    switch_running_mode  = true
  }
  #TODO: need to review with Astrana team about actual settings for workspace client access devices and permissions 
  workspace_access_properties {
    device_type_android    = "ALLOW"
    device_type_chromeos   = "ALLOW"
    device_type_ios        = "ALLOW"
    device_type_linux      = "DENY"
    device_type_osx        = "ALLOW"
    device_type_web        = "ALLOW"
    device_type_windows    = "ALLOW"
    device_type_zeroclient = "DENY"
  }
  #TODO: need to review with Astrana team about actual settings for workspace configuration properties.
  workspace_creation_properties {
    custom_security_group_id            = aws_security_group.workspaces.id
    default_ou                          = var.default_ou
    enable_internet_access              = true
    enable_maintenance_mode             = true
    user_enabled_as_local_administrator = false
  }
  tags = {
    Name        = "WorkSpaces-Directory"
    Environment = "Production"
  }
}





# Example WorkSpace
resource "aws_workspaces_workspace" "example" {
  depends_on   = [aws_workspaces_directory.main]
  directory_id = aws_directory_service_directory.ad_connector.id
  bundle_id    = "wsb-bh8rsxt14" # Standard bundle ID
  user_name    = "haytem.alsharif"
  workspace_properties {
    compute_type_name                         = "STANDARD"
    user_volume_size_gib                      = 50
    root_volume_size_gib                      = 80
    running_mode                              = "AUTO_STOP"
    running_mode_auto_stop_timeout_in_minutes = 15
  }
  tags = {
    Name        = "haytem.alsharif-workspace"
    Environment = "Production"
  }
}

