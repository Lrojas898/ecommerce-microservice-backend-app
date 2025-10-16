output "repository_urls" {
  description = "ECR repository URLs"
  value = {
    for service, repo in aws_ecr_repository.services :
    service => repo.repository_url
  }
}

output "repository_arns" {
  description = "ECR repository ARNs"
  value = {
    for service, repo in aws_ecr_repository.services :
    service => repo.arn
  }
}

output "ecr_login_command" {
  description = "Command to login to ECR"
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}
