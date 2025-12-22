# Get the latest Windows Server 2022 AMI
data "aws_ami" "windows_server" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Key pair for EC2 instance (optional, mainly for troubleshooting)
resource "aws_key_pair" "dc_key" {
  count      = var.create_key_pair ? 1 : 0
  key_name   = "${var.project_name}-${var.challenge_name}-dc-key-${random_string.suffix.result}"
  public_key = var.public_key

  tags = {
    Name = "${var.project_name}-${var.challenge_name}-dc-key-${random_string.suffix.result}"
  }
}

# IAM role for EC2 instance
resource "aws_iam_role" "dc_role" {
  name = "${var.project_name}-${var.challenge_name}-dc-role-${random_string.suffix.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.challenge_name}-dc-role-${random_string.suffix.result}"
  }
}

# IAM instance profile for EC2
resource "aws_iam_instance_profile" "dc_profile" {
  name = "${var.project_name}-${var.challenge_name}-dc-profile-${random_string.suffix.result}"
  role = aws_iam_role.dc_role.name

  tags = {
    Name = "${var.project_name}-${var.challenge_name}-dc-profile-${random_string.suffix.result}"
  }
}

# PowerShell script for Domain Controller setup
locals {
  user_data = base64encode(templatefile("${path.module}/user_data.ps1", {
    domain_name         = var.domain_name
    dc_admin_password   = var.dc_admin_password
    svc_flag_password   = var.svc_flag_password
    challenge_name      = var.challenge_name
  }))
}

# Domain Controller EC2 instance
resource "aws_instance" "domain_controller" {
  ami                    = data.aws_ami.windows_server.id
  instance_type          = "t3.medium"
  key_name              = var.create_key_pair ? aws_key_pair.dc_key[0].key_name : null
  vpc_security_group_ids = [aws_security_group.dc.id]
  subnet_id             = aws_subnet.public.id
  iam_instance_profile  = aws_iam_instance_profile.dc_profile.name

  user_data = local.user_data

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 50
    encrypted             = false  # Intentionally unencrypted for CTF
    delete_on_termination = false  # Keep volume for snapshot creation
  }

  tags = {
    Name        = "MediCloudX-DC-${random_string.suffix.result}"
    Environment = "Production"
    Application = "MediCloudX"
    Role        = "Domain-Controller"
    Owner       = "IT-Operations"
  }

  # Ensure the instance is fully configured before creating snapshot
  provisioner "local-exec" {
    command = "sleep 900"  # Wait 15 minutes for DC setup to complete
  }
}
