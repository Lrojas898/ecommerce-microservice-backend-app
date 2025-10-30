variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "ecommerce-microservices"
}

variable "environment" {
  description = "Environment (dev, stage, prod)"
  type        = string
  default     = "dev"
}

variable "subnet_ids" {
  description = "List of subnet IDs for RDS subnet group"
  type        = list(string)
}

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

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "ecommerce_users"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "ecommerce_user"
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