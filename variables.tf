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

variable "on_premises_cidrs" {
  description = "On-premises CIDR blocks"
  type        = list(string)
}
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
variable "ad_connector_username" {
  description = "Service account username for AD Connector"
  type        = string
}

# TODO: Uncomment this when password is available and provide the AD Connector password via GitHub Secrets
# variable "ad_connector_password" {
#   description = "Service account password for AD Connector"
#   type        = string
#   sensitive   = true
# }


