# ============================================================
# E-Commerce Microservices Infrastructure
# ============================================================
# This Terraform configuration provisions a Kubernetes cluster
# on Digital Ocean with monitoring, ingress, and SSL support
# ============================================================

locals {
  common_tags = concat(var.tags, [
    var.environment,
    "managed-by-terraform"
  ])

  common_labels = merge(var.labels, {
    environment = var.environment
    project     = var.project_name
  })
}

# ============================================================
# Kubernetes Cluster Module
# ============================================================

module "kubernetes_cluster" {
  source = "./modules/kubernetes"

  project_name       = var.project_name
  environment        = var.environment
  region             = var.cluster_region
  kubernetes_version = var.cluster_version

  node_size  = var.node_pool_size
  node_count = var.node_pool_count
  auto_scale = var.node_pool_auto_scale
  min_nodes  = var.node_pool_min_nodes
  max_nodes  = var.node_pool_max_nodes

  tags   = local.common_tags
  labels = local.common_labels

  # Container Registry (optional - currently using Docker Hub)
  create_container_registry = false
  registry_tier             = "basic"
}

# ============================================================
# Networking Module (Ingress + SSL)
# ============================================================

module "networking" {
  source = "./modules/networking"

  project_name = var.project_name
  environment  = var.environment

  enable_ingress_nginx = var.enable_ingress_nginx
  enable_cert_manager  = var.enable_cert_manager
  letsencrypt_email    = var.letsencrypt_email

  cluster_dependency = module.kubernetes_cluster.cluster_id
}

# ============================================================
# Monitoring Module (Placeholder for future implementation)
# ============================================================

# module "monitoring" {
#   source = "./modules/monitoring"
#
#   project_name       = var.project_name
#   environment        = var.environment
#   enable_monitoring  = var.enable_monitoring
#
#   cluster_dependency = module.kubernetes_cluster.cluster_id
# }
