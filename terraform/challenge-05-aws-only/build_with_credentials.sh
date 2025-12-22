#!/bin/bash
# Script to build the MediCloudX Exporter with real AWS credentials

set -e

echo "🔨 Building MediCloudX Exporter with embedded AWS credentials..."

# Get credentials from Terraform outputs
if [ ! -f "terraform.tfstate" ]; then
    echo "❌ Error: terraform.tfstate not found. Please run 'terraform apply' first."
    exit 1
fi

echo "📋 Extracting AWS credentials from Terraform state..."

# Extract credentials from terraform output
ACCESS_KEY=$(terraform output -json embedded_credentials | jq -r '.access_key' 2>/dev/null || echo "")
SECRET_KEY=$(terraform output -json embedded_credentials | jq -r '.secret_key' 2>/dev/null || echo "")

if [ -z "$ACCESS_KEY" ] || [ -z "$SECRET_KEY" ]; then
    echo "❌ Error: Could not extract credentials from Terraform output."
    echo "Please ensure Terraform has been applied and outputs are available."
    exit 1
fi

echo "✅ Successfully extracted credentials"
echo "Access Key: ${ACCESS_KEY:0:12}****"
echo "Secret Key: ${SECRET_KEY:0:8}****"

# Build the binary with credentials
echo ""
echo "🏗️  Compiling binary with embedded credentials..."
make clean
AWS_ACCESS_KEY_ID="$ACCESS_KEY" AWS_SECRET_ACCESS_KEY="$SECRET_KEY" make

echo ""
echo "🐳 Building Linux version..."
# Update Dockerfile to use credentials
cat > Dockerfile.dynamic << EOF
FROM gcc:latest

RUN apt-get update && apt-get install -y \\
    libcurl4-openssl-dev \\
    make \\
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

COPY medicloudx_exporter.c .
COPY Makefile .

ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY

RUN AWS_ACCESS_KEY_ID="\$AWS_ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="\$AWS_SECRET_ACCESS_KEY" make

CMD ["./medicloudx_exporter", "--version"]
EOF

# Build Linux version with Docker
docker build -f Dockerfile.dynamic \\
    --build-arg AWS_ACCESS_KEY_ID="$ACCESS_KEY" \\
    --build-arg AWS_SECRET_ACCESS_KEY="$SECRET_KEY" \\
    -t medicloudx-builder-dynamic .

docker create --name temp-container medicloudx-builder-dynamic
docker cp temp-container:/build/medicloudx_exporter ./medicloudx_exporter_linux
docker rm temp-container

echo ""
echo "✅ Build completed successfully!"
echo ""
echo "📦 Generated binaries:"
echo "  - medicloudx_exporter (macOS)"
echo "  - medicloudx_exporter_linux (Linux)"
echo ""
echo "🧪 Test the binary:"
echo "  ./medicloudx_exporter --version"
echo "  ./medicloudx_exporter --bucket \$(terraform output -json challenge_info | jq -r '.bucket_suffix')"

# Clean up
rm -f Dockerfile.dynamic
