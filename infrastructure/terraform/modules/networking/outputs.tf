output "ingress_nginx_installed" {
  description = "Whether NGINX Ingress is installed"
  value       = var.enable_ingress_nginx
}

output "cert_manager_installed" {
  description = "Whether cert-manager is installed"
  value       = var.enable_cert_manager
}

output "loadbalancer_ip" {
  description = "LoadBalancer IP address for Ingress"
  value = var.enable_ingress_nginx ? (
    try(data.kubernetes_service.ingress_nginx[0].status[0].load_balancer[0].ingress[0].ip, "pending")
  ) : null
}

output "loadbalancer_hostname" {
  description = "LoadBalancer hostname for Ingress"
  value = var.enable_ingress_nginx ? (
    try(data.kubernetes_service.ingress_nginx[0].status[0].load_balancer[0].ingress[0].hostname, "pending")
  ) : null
}
