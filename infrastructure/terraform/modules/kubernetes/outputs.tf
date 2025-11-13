output "cluster_id" {
  description = "ID of the Kubernetes cluster"
  value       = digitalocean_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "Name of the Kubernetes cluster"
  value       = digitalocean_kubernetes_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint for the Kubernetes cluster"
  value       = digitalocean_kubernetes_cluster.main.endpoint
  sensitive   = true
}

output "cluster_token" {
  description = "Token for accessing the Kubernetes cluster"
  value       = digitalocean_kubernetes_cluster.main.kube_config[0].token
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "CA certificate for the Kubernetes cluster"
  value       = digitalocean_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

output "kubeconfig" {
  description = "Raw kubeconfig for the cluster"
  value       = digitalocean_kubernetes_cluster.main.kube_config[0].raw_config
  sensitive   = true
}

output "cluster_ipv4" {
  description = "Public IPv4 address of the cluster"
  value       = digitalocean_kubernetes_cluster.main.ipv4_address
}

output "registry_endpoint" {
  description = "Container registry endpoint"
  value       = var.create_container_registry ? digitalocean_container_registry.main[0].endpoint : null
}

output "namespaces" {
  description = "Created Kubernetes namespaces"
  value = {
    prod       = kubernetes_namespace.prod.metadata[0].name
    dev        = kubernetes_namespace.dev.metadata[0].name
    tracing    = kubernetes_namespace.tracing.metadata[0].name
    monitoring = kubernetes_namespace.monitoring.metadata[0].name
  }
}
