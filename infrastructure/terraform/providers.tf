provider "digitalocean" {
  token = var.do_token
}

provider "kubernetes" {
  host  = module.kubernetes_cluster.cluster_endpoint
  token = module.kubernetes_cluster.cluster_token
  cluster_ca_certificate = base64decode(
    module.kubernetes_cluster.cluster_ca_certificate
  )
}

provider "helm" {
  kubernetes {
    host  = module.kubernetes_cluster.cluster_endpoint
    token = module.kubernetes_cluster.cluster_token
    cluster_ca_certificate = base64decode(
      module.kubernetes_cluster.cluster_ca_certificate
    )
  }
}
