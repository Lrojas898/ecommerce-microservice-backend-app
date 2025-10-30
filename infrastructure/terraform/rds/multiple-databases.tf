# Multiple PostgreSQL databases for microservices
# Each microservice gets its own database for better isolation and scalability

# Define microservices that need databases
locals {
  microservices_with_db = {
    user = {
      db_name     = "userdb"
      description = "User service database - handles users, credentials, addresses"
    }
    product = {
      db_name     = "productdb" 
      description = "Product service database - handles products and categories"
    }
    order = {
      db_name     = "orderdb"
      description = "Order service database - handles orders and carts"
    }
    payment = {
      db_name     = "paymentdb"
      description = "Payment service database - handles payments and statuses"
    }
    favourite = {
      db_name     = "favouritedb"
      description = "Favourite service database - handles user favorites"
    }
  }
}

# Random passwords for each microservice database
resource "random_password" "microservice_postgres_passwords" {
  for_each = local.microservices_with_db
  
  length  = 16
  special = true
}

# RDS PostgreSQL Instances for each microservice
resource "aws_db_instance" "microservice_postgres" {
  for_each = local.microservices_with_db
  
  identifier = "${var.project_name}-${each.key}-postgres-db"

  # Engine configuration
  engine                = "postgres"
  engine_version        = "13.13"
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage

  # Database configuration
  db_name  = each.value.db_name
  username = var.db_username
  password = random_password.microservice_postgres_passwords[each.key].result

  # Network configuration
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.postgres_subnet_group.name
  publicly_accessible    = false

  # Backup configuration
  backup_retention_period = var.backup_retention_period
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  # Performance and monitoring
  performance_insights_enabled = true
  monitoring_interval         = 60

  # Security
  storage_encrypted = true
  deletion_protection = var.deletion_protection

  # Skip final snapshot for development
  skip_final_snapshot = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-${each.key}-postgres-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  tags = {
    Name        = "${var.project_name}-${each.key}-postgres-db"
    Service     = "${each.key}-service"
    Environment = var.environment
    Project     = var.project_name
    Description = each.value.description
  }
}

# Store credentials in AWS Secrets Manager for each microservice
resource "aws_secretsmanager_secret" "microservice_postgres_passwords" {
  for_each = local.microservices_with_db
  
  name        = "${var.project_name}-${each.key}-postgres-credentials"
  description = "${each.value.description} - Database credentials"

  tags = {
    Name        = "${var.project_name}-${each.key}-postgres-credentials"
    Service     = "${each.key}-service"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_secretsmanager_secret_version" "microservice_postgres_passwords" {
  for_each = local.microservices_with_db
  
  secret_id = aws_secretsmanager_secret.microservice_postgres_passwords[each.key].id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.microservice_postgres_passwords[each.key].result
    engine   = "postgres"
    host     = aws_db_instance.microservice_postgres[each.key].address
    port     = aws_db_instance.microservice_postgres[each.key].port
    dbname   = each.value.db_name
    url      = "jdbc:postgresql://${aws_db_instance.microservice_postgres[each.key].address}:${aws_db_instance.microservice_postgres[each.key].port}/${each.value.db_name}?sslmode=require"
  })
}