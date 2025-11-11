variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "Digital Ocean region"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
}

variable "node_size" {
  description = "Size of the worker nodes"
  type        = string
}

variable "node_count" {
  description = "Number of worker nodes"
  type        = number
}

variable "auto_scale" {
  description = "Enable auto-scaling"
  type        = bool
  default     = true
}

variable "min_nodes" {
  description = "Minimum number of nodes"
  type        = number
}

variable "max_nodes" {
  description = "Maximum number of nodes"
  type        = number
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels to apply to Kubernetes resources"
  type        = map(string)
  default     = {}
}

variable "create_container_registry" {
  description = "Create Digital Ocean Container Registry"
  type        = bool
  default     = false
}

variable "registry_tier" {
  description = "Container registry subscription tier"
  type        = string
  default     = "basic" # starter, basic, professional
}
