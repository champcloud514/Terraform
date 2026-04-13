provider "aws" {
  region = "us-east-2"
}

# ---------------------
# VPC
# ---------------------
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# ---------------------
# SUBNET (public)
# ---------------------
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true   # ensures EC2 gets a public IP
}

# ---------------------
# INTERNET GATEWAY
# ---------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# ---------------------
# ROUTE TABLE
# ---------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# ---------------------
# ROUTE TABLE ASSOCIATION
# ---------------------
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.public.id
}

# ---------------------
# SECURITY GROUP
# ---------------------
resource "aws_security_group" "main" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------
# EC2 INSTANCE
# ---------------------
resource "aws_instance" "my_ec2" {
  ami                    = "ami-0f5fcdfbd140e4ab7"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.main.id]

  tags = {
    Name = "Terraform-EC2"
  }
}

