# Here will be the main tf code for network infrastructure related resources
### TODO: pre-requisite variables should be defined in tfvars file such as:
##    - VPC CIDR blocks Transit 
##    - TGW Gateway ID 
##    - AD details (domain name, DNS IPs, etc)
## 
## This file will be configuring and creating the following resources: 
##  1- VPC1 & VPC2: VPC1 for (EVS) and VPC2 for (WorkSpaces)
##  2- VPC Peering: between VPC1 (EVS) and VPC2 (WorkSpaces)
##  3- Subnets in both VPCs
##  4- Route tables
##      a. create route tables and associations for both VPCs
##      b. add peering routes to both VPCs route tables and TGW routes for on-premises access
##  5- DHCP Options Set for both VPCs to point to AD DNS IPs
##  6- (optional) public subn for NAT Gateway in workspaces VPC
##  7- (optional) NAT Gateway in WorkSpaces VPC
##  8- TGW attachments for both VPCs

#####################################################################################
################ CREATING VPCs for the required infrastructure ######################
#####################################################################################
# TODO: update the VPC ids - remove the PVC resources when apply this in prod, PVCs should be pre-existed and has the following tags:
# TODO:  for evs-vpc --> Application="evs" and for workspaces-vpc --> Application="workspaces"
# TODO: you will only need to keep the datasources to read the existing VPC ids 
resource "aws_vpc" "evs" {
  cidr_block           = var.evs_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Application = "evs"
    Name        = "evs-vpc"
  }
}

resource "aws_vpc" "workspaces" {
  cidr_block           = var.workspaces_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Application = "workspaces"
    Name        = "workspaces-vpc"
  }
}

# Data sources to read the VPC IDs -- those datassources were added to read the pre-existed VPCs in prod env in case they are not created by this code.
data "aws_vpc" "evs" {
  depends_on = [aws_vpc.evs]
  filter {
    name   = "tag:Application"
    values = ["evs"]
  }
}

data "aws_vpc" "workspaces" {
  depends_on = [aws_vpc.workspaces]
  filter {
    name   = "tag:Application"
    values = ["workspaces"]
  }
}


