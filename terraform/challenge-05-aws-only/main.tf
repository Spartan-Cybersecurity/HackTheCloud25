terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = "CTF-2025"
      Challenge   = "challenge-05-aws-only"
      Environment = var.environment
      Owner       = "EkoCloudSec"
    }
  }
}

# Random suffix for unique resource naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Local values for consistent naming
locals {
  resource_suffix = random_string.suffix.result
  base_name      = "ctf-25-medical-exporter"
  binary_name    = "medicloudx_exporter_linux_x86"
}

# Compile binary with embedded credentials after IAM resources are created
resource "null_resource" "compile_binary" {
  depends_on = [aws_iam_access_key.exporter_keys]
  
  provisioner "local-exec" {
    command = <<-EOF
      echo "🔨 Compiling MediCloudX Exporter binary with embedded AWS credentials..."
      
      # Check Docker availability
      if ! command -v docker &> /dev/null; then
        echo "❌ Error: Docker is required but not found"
        exit 1
      fi
      
      # Extract credentials from terraform output
      ACCESS_KEY="${aws_iam_access_key.exporter_keys.id}"
      SECRET_KEY="${aws_iam_access_key.exporter_keys.secret}"
      
      echo "✅ Using AWS credentials: ${aws_iam_access_key.exporter_keys.id}"
      
      # Build x86_64 Linux binary using Docker
      echo "🐳 Building x86_64 Linux binary..."
      docker build --platform linux/amd64 \
        --build-arg AWS_ACCESS_KEY_ID="$ACCESS_KEY" \
        --build-arg AWS_SECRET_ACCESS_KEY="$SECRET_KEY" \
        -t medicloudx-builder-x86-auto .
      
      # Extract the compiled binary
      docker create --name temp-container-auto medicloudx-builder-x86-auto
      docker cp temp-container-auto:/build/medicloudx_exporter ./medicloudx_exporter_linux_x86
      docker rm temp-container-auto
      
      # Verify binary was created
      if [ -f "./medicloudx_exporter_linux_x86" ]; then
        echo "✅ Binary compiled successfully"
        file ./medicloudx_exporter_linux_x86
        ls -la ./medicloudx_exporter_linux_x86
      else
        echo "❌ Binary compilation failed"
        exit 1
      fi
      
      # Cleanup Docker images
      docker rmi medicloudx-builder-x86-auto 2>/dev/null || true
    EOF
    
    working_dir = path.module
  }
  
  triggers = {
    always_run = timestamp()
  }
}

# Upload compiled binary to S3
resource "aws_s3_object" "compiled_binary" {
  depends_on = [null_resource.compile_binary, aws_s3_bucket.patient_data]
  
  bucket = aws_s3_bucket.patient_data.bucket
  key    = "tools/medicloudx_exporter_linux_x86"
  source = "${path.module}/medicloudx_exporter_linux_x86"
  
  content_type = "application/octet-stream"
  
  tags = {
    Name        = "MediCloudX Exporter Binary"
    Type        = "Challenge Tool"
    Platform    = "Linux x86_64"
    Purpose     = "Reverse Engineering Target"
  }
  
  # File will be managed by null_resource dependency
  # etag removed to avoid circular dependency
}

# Create download instructions file
resource "local_file" "download_instructions" {
  depends_on = [aws_s3_object.compiled_binary]
  
  content = <<-EOT
#!/bin/bash
# Download and setup the MediCloudX Exporter binary

echo "📥 Downloading MediCloudX Exporter binary..."

# Download binary from S3
aws s3 cp s3://${aws_s3_bucket.patient_data.bucket}/tools/medicloudx_exporter_linux_x86 . \
  --profile ${var.aws_profile} \
  --region ${var.aws_region}

if [ $? -eq 0 ]; then
  echo "✅ Binary downloaded successfully"
  chmod +x medicloudx_exporter_linux_x86
  
  echo ""
  echo "🔍 Binary information:"
  file medicloudx_exporter_linux_x86
  ls -la medicloudx_exporter_linux_x86
  
  echo ""
  echo "🧪 Test the binary:"
  echo "  ./medicloudx_exporter_linux_x86 --version"
  echo "  ./medicloudx_exporter_linux_x86 --bucket ${local.resource_suffix}"
  
  echo ""
  echo "🔧 Reverse engineering commands:"
  echo "  strings medicloudx_exporter_linux_x86 | grep AKIA"
  echo "  objdump -s medicloudx_exporter_linux_x86"
  echo "  gdb medicloudx_exporter_linux_x86"
else
  echo "❌ Failed to download binary"
  exit 1
fi
EOT
  
  filename = "${path.module}/download_binary.sh"
  file_permission = "0755"
}
