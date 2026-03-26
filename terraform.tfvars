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
map_tag                       = { "map-migrated" : "migSHUGRNMVMC" } # this is used by MPE id identified by MAP 2.0 tagging program  


# Workspaces config - you can customize these based on your needs
enable_personal_workspaces = true
workspace_running_mode     = "ALWAYS_ON" # or "AUTO_STOP"
ws_clients_usernames = [
  "HAlsharif",
  "JNgo",
  "MCueto"
]
user_access_url_sso = "https://launcher.myapps.microsoft.com/api/signin/e348f26f-fa00-4c81-81f3-caf7d427b9ec?tenantId=f9c59c38-400c-4a74-9b2d-d0c26518f803"
ws_bundle           = "wsb-vz2zm0x4t" # this is the bundle for Windows 10 with 4 vCPU and 16 GB RAM, you can choose other bundles based on your needs, refer to AWS documentation for available bundles and their IDs

workspace_access_properties = {
  "device_type_android" : "ALLOW"
  "device_type_chromeos" : "ALLOW"
  "device_type_ios" : "ALLOW"
  "device_type_linux" : "DENY"
  "device_type_osx" : "ALLOW"
  "device_type_web" : "ALLOW"
  "device_type_windows" : "ALLOW"
  "device_type_zeroclient" : "DENY"
}

self_service_permissions = {
  "change_compute_type" : true
  "increase_volume_size" : true
  "rebuild_workspace" : true
  "restart_workspace" : true
  "switch_running_mode" : true
}