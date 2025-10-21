variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "ecommerce-microservices"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "jenkins_instance_type" {
  description = "EC2 instance type for Jenkins"
  type        = string
  default     = "m7i-flex.large"
}

variable "sonarqube_instance_type" {
  description = "EC2 instance type for SonarQube"
  type        = string
  default     = "t3.small"
}

variable "eks_node_instance_type" {
  description = "EC2 instance type for EKS nodes"
  type        = string
  default     = "t3.small"
}

variable "eks_desired_capacity" {
  description = "Desired number of EKS nodes"
  type        = number
  default     = 1
}

variable "eks_min_capacity" {
  description = "Minimum number of EKS nodes"
  type        = number
  default     = 1
}

variable "eks_max_capacity" {
  description = "Maximum number of EKS nodes"
  type        = number
  default     = 4
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access Jenkins"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Change this in production
}
