terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "aws" {
  region = "ap-south-1"
}

# -------------------------------
# VPC
# -------------------------------
resource "aws_vpc" "main" {
  cidr_block           = "172.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name      = "Terraform-vpc"
    terraform = "server"
  }
}

# -------------------------------
# Internet Gateway
# -------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name      = "terraform-igw"
    terraform = "server"
  }
}

# -------------------------------
# Public Subnet
# -------------------------------
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "172.0.1.0/25"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1a"

  tags = {
    Name      = "terraform-public-subnet"
    terraform = "server"
  }
}

# -------------------------------
# Route Table
# -------------------------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name      = "terraform-public-rt"
    terraform = "server"
  }
}

# -------------------------------
# Route Table Association
# -------------------------------
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# -------------------------------
# Security Group
# -------------------------------
resource "aws_security_group" "terraform_sg" {
  name        = "terraform-sg"
  description = "Allow SSH, HTTP, HTTPS, and Jenkins (8080)"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "terraform-sg"
    terraform = "server"
  }
}

# -------------------------------
# Key Pair
# -------------------------------
resource "tls_private_key" "linux_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "linuxterraform" {
  key_name   = "linuxterraform"
  public_key = tls_private_key.linux_key.public_key_openssh
}

resource "local_file" "private_key_pem" {
  filename        = "${path.module}/linuxterraform.pem"
  content         = tls_private_key.linux_key.private_key_pem
  file_permission = "0400"
}

# -------------------------------
# EC2 Instance
# -------------------------------
resource "aws_instance" "ec2" {
  ami                         = "ami-00af95fa354fdb788"
  instance_type                = "t3.small"
  subnet_id                    = aws_subnet.public.id
  key_name                     = aws_key_pair.linuxterraform.key_name
  vpc_security_group_ids       = [aws_security_group.terraform_sg.id]
  associate_public_ip_address  = true

  # Inline user_data script for Jenkins setup
  user_data = <<-EOF
    #!/bin/bash
    set -eux

    # Update packages
    sudo dnf update -y

    # Install Java (Amazon Corretto 17)
    sudo dnf install -y java-17-amazon-corretto

    # Add Jenkins repo and import key
    sudo rpm --import https://pkg.jenkins.io/redhat/jenkins.io-2023.key
    cat <<EOT | sudo tee /etc/yum.repos.d/jenkins.repo
    [jenkins]
    name=Jenkins-stable
    baseurl=https://pkg.jenkins.io/redhat-stable
    gpgcheck=1
    EOT

    # Install Jenkins
    sudo dnf install -y jenkins

    # Start Jenkins service
    sudo systemctl enable jenkins
    sudo systemctl start jenkins

    # Open firewall port 8080 (if firewalld exists)
    if command -v firewall-cmd >/dev/null 2>&1; then
      sudo systemctl start firewalld
      sudo firewall-cmd --permanent --add-port=8080/tcp
      sudo firewall-cmd --reload
    fi

    echo "Jenkins setup complete!"
  EOF

  root_block_device {
    volume_size = 25
    volume_type = "gp3"
  }

  tags = {
    Name      = "terraform-ec2"
    terraform = "server"
  }
}

# -------------------------------
# Output
# -------------------------------
output "jenkins_url" {
  value = "http://${aws_instance.ec2.public_ip}:8080"
}

output "ssh_command" {
  value = "ssh -i linuxterraform.pem ec2-user@${aws_instance.ec2.public_ip}"
}

