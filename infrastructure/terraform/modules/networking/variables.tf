variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "enable_ingress_nginx" {
  description = "Enable NGINX Ingress Controller"
  type        = bool
  default     = true
}

variable "enable_cert_manager" {
  description = "Enable cert-manager for SSL certificates"
  type        = bool
  default     = true
}

variable "letsencrypt_email" {
  description = "Email for Let's Encrypt certificates"
  type        = string
  default     = ""
}

variable "cluster_dependency" {
  description = "Dependency on cluster creation"
  type        = any
  default     = null
}
