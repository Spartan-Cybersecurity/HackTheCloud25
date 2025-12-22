# EC2 resources for the challenge

# Key pair for EC2 instance (optional, for debugging)
# Uncomment and add your public key if SSH access is needed
# resource "aws_key_pair" "web_app_key" {
#   key_name   = "${var.project_name}-web-app-key-${local.random_suffix}"
#   public_key = "ssh-rsa AAAAB3NzaC1yc2E..." # Replace with your actual public key
#
#   tags = local.common_tags
# }

# EC2 instance running the vulnerable MediCloudX Health web application
resource "aws_instance" "web_app" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  # key_name              = aws_key_pair.web_app_key.key_name  # Uncomment if using SSH key
  vpc_security_group_ids = [aws_security_group.web_app.id]
  subnet_id             = aws_subnet.public.id
  iam_instance_profile  = aws_iam_instance_profile.ec2_profile.name

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    credentials_bucket_name = aws_s3_bucket.credentials_bucket.id
    flag_bucket_name       = aws_s3_bucket.flag_bucket.id
  }))

  tags = merge(local.common_tags, {
    Name        = "${var.project_name}-medicloudx-portal-analisis-${local.random_suffix}"
    Application = "MediCloudX Health Portal"
    Environment = "production"
    Owner       = "DevOps Team"
  })
}

# Elastic IP for the web application
resource "aws_eip" "web_app_eip" {
  instance = aws_instance.web_app.id
  domain   = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-web-app-eip-${local.random_suffix}"
  })

  depends_on = [aws_internet_gateway.main]
}
