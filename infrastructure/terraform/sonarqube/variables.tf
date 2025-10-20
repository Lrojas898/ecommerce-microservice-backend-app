variable "project_name" {
  description = "Project name"
  type        = string
}

variable "sonarqube_instance_type" {
  description = "EC2 instance type for SonarQube"
  type        = string
  default     = "t3.small"
}
