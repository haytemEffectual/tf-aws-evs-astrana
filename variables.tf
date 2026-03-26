# ----------------------------------
# Variables

variable "aws_region" {
  description = "AWS region for the provider"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, prod)"
  validation {
    condition     = can(regex("^(dev|prod|staging)$", var.environment))
    error_message = "Environment must be one of: dev, prod, staging."
  }
  type    = string
  default = "dev"
}
variable "evs_vpc_cidr" {
  type = string
}

variable "workspaces_vpc_cidr" {
  type = string
}

# variable "on_premises_cidrs" {
#   description = "On-premises CIDR blocks"
#   type        = list(string)
# }

variable "transit_gateway_id" {
  description = "Transit Gateway ID"
  type        = string
}
variable "domain_name" {
  description = "Active Directory domain name"
  type        = string
}
variable "domain_short_name" {
  description = "Active Directory short name"
  type        = string
}

variable "default_ou" {
  description = "Default Organizational Unit for WorkSpaces"
  type        = string
}
variable "ad_dns_ips" {
  description = "DNS IP addresses of AD servers in EVS VPC"
  type        = list(string)
}
variable "ad_connector_creds_secret_arn" {
  description = "ARN of the Secrets Manager secret containing AD Connector credentials"
  type        = string
}

variable "map_tag" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "ws_clients_usernames" {
  description = "List of usernames for pearsonal WorkSpaces clients"
  type        = list(string)
}

variable "enable_personal_workspaces" {
  description = "Whether to create personal WorkSpaces instances"
  type        = bool
  default     = false
}

variable "user_access_url_sso" {
  description = "url for user access sso"
  type        = string
}

variable "ws_bundle" {
  type        = string
  description = "WorkSpaces bundle ID"
}

variable "workspace_running_mode" {
  description = "Running mode for WorkSpaces (ALWAYS_ON or AUTO_STOP)"
  type        = string
  validation {
    condition     = can(regex("^(ALWAYS_ON|AUTO_STOP)$", var.workspace_running_mode))
    error_message = "workspace_running_mode must be either ALWAYS_ON or AUTO_STOP."
  }
}

variable "workspace_access_properties" {
  description = "WorkSpaces access properties defining allowed device types"
  type        = map(string)
}

variable "self_service_permissions" {
  description = "Self-service permissions for WorkSpaces"
  type        = map(bool)
}