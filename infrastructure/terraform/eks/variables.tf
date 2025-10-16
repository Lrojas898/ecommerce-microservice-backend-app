variable "project_name" {
  description = "Project name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "eks_node_instance_type" {
  description = "EC2 instance type for EKS nodes"
  type        = string
}

variable "eks_desired_capacity" {
  description = "Desired number of EKS nodes"
  type        = number
}

variable "eks_min_capacity" {
  description = "Minimum number of EKS nodes"
  type        = number
}

variable "eks_max_capacity" {
  description = "Maximum number of EKS nodes"
  type        = number
}

variable "subnet_ids" {
  description = "Subnet IDs for EKS"
  type        = list(string)
}
