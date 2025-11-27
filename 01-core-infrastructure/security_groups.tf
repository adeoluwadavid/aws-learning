# =============================================================================
# SECURITY GROUPS
# =============================================================================
# Security Groups act as virtual firewalls for your resources.
# They control inbound and outbound traffic at the instance level.
#
# Key concepts:
# - Security groups are STATEFUL (if you allow inbound, response is auto-allowed)
# - Default: deny all inbound, allow all outbound
# - You can reference other security groups (not just IP ranges)

# -----------------------------------------------------------------------------
# ALB SECURITY GROUP
# -----------------------------------------------------------------------------
# For the Application Load Balancer - accepts HTTP/HTTPS from anywhere

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  # Allow HTTP from anywhere
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS from anywhere
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  }
}

# -----------------------------------------------------------------------------
# APPLICATION SECURITY GROUP
# -----------------------------------------------------------------------------
# For ECS tasks / EC2 instances running the FastAPI application
# Only accepts traffic from the ALB security group

resource "aws_security_group" "app" {
  name        = "${var.project_name}-${var.environment}-app-sg"
  description = "Security group for application servers"
  vpc_id      = aws_vpc.main.id

  # Allow traffic from ALB on application port
  ingress {
    description     = "HTTP from ALB"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id] # Only from ALB!
  }

  # Allow all outbound (for API calls, package downloads, etc.)
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-app-sg"
  }
}

# -----------------------------------------------------------------------------
# DATABASE SECURITY GROUP
# -----------------------------------------------------------------------------
# For RDS / database instances
# Only accepts traffic from the application security group

resource "aws_security_group" "database" {
  name        = "${var.project_name}-${var.environment}-db-sg"
  description = "Security group for database"
  vpc_id      = aws_vpc.main.id

  # Allow PostgreSQL from application servers
  ingress {
    description     = "PostgreSQL from app servers"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id] # Only from app!
  }

  # No outbound needed for databases typically
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-db-sg"
  }
}
