# NOTA: Para AWS Academy, crear EKS manualmente es más confiable
# Este archivo está como referencia, pero recomendamos usar eksctl

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Output para crear cluster manualmente
output "create_eks_command" {
  value = <<-EOT
    # Crear cluster EKS con eksctl (recomendado para AWS Academy)
    eksctl create cluster \
      --name ${var.project_name}-cluster \
      --region ${var.aws_region} \
      --nodegroup-name standard-workers \
      --node-type ${var.eks_node_instance_type} \
      --nodes ${var.eks_desired_capacity} \
      --nodes-min ${var.eks_min_capacity} \
      --nodes-max ${var.eks_max_capacity} \
      --managed
    
    # Configurar kubectl
    aws eks update-kubeconfig --region ${var.aws_region} --name ${var.project_name}-cluster
    
    # Crear namespaces
    kubectl create namespace dev
    kubectl create namespace staging
    kubectl create namespace production
  EOT
}
