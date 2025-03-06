# AWS Infrastructure for k0rdent-ops

provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "k0rdent" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "k0rdent-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "k0rdent" {
  vpc_id = aws_vpc.k0rdent.id

  tags = {
    Name = "k0rdent-igw"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.k0rdent.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "k0rdent-public-${var.availability_zones[count.index]}"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.k0rdent.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k0rdent.id
  }

  tags = {
    Name = "k0rdent-public-rt"
  }
}

# Route Table Association for Public Subnets
resource "aws_route_table_association" "public" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security Group for k0s Nodes
resource "aws_security_group" "k0s" {
  name        = "k0rdent-k0s"
  description = "Security group for k0s nodes"
  vpc_id      = aws_vpc.k0rdent.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubernetes API
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Internal cluster communication
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # Outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k0rdent-k0s-sg"
  }
}

# EC2 Instances for k0s Cluster
resource "aws_instance" "controller" {
  count                  = var.controller_count
  ami                    = var.ami_id
  instance_type          = var.controller_instance_type
  key_name               = var.ssh_key_name
  subnet_id              = aws_subnet.public[count.index % length(var.availability_zones)].id
  vpc_security_group_ids = [aws_security_group.k0s.id]

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }

  tags = {
    Name = "k0rdent-controller-${count.index}"
    Role = "controller"
  }
}

resource "aws_instance" "worker" {
  count                  = var.worker_count
  ami                    = var.ami_id
  instance_type          = var.worker_instance_type
  key_name               = var.ssh_key_name
  subnet_id              = aws_subnet.public[count.index % length(var.availability_zones)].id
  vpc_security_group_ids = [aws_security_group.k0s.id]

  root_block_device {
    volume_size = 100
    volume_type = "gp3"
  }

  tags = {
    Name = "k0rdent-worker-${count.index}"
    Role = "worker"
  }
}

# Load Balancer for Kubernetes API
resource "aws_lb" "k0s_api" {
  name               = "k0rdent-k0s-api"
  internal           = false
  load_balancer_type = "network"
  subnets            = aws_subnet.public[*].id

  tags = {
    Name = "k0rdent-k0s-api-lb"
  }
}

resource "aws_lb_target_group" "k0s_api" {
  name     = "k0rdent-k0s-api"
  port     = 6443
  protocol = "TCP"
  vpc_id   = aws_vpc.k0rdent.id

  health_check {
    protocol = "TCP"
    port     = 6443
  }
}

resource "aws_lb_target_group_attachment" "k0s_api" {
  count            = var.controller_count
  target_group_arn = aws_lb_target_group.k0s_api.arn
  target_id        = aws_instance.controller[count.index].id
  port             = 6443
}

resource "aws_lb_listener" "k0s_api" {
  load_balancer_arn = aws_lb.k0s_api.arn
  port              = 6443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k0s_api.arn
  }
}

# Output the k0sctl configuration
resource "local_file" "k0sctl_config" {
  content = templatefile("${path.module}/templates/k0sctl.yaml.tpl", {
    controller_ips = aws_instance.controller[*].public_ip
    worker_ips     = aws_instance.worker[*].public_ip
    ssh_key_path   = var.ssh_private_key_path
    k0s_version    = var.k0s_version
  })
  filename = "${path.module}/k0sctl.yaml"
}

# Output variables
output "controller_ips" {
  value = aws_instance.controller[*].public_ip
}

output "worker_ips" {
  value = aws_instance.worker[*].public_ip
}

output "api_endpoint" {
  value = "https://${aws_lb.k0s_api.dns_name}:6443"
}

output "k0sctl_config_path" {
  value = local_file.k0sctl_config.filename
}