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

# Outputs for microservice databases
output "microservice_postgres_endpoints" {
  description = "PostgreSQL database endpoints for each microservice"
  value = {
    for service, instance in aws_db_instance.microservice_postgres : service => instance.address
  }
}

output "microservice_postgres_ports" {
  description = "PostgreSQL database ports for each microservice"
  value = {
    for service, instance in aws_db_instance.microservice_postgres : service => instance.port
  }
}

output "microservice_postgres_database_names" {
  description = "PostgreSQL database names for each microservice"
  value = {
    for service, instance in aws_db_instance.microservice_postgres : service => instance.db_name
  }
}

output "microservice_postgres_secret_arns" {
  description = "ARNs of secrets containing PostgreSQL credentials for each microservice"
  value = {
    for service, secret in aws_secretsmanager_secret.microservice_postgres_passwords : service => secret.arn
  }
}

output "microservice_postgres_connection_strings" {
  description = "PostgreSQL JDBC connection strings for each microservice"
  value = {
    for service, instance in aws_db_instance.microservice_postgres : service => "jdbc:postgresql://${instance.address}:${instance.port}/${instance.db_name}?sslmode=require"
  }
  sensitive = true
}