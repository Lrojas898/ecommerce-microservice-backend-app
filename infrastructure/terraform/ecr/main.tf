# ECR Repositories for all microservices and infrastructure components
locals {
  services = [
    # Infrastructure services
    "service-discovery",
    "cloud-config",
    "api-gateway",
    # Business microservices
    "user-service",
    "product-service",
    "order-service",
    "payment-service",
    "shipping-service",
    "favourite-service"
  ]
}

resource "aws_ecr_repository" "services" {
  for_each = toset(local.services)
  
  name                 = "ecommerce/${each.value}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = {
    Name        = "ecommerce/${each.value}"
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# Lifecycle policy to keep only last 10 images
resource "aws_ecr_lifecycle_policy" "services" {
  for_each = aws_ecr_repository.services
  
  repository = each.value.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}
