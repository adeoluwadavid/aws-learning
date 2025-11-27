# =============================================================================
# VPC (Virtual Private Cloud)
# =============================================================================
# A VPC is your isolated virtual network in AWS. Think of it as your own
# private data center in the cloud where you control:
# - IP address ranges
# - Subnets (network segments)
# - Route tables (traffic rules)
# - Network gateways (internet access)

# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true # Allows instances to get DNS hostnames
  enable_dns_support   = true # Enables DNS resolution in the VPC

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

# -----------------------------------------------------------------------------
# INTERNET GATEWAY
# -----------------------------------------------------------------------------
# An Internet Gateway allows resources in public subnets to communicate
# with the internet. It's like the front door of your VPC.

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

# -----------------------------------------------------------------------------
# PUBLIC SUBNETS
# -----------------------------------------------------------------------------
# Public subnets have a route to the Internet Gateway.
# Resources here can have public IP addresses and be accessed from the internet.
# Use for: Load Balancers, Bastion Hosts, NAT Gateways

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true # Instances get public IPs automatically

  tags = {
    Name = "${var.project_name}-${var.environment}-public-${var.availability_zones[count.index]}"
    Type = "Public"
  }
}

# -----------------------------------------------------------------------------
# PRIVATE SUBNETS
# -----------------------------------------------------------------------------
# Private subnets have NO direct route to the internet.
# Resources here are protected from direct internet access.
# Use for: Application servers, Databases, Internal services

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.project_name}-${var.environment}-private-${var.availability_zones[count.index]}"
    Type = "Private"
  }
}

# -----------------------------------------------------------------------------
# ELASTIC IP FOR NAT GATEWAY
# -----------------------------------------------------------------------------
# A static public IP address that the NAT Gateway will use.
# This allows private resources to have a consistent outbound IP.

resource "aws_eip" "nat" {
  count  = 1 # Using 1 NAT Gateway to save costs (use count = length(var.availability_zones) for HA)
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-eip"
  }

  depends_on = [aws_internet_gateway.main]
}

# -----------------------------------------------------------------------------
# NAT GATEWAY
# -----------------------------------------------------------------------------
# NAT (Network Address Translation) Gateway allows resources in private
# subnets to access the internet (for updates, API calls, etc.) while
# preventing inbound connections from the internet.
#
# COST WARNING: NAT Gateway costs ~$0.045/hour (~$32/month) + data transfer
# For learning: Consider removing this to save costs (private resources won't
# have internet access, but that's fine for learning VPC concepts)

resource "aws_nat_gateway" "main" {
  count         = 1 # Single NAT to save costs
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id # NAT Gateway lives in a public subnet

  tags = {
    Name = "${var.project_name}-${var.environment}-nat"
  }

  depends_on = [aws_internet_gateway.main]
}

# -----------------------------------------------------------------------------
# ROUTE TABLES
# -----------------------------------------------------------------------------
# Route tables contain rules (routes) that determine where network traffic
# from subnets is directed.

# Public Route Table - Routes traffic to Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0" # All traffic not matching VPC CIDR
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
  }
}

# Private Route Table - Routes traffic to NAT Gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[0].id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-private-rt"
  }
}

# -----------------------------------------------------------------------------
# ROUTE TABLE ASSOCIATIONS
# -----------------------------------------------------------------------------
# Associate subnets with their respective route tables

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
