# RDS MySQL Database for Ecommerce Microservices
# Creates a managed MySQL database instance in AWS RDS

# Random password for MySQL root user
resource "random_password" "mysql_password" {
  length  = 16
  special = true
}

# Security group for RDS MySQL
resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-mysql-sg"
  description = "Security group for RDS MySQL database"

  # Allow MySQL connections from EKS cluster
  ingress {
    from_port   = 3306
    to_port     = 3306
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
    Name        = "${var.project_name}-rds-mysql-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# DB Subnet Group for RDS
resource "aws_db_subnet_group" "mysql_subnet_group" {
  name       = "${var.project_name}-mysql-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "${var.project_name}-mysql-subnet-group"
    Environment = var.environment
    Project     = var.project_name
  }
}

# RDS MySQL Instance
resource "aws_db_instance" "mysql" {
  identifier = "${var.project_name}-mysql-db"

  # Engine configuration
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage

  # Database configuration
  db_name  = var.db_name
  username = var.db_username
  password = random_password.mysql_password.result

  # Network configuration
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.mysql_subnet_group.name
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
    Name        = "${var.project_name}-mysql-db"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Store MySQL password in AWS Secrets Manager
resource "aws_secretsmanager_secret" "mysql_password" {
  name        = "${var.project_name}-mysql-credentials"
  description = "MySQL database credentials for ${var.project_name}"

  tags = {
    Name        = "${var.project_name}-mysql-credentials"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_secretsmanager_secret_version" "mysql_password" {
  secret_id = aws_secretsmanager_secret.mysql_password.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.mysql_password.result
    engine   = "mysql"
    host     = aws_db_instance.mysql.address
    port     = aws_db_instance.mysql.port
    dbname   = var.db_name
    url      = "jdbc:mysql://${aws_db_instance.mysql.address}:${aws_db_instance.mysql.port}/${var.db_name}?useSSL=false&serverTimezone=UTC"
  })
}