#####################################################################################
############################# CONFIGURING VPC PEERING CONNECTION ####################
#####################################################################################
####  Create VPC peering connection between VPC1 (EVS) and VPC2 (WorkSpaces)
resource "aws_vpc_peering_connection" "evsvpc_workspacesvpc" {
  vpc_id      = data.aws_vpc.evs.id
  peer_vpc_id = data.aws_vpc.workspaces.id
  peer_region = "us-west-2"
  auto_accept = true
  tags = {
    Name        = "Evs-workspaces"
    Environment = var.environment
  }
}
#### Enable DNS resolution for VPC peering
resource "aws_vpc_peering_connection_options" "evsvpc_workspacesvpc" {
  vpc_peering_connection_id = aws_vpc_peering_connection.evsvpc_workspacesvpc.id
  requester {
    allow_remote_vpc_dns_resolution = true
  }
  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

#####################################################################################
########################## CONFIGURING SUBNETS ON BOTH VPCs   #######################
#####################################################################################
#### Get available AZs in the region
data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "region-name"
    values = ["us-west-2"]
  }
}
#### create subnets in evs-vpc and workspaces-vpc on AZ1 and AZ2
resource "aws_subnet" "evs_vpc_subnets" {
  count             = 1 # Number of subnets --> Ajust this number based on the number of subnets needed
  vpc_id            = data.aws_vpc.evs.id
  cidr_block        = cidrsubnet(var.evs_vpc_cidr, 7, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  tags = {
    Name = "evs-vpc-subnet-${count.index + 1}"
  }
}
resource "aws_subnet" "workspaces_vpc_subnets" {
  count             = 2
  vpc_id            = data.aws_vpc.workspaces.id
  cidr_block        = cidrsubnet(var.workspaces_vpc_cidr, 4, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  tags = {
    Name = "workspaces-vpc-subnet-${count.index + 1}"
  }
}



#####################################################################################
###################### CONFIGURING ROUTE TABLES ON BOTH VPCs  #######################
#####################################################################################
#### ctreate route tables for EVS VPC 
resource "aws_route_table" "evs_vpc_private_rt" {
  vpc_id = data.aws_vpc.evs.id
  tags = {
    Name = "evs-vpc-private-rt"
  }
}

#### ctreate route tables for WorkSpaces VPC
resource "aws_route_table" "workspaces_vpc_private_rt" {
  vpc_id = data.aws_vpc.workspaces.id
  tags = {
    Name = "workspaces-vpc-private-rt"
  }
}


#### Associate subnets with route tables in evs voc
resource "aws_route_table_association" "evs_vpc_subnets" {
  count          = length(aws_subnet.evs_vpc_subnets)
  subnet_id      = aws_subnet.evs_vpc_subnets[count.index].id
  route_table_id = aws_route_table.evs_vpc_private_rt.id
}

#### Associate subnets with route tables in workspaces voc
resource "aws_route_table_association" "workspaces_vpc_subnets" {
  count          = length(aws_subnet.workspaces_vpc_subnets)
  subnet_id      = aws_subnet.workspaces_vpc_subnets[count.index].id
  route_table_id = aws_route_table.workspaces_vpc_private_rt.id
}



#### Add peering routes to VPC1 (EVS) route tables
resource "aws_route" "evsvpc_to_workspacesvpc" {
  route_table_id            = aws_route_table.evs_vpc_private_rt.id
  destination_cidr_block    = var.workspaces_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.evsvpc_workspacesvpc.id
}


#### Add peering routes to VPC2 (WorkSpaces) route tables
resource "aws_route" "workspacesvpc_to_evsvpc" {
  route_table_id            = aws_route_table.workspaces_vpc_private_rt.id
  destination_cidr_block    = var.evs_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.evsvpc_workspacesvpc.id
}

# TODO: uncomment the folloing section after Asstrana team creates the TGW and it is ready to use 
# #### Add TGW routes on evs vpc for on-premises access
# resource "aws_route" "evsvpc_default_route" {
#   route_table_id         = aws_route_table.evs_vpc_private_rt.id
#   destination_cidr_block = "0.0.0.0/0"
#   transit_gateway_id     = var.transit_gateway_id
#   depends_on = [
#     data.aws_ec2_transit_gateway_vpc_attachments.evs,
#     aws_ec2_transit_gateway_vpc_attachment.evs-vpc
#   ]
# }

# #### Add TGW routes on workspaces vpc for on-premises access
# resource "aws_route" "workspacesvpc_default_route" {
#   route_table_id         = aws_route_table.workspaces_vpc_private_rt.id
#   destination_cidr_block = "0.0.0.0/0"
#   transit_gateway_id     = var.transit_gateway_id
#   depends_on = [
#     data.aws_ec2_transit_gateway_vpc_attachments.workspaces,
#     aws_ec2_transit_gateway_vpc_attachment.workspaces
#   ]
# }

# #TODO: uncomment the folloing section after Asstrana team creates AD and provides the DNS IPs
# #####################################################################################
# ###################### CONFIGURING DHCP OPTIONS ON BOTH VPCs  #######################
# #####################################################################################
# #### Create DHCP Options Set for workspaces VPC to point to EVS VPC AD DNS IPs
# resource "aws_vpc_dhcp_options" "workspaces_vpc" {
#   domain_name         = var.domain_name
#   domain_name_servers = var.ad_dns_ips
#   tags = {
#     Name        = "workspaces-vpc-DHCP"
#     Environment = "Production"
#   }
# }

# # Associate DHCP Options with workspaces VPC
# resource "aws_vpc_dhcp_options_association" "workspaces_vpc" {
#   vpc_id          = data.aws_vpc.workspaces.id
#   dhcp_options_id = aws_vpc_dhcp_options.workspaces_vpc.id
# }


# #TODO: uncomment the folloing section after Asstrana team creates the TGW and it is ready to use 
#####################################################################################
######################### TRANSIT GATEWAY CONFIGURATION ##############################
#####################################################################################

# # Get existing TGW VPC attachment for EVS-VPC (if exists)
# data "aws_ec2_transit_gateway_vpc_attachments" "evs" {
#   filter {
#     name   = "vpc-id"
#     values = [data.aws_vpc.evs.id]
#   }
#   filter {
#     name   = "transit-gateway-id"
#     values = [var.transit_gateway_id]
#   }
# }

# # Create TGW VPC attachment for EVS-VPC (if it doesn't exist)
# resource "aws_ec2_transit_gateway_vpc_attachment" "evs-vpc" {
#   count = length(data.aws_ec2_transit_gateway_vpc_attachments.evs.ids) == 0 ? 1 : 0
#   # You'll need to provide EVS VPC TGW subnet IDs
#   subnet_ids         = aws_subnet.evs_vpc_subnets[*].id
#   transit_gateway_id = var.transit_gateway_id
#   vpc_id             = data.aws_vpc.evs.id
#   tags = {
#     Name        = "evs-vpc-TGW-Attachment"
#     Environment = var.environment
#   }
# }

# # Get existing TGW VPC attachment for workspaces-VPC (if exists)
# data "aws_ec2_transit_gateway_vpc_attachments" "workspaces" {
#   filter {
#     name   = "vpc-id"
#     values = [data.aws_vpc.workspaces.id]
#   }
#   filter {
#     name   = "transit-gateway-id"
#     values = [var.transit_gateway_id]
#   }
# }
# # Create TGW VPC attachment for workspaces-VPC (if it doesn't exist)
# resource "aws_ec2_transit_gateway_vpc_attachment" "workspaces" {
#   count = length(data.aws_ec2_transit_gateway_vpc_attachments.workspaces.ids) == 0 ? 1 : 0
#   # You'll need to provide EVS VPC TGW subnet IDs
#   subnet_ids         = aws_subnet.workspaces_vpc_subnets[*].id
#   transit_gateway_id = var.transit_gateway_id
#   vpc_id             = data.aws_vpc.workspaces.id
#   tags = {
#     Name        = "workspaces-vpc-TGW-Attachment"
#     Environment = var.environment
#   }
# }



