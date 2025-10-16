variable "project_name" {
  description = "Project name"
  type        = string
}

variable "jenkins_instance_type" {
  description = "EC2 instance type for Jenkins"
  type        = string
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access Jenkins"
  type        = list(string)
}
