# Add Terraform main resources here

provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "usw1"
  region = "us-west-1"
}