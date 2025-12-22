#!/bin/bash
# Challenge-05 Preparation Script - Build x86_linux binaries with embedded AWS credentials
# This script is executed by the CTF Framework before terraform apply

set -e

echo "🔨 Preparing Challenge-05: MediCloudX Data Exporter"
echo "=================================================="

# Check if we have Docker available
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker is required for this challenge but not found"
    echo "Please install Docker to compile x86_linux binaries"
    exit 1
fi

# Check for Terraform state (credentials needed for build)
if [ ! -f "terraform.tfstate" ]; then
    echo "⚠️  Warning: No terraform.tfstate found. Using placeholder credentials for initial build."
    echo "After deployment, run build_with_credentials.sh for functional binaries."
    ACCESS_KEY="PLACEHOLDER_ACCESS_KEY"
    SECRET_KEY="PLACEHOLDER_SECRET_KEY"
else
    echo "📋 Extracting AWS credentials from Terraform state..."
    
    # Extract credentials from terraform output (if available)
    ACCESS_KEY=$(terraform output -json embedded_credentials 2>/dev/null | jq -r '.access_key' 2>/dev/null || echo "PLACEHOLDER_ACCESS_KEY")
    SECRET_KEY=$(terraform output -json embedded_credentials 2>/dev/null | jq -r '.secret_key' 2>/dev/null || echo "PLACEHOLDER_SECRET_KEY")
    
    if [ "$ACCESS_KEY" = "null" ] || [ "$SECRET_KEY" = "null" ] || [ -z "$ACCESS_KEY" ] || [ -z "$SECRET_KEY" ]; then
        echo "⚠️  Could not extract real credentials. Using placeholders."
        ACCESS_KEY="PLACEHOLDER_ACCESS_KEY"
        SECRET_KEY="PLACEHOLDER_SECRET_KEY"
    else
        echo "✅ Successfully extracted real AWS credentials"
        echo "Access Key: ${ACCESS_KEY:0:12}****"
    fi
fi

# Build x86_64 Linux binary using Docker
echo ""
echo "🐳 Building x86_64 Linux binary with Docker..."
echo "Platform: linux/amd64"

# Build the Docker image with credentials
docker build --platform linux/amd64 \
    --build-arg AWS_ACCESS_KEY_ID="$ACCESS_KEY" \
    --build-arg AWS_SECRET_ACCESS_KEY="$SECRET_KEY" \
    -t medicloudx-builder-x86 .

# Extract the compiled binary
echo "📦 Extracting compiled binary..."
docker create --name temp-container-x86 medicloudx-builder-x86
docker cp temp-container-x86:/build/medicloudx_exporter ./medicloudx_exporter_linux_x86
docker rm temp-container-x86

# Verify the binary
echo ""
echo "🔍 Verifying compiled binary..."
file ./medicloudx_exporter_linux_x86
ls -la ./medicloudx_exporter_linux_x86

echo ""
echo "✅ Challenge-05 preparation completed successfully!"
echo ""
echo "📋 Generated files:"
echo "  - medicloudx_exporter_linux_x86 (Linux x86_64 binary)"
echo ""
echo "🧪 Test the binary:"
echo "  ./medicloudx_exporter_linux_x86 --version"
echo ""
echo "📚 Challenge overview:"
echo "  - Reverse engineer the binary to extract embedded AWS credentials"
echo "  - Use static analysis: strings medicloudx_exporter_linux_x86 | grep AKIA"
echo "  - Use dynamic analysis: gdb for runtime debugging"
echo "  - Access S3 bucket with extracted credentials"
echo "  - Find flag in admin/system_backup/flag.txt"

# Clean up Docker images if requested
if [ "${CLEANUP_DOCKER:-false}" = "true" ]; then
    echo ""
    echo "🧹 Cleaning up Docker images..."
    docker rmi medicloudx-builder-x86 2>/dev/null || true
fi

echo ""
echo "🎯 Challenge ready for deployment!"
