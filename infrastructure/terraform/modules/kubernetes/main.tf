# ============================================================
# Digital Ocean Kubernetes Cluster
# ============================================================

resource "digitalocean_kubernetes_cluster" "main" {
  name    = "${var.project_name}-${var.environment}-cluster"
  region  = var.region
  version = var.kubernetes_version
  tags    = var.tags

  node_pool {
    name       = "worker-pool"
    size       = var.node_size
    node_count = var.node_count
    auto_scale = var.auto_scale
    min_nodes  = var.auto_scale ? var.min_nodes : null
    max_nodes  = var.auto_scale ? var.max_nodes : null
    tags       = var.tags
    labels     = var.labels
  }

  maintenance_policy {
    start_time = "04:00" # 4 AM UTC
    day        = "sunday"
  }

  lifecycle {
    prevent_destroy = false # Set to true in production
  }
}

# ============================================================
# Namespaces
# ============================================================

resource "kubernetes_namespace" "prod" {
  metadata {
    name = "prod"
    labels = merge(var.labels, {
      environment = "production"
    })
  }

  depends_on = [digitalocean_kubernetes_cluster.main]
}

resource "kubernetes_namespace" "staging" {
  metadata {
    name = "staging"
    labels = merge(var.labels, {
      environment = "staging"
    })
  }

  depends_on = [digitalocean_kubernetes_cluster.main]
}

resource "kubernetes_namespace" "tracing" {
  metadata {
    name = "tracing"
    labels = merge(var.labels, {
      purpose = "distributed-tracing"
    })
  }

  depends_on = [digitalocean_kubernetes_cluster.main]
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = merge(var.labels, {
      purpose = "monitoring"
    })
  }

  depends_on = [digitalocean_kubernetes_cluster.main]
}

# ============================================================
# Storage Classes
# ============================================================

resource "kubernetes_storage_class" "do_block_storage" {
  metadata {
    name = "do-block-storage"
  }

  storage_provisioner = "dobs.csi.digitalocean.com"
  reclaim_policy      = "Retain"
  parameters = {
    type = "pd-ssd"
  }
  allow_volume_expansion = true

  depends_on = [digitalocean_kubernetes_cluster.main]
}

# ============================================================
# Digital Ocean Container Registry Integration (Optional)
# ============================================================

resource "digitalocean_container_registry" "main" {
  count                  = var.create_container_registry ? 1 : 0
  name                   = "${var.project_name}-registry"
  subscription_tier_slug = var.registry_tier
  region                 = var.region
}

resource "digitalocean_container_registry_docker_credentials" "main" {
  count          = var.create_container_registry ? 1 : 0
  registry_name  = digitalocean_container_registry.main[0].name
  write          = true
  expiry_seconds = 31536000 # 1 year
}

# Create Kubernetes secret for pulling images from DO registry
resource "kubernetes_secret" "docker_registry" {
  count = var.create_container_registry ? 1 : 0

  metadata {
    name      = "do-registry-credentials"
    namespace = "prod"
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = digitalocean_container_registry_docker_credentials.main[0].docker_credentials
  }

  depends_on = [
    kubernetes_namespace.prod,
    digitalocean_container_registry_docker_credentials.main
  ]
}
