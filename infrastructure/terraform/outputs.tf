# ECR Outputs
output "ecr_repositories" {
  description = "ECR repository URLs"
  value       = module.ecr.repository_urls
}

output "ecr_login_command" {
  description = "Command to login to ECR"
  value       = module.ecr.ecr_login_command
}

# Jenkins Outputs
output "jenkins_url" {
  description = "Jenkins server URL"
  value       = module.jenkins.jenkins_url
}

output "jenkins_public_ip" {
  description = "Jenkins public IP"
  value       = module.jenkins.jenkins_public_ip
}

output "jenkins_ssh_command" {
  description = "SSH to Jenkins"
  value       = module.jenkins.jenkins_ssh_command
}

output "get_jenkins_password" {
  description = "Get Jenkins initial password"
  value       = module.jenkins.get_jenkins_password_command
}

# EKS Outputs
output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_kubectl_config" {
  description = "kubectl config command"
  value       = module.eks.kubectl_config_command
}

output "eks_scale_down_command" {
  description = "Command to scale down to save costs"
  value       = module.eks.scale_down_command
}

output "next_steps" {
  description = "Next steps after infrastructure deployment"
  value       = <<-EOT

    ═══════════════════════════════════════════════════════════════════
    ✅ INFRAESTRUCTURA DESPLEGADA EXITOSAMENTE
    ═══════════════════════════════════════════════════════════════════

    📦 ECR REPOSITORIES CREADOS:
    ${join("\n    ", [for name, url in module.ecr.repository_urls : "${name}: ${url}"])}

    🔐 ECR LOGIN:
       ${module.ecr.ecr_login_command}

    📋 JENKINS SERVER:
       URL: ${module.jenkins.jenkins_url}
       IP:  ${module.jenkins.jenkins_public_ip}
       SSH: ${module.jenkins.jenkins_ssh_command}

       Obtener contraseña:
       ${module.jenkins.get_jenkins_password_command}

    ☸️  EKS CLUSTER:
       Nombre: ${module.eks.cluster_name}
       Endpoint: ${module.eks.cluster_endpoint}

       Configurar kubectl:
       ${module.eks.kubectl_config_command}

       Crear namespaces:
       kubectl create namespace dev
       kubectl create namespace staging
       kubectl create namespace production

       ⚠️  PARA AHORRAR COSTOS (apagar sin eliminar):
       ${module.eks.scale_down_command}

    📋 SIGUIENTES PASOS:

       1. Acceder a Jenkins: ${module.jenkins.jenkins_url}
       2. Configurar kubectl: ${module.eks.kubectl_config_command}
       3. Crear namespaces de K8s
       4. Build y push imágenes: ./infrastructure/scripts/build-and-push.sh user-service
       5. Desplegar en K8s: kubectl apply -f infrastructure/kubernetes/base/
       6. Configurar pipelines en Jenkins

    ═══════════════════════════════════════════════════════════════════
  EOT
}
