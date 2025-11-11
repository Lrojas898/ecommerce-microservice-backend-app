# ============================================================
# Cluster Outputs
# ============================================================

output "cluster_id" {
  description = "The ID of the Kubernetes cluster"
  value       = module.kubernetes_cluster.cluster_id
}

output "cluster_name" {
  description = "The name of the Kubernetes cluster"
  value       = module.kubernetes_cluster.cluster_name
}

output "cluster_endpoint" {
  description = "The endpoint for the Kubernetes cluster"
  value       = module.kubernetes_cluster.cluster_endpoint
  sensitive   = true
}

output "cluster_region" {
  description = "The region where the cluster is deployed"
  value       = var.cluster_region
}

output "cluster_ipv4" {
  description = "The public IPv4 address of the cluster"
  value       = module.kubernetes_cluster.cluster_ipv4
}

# ============================================================
# Networking Outputs
# ============================================================

output "loadbalancer_ip" {
  description = "The LoadBalancer IP address for Ingress (use this for DNS)"
  value       = module.networking.loadbalancer_ip
}

output "loadbalancer_hostname" {
  description = "The LoadBalancer hostname for Ingress"
  value       = module.networking.loadbalancer_hostname
}

output "ingress_nginx_installed" {
  description = "Whether NGINX Ingress Controller is installed"
  value       = module.networking.ingress_nginx_installed
}

output "cert_manager_installed" {
  description = "Whether cert-manager is installed"
  value       = module.networking.cert_manager_installed
}

# ============================================================
# Namespaces Output
# ============================================================

output "namespaces" {
  description = "Created Kubernetes namespaces"
  value       = module.kubernetes_cluster.namespaces
}

# ============================================================
# Kubeconfig Output
# ============================================================

output "kubeconfig" {
  description = "Kubeconfig for accessing the cluster"
  value       = module.kubernetes_cluster.kubeconfig
  sensitive   = true
}

# ============================================================
# Configuration Summary
# ============================================================

output "infrastructure_summary" {
  description = "Summary of the infrastructure"
  value = {
    project     = var.project_name
    environment = var.environment
    region      = var.cluster_region
    cluster     = module.kubernetes_cluster.cluster_name
    nodes = {
      size       = var.node_pool_size
      count      = var.node_pool_count
      auto_scale = var.node_pool_auto_scale
    }
    total_ram_gb   = var.node_pool_size == "s-4vcpu-8gb" ? var.node_pool_count * 8 : "check node size"
    estimated_cost = "$${var.node_pool_count * 48 + 12}/month" # nodes + loadbalancer
  }
}

# ============================================================
# Next Steps Output
# ============================================================

output "next_steps" {
  description = "Next steps after infrastructure is created"
  value       = <<-EOT

    ╔══════════════════════════════════════════════════════════════╗
    ║         Infrastructure Created Successfully!                  ║
    ╚══════════════════════════════════════════════════════════════╝

    📋 Next Steps:

    1. Configure kubectl to access your cluster:

       doctl kubernetes cluster kubeconfig save ${module.kubernetes_cluster.cluster_name}

       Or save the kubeconfig output:
       terraform output -raw kubeconfig > ~/.kube/config-ecommerce
       export KUBECONFIG=~/.kube/config-ecommerce

    2. Verify cluster access:

       kubectl cluster-info
       kubectl get nodes
       kubectl get namespaces

    3. Note the LoadBalancer IP for DNS configuration:

       LoadBalancer IP: ${module.networking.loadbalancer_ip}

       Configure your DNS records:
       api.yourdomain.com     → ${module.networking.loadbalancer_ip}
       jaeger.yourdomain.com  → ${module.networking.loadbalancer_ip}
       grafana.yourdomain.com → ${module.networking.loadbalancer_ip}

    4. Deploy your applications:

       cd ../kubernetes
       kubectl apply -f base/ -n prod
       kubectl apply -f tracing/ -n tracing

    5. Monitor deployment:

       kubectl get pods -n prod
       kubectl get ingress -n prod

    📊 Cluster Information:
       - Name: ${module.kubernetes_cluster.cluster_name}
       - Region: ${var.cluster_region}
       - Nodes: ${var.node_pool_count}x ${var.node_pool_size}
       - Total RAM: ~${var.node_pool_count * 8}GB
       - Estimated Cost: ~$${var.node_pool_count * 48 + 12}/month

    🔐 Security Note:
       - Kubeconfig is stored in Terraform state (sensitive)
       - Use 'terraform output -raw kubeconfig' to retrieve it
       - Consider using remote state backend for team collaboration

    📚 Documentation:
       - Terraform: ./README.md
       - Kubernetes: ../kubernetes/README.md
       - Monitoring: ../kubernetes/monitoring/README.md

  EOT
}
