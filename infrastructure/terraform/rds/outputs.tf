output "postgres_endpoint" {
  description = "PostgreSQL database endpoint"
  value       = aws_db_instance.postgres.address
}

output "postgres_port" {
  description = "PostgreSQL database port"
  value       = aws_db_instance.postgres.port
}

output "postgres_database_name" {
  description = "PostgreSQL database name"
  value       = aws_db_instance.postgres.db_name
}

output "postgres_username" {
  description = "PostgreSQL database username"
  value       = aws_db_instance.postgres.username
  sensitive   = true
}

output "postgres_secret_arn" {
  description = "ARN of the secret containing PostgreSQL credentials"
  value       = aws_secretsmanager_secret.postgres_password.arn
}

output "postgres_connection_string" {
  description = "PostgreSQL JDBC connection string"
  value       = "jdbc:postgresql://${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}/${aws_db_instance.postgres.db_name}?sslmode=require"
  sensitive   = true
}