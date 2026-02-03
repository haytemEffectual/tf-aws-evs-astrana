# here will be project specific variables
aws_region            = "us-west-2"
environment           = "prod"
on_premises_cidrs      = ["10.1.6.0/24","10.1.7.0/24"] 
transit_gateway_id    = "tgw-007d8d4536850ff23"
evs_vpc_cidr          = "10.210.0.0/17" # CIDR for EVS VPC,        prefix will be added +4 bits for subnets
workspaces_vpc_cidr   = "10.211.0.0/20" # CIDR for WorkSpaces VPC, prefix will be added +4 bits for subnets
domain_name           = "corp.Astrana.com"
domain_short_name     = "CORP"
default_ou            = "OU=WorkSpaces,DC=corp,DC=astrana,DC=com"
ad_dns_ips            = ["10.1.10.10", "10.1.10.11"] # TODO: wating on Astrana health to provide
ad_connector_username = "svc-adconnector"
# ad_connector_password = "000000000000"                # TODO: this should be provided via GitHub Secrets"