# RDS PostgreSQL Database for Ecommerce Microservices
# Creates a managed PostgreSQL database instance in AWS RDS

# Random password for PostgreSQL root user
resource "random_password" "postgres_password" {
  length  = 16
  special = true
}

# Security group for RDS PostgreSQL
resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-postgres-sg"
  description = "Security group for RDS PostgreSQL database"

  # Allow PostgreSQL connections from EKS cluster
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"] # Allow from private subnets
  }

  # Allow outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-rds-postgres-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# DB Subnet Group for RDS
resource "aws_db_subnet_group" "postgres_subnet_group" {
  name       = "${var.project_name}-postgres-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "${var.project_name}-postgres-subnet-group"
    Environment = var.environment
    Project     = var.project_name
  }
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "postgres" {
  identifier = "${var.project_name}-postgres-db"

  # Engine configuration
  engine                = "postgres"
  engine_version        = "13.13"
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage

  # Database configuration
  db_name  = var.db_name
  username = var.db_username
  password = random_password.postgres_password.result

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
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-mysql-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  tags = {
    Name        = "${var.project_name}-postgres-db"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Store PostgreSQL password in AWS Secrets Manager
resource "aws_secretsmanager_secret" "postgres_password" {
  name        = "${var.project_name}-postgres-credentials"
  description = "PostgreSQL database credentials for ${var.project_name}"

  tags = {
    Name        = "${var.project_name}-postgres-credentials"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_secretsmanager_secret_version" "postgres_password" {
  secret_id = aws_secretsmanager_secret.postgres_password.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.postgres_password.result
    engine   = "postgres"
    host     = aws_db_instance.postgres.address
    port     = aws_db_instance.postgres.port
    dbname   = var.db_name
    url      = "jdbc:postgresql://${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}/${var.db_name}?sslmode=require"
  })
}