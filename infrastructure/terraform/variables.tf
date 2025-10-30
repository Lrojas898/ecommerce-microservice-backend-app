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
  description = "EC2 instance type for Jenkins (also runs SonarQube via Docker Compose)"
  type        = string
  default     = "m7i-flex.large"
}

variable "jenkins_agent_instance_type" {
  description = "EC2 instance type for Jenkins Agent"
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

# RDS MySQL Variables
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS instance (GB)"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage for RDS instance (GB)"
  type        = number
  default     = 100
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when deleting"
  type        = bool
  default     = true
}
