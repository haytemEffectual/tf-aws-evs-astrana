terraform {
  required_version = ">= 1.6.0"
  required_providers {
    # awscc = {
    #   source  = "hashicorp/awscc"
    #   version = "~> 1.0"
    # }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.31"
    }
  }
  backend "s3" {
    # Backend configuration will be provided via terraform init flags or backend config file via GH Actions workflows
  }
}
