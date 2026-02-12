# here will be project specific variables
aws_region  = "us-west-2"
environment = "prod"
# on_premises_cidrs     = ["10.1.6.0/24", "10.1.7.0/24"]
transit_gateway_id            = "tgw-007d8d4536850ff23"
evs_vpc_cidr                  = "10.210.0.0/17" # CIDR for EVS VPC,        prefix will be added +4 bits for subnets
workspaces_vpc_cidr           = "10.211.0.0/20" # CIDR for WorkSpaces VPC, prefix will be added +4 bits for subnets
domain_name                   = "alliedipa.int"
domain_short_name             = "alliedipa"
default_ou                    = "OU=Workspaces,DC=alliedipa,DC=int"
ad_dns_ips                    = ["10.210.20.10", "10.1.7.12", "10.1.7.13"] # 
ad_connector_creds_secret_arn = "arn:aws:secretsmanager:us-west-2:747025127203:secret:ad_connector_sa-j5Ducj"
map_tag                      = {"map-migrated":"migSHUGRNMVMC"} # this is used by MPE id identified by MAP 2.0 tagging program  