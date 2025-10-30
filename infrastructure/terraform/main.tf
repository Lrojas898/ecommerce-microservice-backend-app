# Get default VPC and subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Get AWS account ID
data "aws_caller_identity" "current" {}

# ECR Module
module "ecr" {
  source = "./ecr"

  project_name   = var.project_name
  aws_region     = var.aws_region
  aws_account_id = data.aws_caller_identity.current.account_id
}

# Jenkins Module - Managed by Terraform but protected from accidental destruction
module "jenkins" {
  source = "./jenkins"

  project_name          = var.project_name
  jenkins_instance_type = var.jenkins_instance_type
  allowed_cidr_blocks   = var.allowed_cidr_blocks
}

# EKS Module
module "eks" {
  source = "./eks"

  project_name           = var.project_name
  aws_region             = var.aws_region
  eks_node_instance_type = var.eks_node_instance_type
  eks_desired_capacity   = var.eks_desired_capacity
  eks_min_capacity       = var.eks_min_capacity
  eks_max_capacity       = var.eks_max_capacity
  subnet_ids             = data.aws_subnets.default.ids
}

# RDS PostgreSQL Module
module "rds" {
  source = "./rds"

  project_name              = var.project_name
  environment              = var.environment
  subnet_ids               = data.aws_subnets.default.ids
  db_instance_class        = var.db_instance_class
  db_allocated_storage     = var.db_allocated_storage
  db_max_allocated_storage = var.db_max_allocated_storage
  backup_retention_period  = var.backup_retention_period
  deletion_protection      = var.deletion_protection
  skip_final_snapshot      = var.skip_final_snapshot
}
