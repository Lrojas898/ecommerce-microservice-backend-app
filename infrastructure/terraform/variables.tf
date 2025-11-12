# ============================================================
# Digital Ocean Configuration
# ============================================================

variable "do_token" {
  description = "Digital Ocean API Token"
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "ecommerce-microservices"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

# ============================================================
# Kubernetes Cluster Configuration
# ============================================================

variable "cluster_region" {
  description = "Digital Ocean region for the Kubernetes cluster"
  type        = string
  default     = "nyc1" # New York 1 - closest to Latin America
  # Other options: nyc3, sfo3, sgp1, lon1, fra1, tor1
}

variable "cluster_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.31.9-do.5" # Updated to latest stable version available in DigitalOcean
}

variable "node_pool_size" {
  description = "Droplet size for worker nodes"
  type        = string
  default     = "s-4vcpu-8gb" # 8GB RAM, 4 vCPUs - $48/month per node
  # Options for 20GB+ total RAM:
  # s-2vcpu-4gb   - 4GB RAM, 2 vCPUs - $24/month (need 5+ nodes = $120/month)
  # s-4vcpu-8gb   - 8GB RAM, 4 vCPUs - $48/month (need 3 nodes = $144/month) ✓ RECOMMENDED
  # s-6vcpu-16gb  - 16GB RAM, 6 vCPUs - $96/month (need 2 nodes = $192/month)
}

variable "node_pool_count" {
  description = "Number of nodes in the default pool"
  type        = number
  default     = 3 # 3 nodes x 8GB = 24GB total RAM (exceeds 20GB requirement)
  validation {
    condition     = var.node_pool_count >= 2
    error_message = "Node pool must have at least 2 nodes for high availability."
  }
}

variable "node_pool_auto_scale" {
  description = "Enable auto-scaling for node pool"
  type        = bool
  default     = true
}

variable "node_pool_min_nodes" {
  description = "Minimum number of nodes when auto-scaling"
  type        = number
  default     = 3
}

variable "node_pool_max_nodes" {
  description = "Maximum number of nodes when auto-scaling"
  type        = number
  default     = 3 # Adjusted to match DigitalOcean account droplet limit
}

# ============================================================
# Monitoring Configuration
# ============================================================

variable "enable_monitoring" {
  description = "Enable Prometheus and Grafana monitoring stack"
  type        = bool
  default     = true
}

variable "enable_ingress_nginx" {
  description = "Enable NGINX Ingress Controller"
  type        = bool
  default     = true
}

variable "enable_cert_manager" {
  description = "Enable cert-manager for automatic SSL certificates"
  type        = bool
  default     = true
}

# ============================================================
# Networking Configuration
# ============================================================

variable "domain_name" {
  description = "Domain name for the application (optional)"
  type        = string
  default     = ""
}

variable "letsencrypt_email" {
  description = "Email for Let's Encrypt certificates"
  type        = string
  default     = ""
}

# ============================================================
# Tags and Labels
# ============================================================

variable "tags" {
  description = "Tags to apply to all resources"
  type        = list(string)
  default = [
    "ecommerce",
    "kubernetes",
    "terraform"
  ]
}

variable "labels" {
  description = "Labels to apply to Kubernetes resources"
  type        = map(string)
  default = {
    "managed-by" = "terraform"
    "project"    = "ecommerce-microservices"
  }
}
