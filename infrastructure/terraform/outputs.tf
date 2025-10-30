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

# SonarQube Outputs (runs on same instance as Jenkins via Docker Compose)
output "sonarqube_url" {
  description = "SonarQube server URL (running on Jenkins instance)"
  value       = "http://${module.jenkins.jenkins_public_ip}:9000"
}

output "sonarqube_credentials" {
  description = "SonarQube default credentials"
  value       = "Username: admin | Password: admin (change on first login)"
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

# RDS PostgreSQL Outputs
output "postgres_endpoint" {
  description = "PostgreSQL database endpoint"
  value       = module.rds.postgres_endpoint
}

output "postgres_database_name" {
  description = "PostgreSQL database name"
  value       = module.rds.postgres_database_name
}

output "postgres_secret_arn" {
  description = "ARN of the secret containing PostgreSQL credentials"
  value       = module.rds.postgres_secret_arn
}

output "next_steps" {
  description = "Next steps after infrastructure deployment"
  value       = <<-EOT

    ═══════════════════════════════════════════════════════════════════
    ✅ INFRAESTRUCTURA DESPLEGADA EXITOSAMENTE
    ═══════════════════════════════════════════════════════════════════

    📦 ECR REPOSITORIES CREADOS (9 servicios):
    ${join("\n    ", [for name, url in module.ecr.repository_urls : "${name}: ${url}"])}

    🔐 ECR LOGIN:
       ${module.ecr.ecr_login_command}

    📋 JENKINS SERVER:
       URL: ${module.jenkins.jenkins_url}
       IP:  ${module.jenkins.jenkins_public_ip}
       SSH: ${module.jenkins.jenkins_ssh_command}

       Obtener contraseña inicial:
       ${module.jenkins.get_jenkins_password_command}

    🔍 SONARQUBE SERVER (running on Jenkins instance):
       URL: http://${module.jenkins.jenkins_public_ip}:9000
       Credenciales: admin / admin (change on first login)

    ☸️  EKS CLUSTER:
       Nombre: ${module.eks.cluster_name}
       Endpoint: ${module.eks.cluster_endpoint}

       Configurar kubectl:
       ${module.eks.kubectl_config_command}

       Crear namespaces:
       kubectl create namespace dev
       kubectl create namespace staging
       kubectl create namespace production

       Verificar node group:
       kubectl get nodes

       ⚠️  PARA AHORRAR COSTOS (apagar sin eliminar):
       ${module.eks.scale_down_command}

    📋 SIGUIENTES PASOS:

       1. Acceder a Jenkins: ${module.jenkins.jenkins_url}
       2. Configurar kubectl: ${module.eks.kubectl_config_command}
       3. Verificar namespaces: kubectl get namespaces
       4. Configurar credenciales en Jenkins (AWS, GitHub, ECR)
       5. Crear pipelines en Jenkins usando Jenkinsfiles en infrastructure/jenkins/
       6. Ejecutar pipeline DEV para construir y pushear imágenes
       7. Ejecutar pipeline STAGE para desplegar en staging
       8. Ejecutar pruebas (unitarias, integración, E2E, performance)
       9. Ejecutar pipeline PROD para desplegar en producción

    ═══════════════════════════════════════════════════════════════════
  EOT
}
