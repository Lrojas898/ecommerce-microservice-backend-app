terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket         = "ecommerce-terraform-state-020951019497"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    dynamodb_table = "ecommerce-terraform-locks"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
