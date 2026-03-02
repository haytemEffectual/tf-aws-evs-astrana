# resource "aws_internet_gateway" "workspaces_igw" {
# 	vpc_id = data.aws_vpc.workspaces.id
# 	tags = merge(
# 		{
# 			Name        = "workspaces-igw"
# 			Environment = var.environment
# 		}
# 	)
# }

# resource "aws_subnet" "workspaces_vpc_pub_subnet" {
#   vpc_id            = data.aws_vpc.workspaces.id
#   cidr_block        = cidrsubnet(var.workspaces_vpc_cidr, 4, 2)
#   availability_zone = data.aws_availability_zones.available.names[0]
#   map_public_ip_on_launch = true
#   tags = {
#     Name = "usw${substr(data.aws_availability_zones.available.names[0], -2, 2)}-workspaces-pub-subnet"
#   }
# }

# resource "aws_route_table" "workspaces_vpc_public_rt" {
#   vpc_id = data.aws_vpc.workspaces.id
#   tags = {
#     Name = "workspaces-vpc-public-rt"
#   }
# }

# resource "aws_route" "workspaces_public_internet" {
#   route_table_id         = aws_route_table.workspaces_vpc_public_rt.id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = aws_internet_gateway.workspaces_igw.id
# }  

# resource "aws_route_table_association" "workspaces_vpc_pub_subnet_rt" {
#   subnet_id      = aws_subnet.workspaces_vpc_pub_subnet.id
#   route_table_id = aws_route_table.workspaces_vpc_public_rt.id
# }

# resource "aws_eip" "workspaces_nat_eip" {
#   domain = "vpc"
#   tags = {
#     Name = "workspaces-nat-eip"
#   }
# }

# resource "aws_nat_gateway" "workspaces_nat_gw" {
#   allocation_id = aws_eip.workspaces_nat_eip.id
#   subnet_id     = aws_subnet.workspaces_vpc_pub_subnet.id
#   tags = {
#     Name = "workspaces-nat-gw"
#   }
#   depends_on = [aws_internet_gateway.workspaces_igw] 
# }


# #========================================================================================================
# ########   routing Workspaces to the internet via NAT GW   #############
# resource "aws_route" "workspaces_default_internet" {
#   route_table_id         = aws_route_table.workspaces_vpc_private_rt.id
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id =      aws_nat_gateway.workspaces_nat_gw.id
#   depends_on = [aws_internet_gateway.workspaces_igw]
# }
