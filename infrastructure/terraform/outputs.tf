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
    
    📋 CREAR EKS CLUSTER (opcional):
    
       eksctl create cluster \
         --name ecommerce-cluster \
         --region us-east-1 \
         --nodegroup-name standard-workers \
         --node-type t3.medium \
         --nodes 2 \
         --managed
       
       aws eks update-kubeconfig --region us-east-1 --name ecommerce-cluster
       
       kubectl create namespace dev
       kubectl create namespace staging  
       kubectl create namespace production
    
    📋 SIGUIENTES PASOS:
    
       1. Acceder a Jenkins: ${module.jenkins.jenkins_url}
       2. Configurar Jenkins (instalar plugins)
       3. Build una imagen: ./infrastructure/scripts/build-and-push.sh user-service
       4. Crear pipelines en Jenkins
       5. (Opcional) Crear cluster EKS
       6. Desplegar servicios
    
    ═══════════════════════════════════════════════════════════════════
  EOT
}
