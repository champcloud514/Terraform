provider "aws" {
  region = "us-east-2"
}

# --------------------------
# Create VPC
# --------------------------
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# --------------------------
# Create Subnet
# --------------------------
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# --------------------------
# Internet Gateway
# --------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# --------------------------
# Route table for Internet access
# --------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.public.id
}

# --------------------------
# Security group allowing SSH + HTTP
# --------------------------
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
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

# --------------------------
# EC2 with user-data (install nginx + deploy custom HTML)
# --------------------------
resource "aws_instance" "my_ec2" {
  ami                    = "ami-0f5fcdfbd140e4ab7"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.main.id
  security_groups        = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y nginx
              echo "<h1>Hello from my custom HTML page!</h1>" > /var/www/html/index.html
              systemctl enable nginx
              systemctl start nginx
              EOF

  tags = {
    Name = "MyWebServer"
  }
}

