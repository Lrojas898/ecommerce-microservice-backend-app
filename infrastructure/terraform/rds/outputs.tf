output "mysql_endpoint" {
  description = "MySQL database endpoint"
  value       = aws_db_instance.mysql.address
}

output "mysql_port" {
  description = "MySQL database port"
  value       = aws_db_instance.mysql.port
}

output "mysql_database_name" {
  description = "MySQL database name"
  value       = aws_db_instance.mysql.db_name
}

output "mysql_username" {
  description = "MySQL database username"
  value       = aws_db_instance.mysql.username
  sensitive   = true
}

output "mysql_secret_arn" {
  description = "ARN of the secret containing MySQL credentials"
  value       = aws_secretsmanager_secret.mysql_password.arn
}

output "mysql_connection_string" {
  description = "MySQL JDBC connection string"
  value       = "jdbc:mysql://${aws_db_instance.mysql.address}:${aws_db_instance.mysql.port}/${aws_db_instance.mysql.db_name}?useSSL=false&serverTimezone=UTC"
  sensitive   = true
}