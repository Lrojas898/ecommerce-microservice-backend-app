terraform {
  required_version = ">= 1.5.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.34.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12.0"
    }
  }

  # Backend configuration for storing state in DigitalOcean Spaces
  # Spaces is S3-compatible, so we use the S3 backend
  backend "s3" {
    bucket = "ecommerce-terraform-state"
    key    = "terraform.tfstate"
    region = "us-east-1" # Required by Terraform, but not used by Spaces

    # DigitalOcean Spaces endpoint
    endpoint = "https://nyc3.digitaloceanspaces.com"

    # Skip AWS-specific validations
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true

    # Force path-style addressing (required for Spaces)
    force_path_style = true
  }
}
