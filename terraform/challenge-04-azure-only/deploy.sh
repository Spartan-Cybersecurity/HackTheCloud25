#!/bin/bash

# Deployment script for Challenge-04-Azure-Only: MediCloudX Workforce Onboarding
# This script automates the deployment process for the challenge infrastructure

set -e

echo "🏥 MediCloudX Workforce Onboarding - Challenge-04-Azure-Only Deployment"
echo "================================================================="

# Check prerequisites
echo "Checking prerequisites..."

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed. Please install it first:"
    echo "   https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install it first:"
    echo "   https://www.terraform.io/downloads.html"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install it first:"
    echo "   https://docs.docker.com/get-docker/"
    exit 1
fi

echo "✅ All prerequisites are installed"

# Check Azure login status
echo "Checking Azure authentication..."
if ! az account show &> /dev/null; then
    echo "❌ You are not logged in to Azure. Please run:"
    echo "   az login"
    exit 1
fi

echo "✅ Azure authentication verified"

# Get current subscription details
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

echo "Current Azure Subscription: $SUBSCRIPTION_ID"
echo "Current Azure Tenant: $TENANT_ID"

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "Creating terraform.tfvars file..."
    cat > terraform.tfvars << EOF
# Terraform Variables for Challenge-04-Azure-Only
azure_subscription_id = "$SUBSCRIPTION_ID"
azure_tenant_id       = "$TENANT_ID"

# Optional: Customize these values
challenge_prefix = "ctf-25-ch04"
environment     = "dev"
location        = "East US"
app_service_sku = "B1"
EOF
    echo "✅ terraform.tfvars created with your Azure details"
else
    echo "✅ terraform.tfvars already exists"
fi

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Validate configuration
echo "Validating Terraform configuration..."
terraform validate

# Plan deployment
echo "Planning deployment..."
terraform plan -out=tfplan

# Ask for confirmation
echo ""
read -p "Do you want to proceed with the deployment? (y/N): " confirm

if [[ $confirm =~ ^[Yy]$ ]]; then
    echo "Deploying infrastructure..."
    terraform apply tfplan
    
    # Get outputs
    echo ""
    echo "🎉 Deployment completed successfully!"
    echo ""
    echo "Challenge Information:"
    echo "===================="
    terraform output challenge_info
    
    echo ""
    echo "API Endpoints:"
    echo "=============="
    terraform output api_endpoints
    
    echo ""
    echo "🔗 Access your application at:"
    terraform output -raw app_service_url
    echo ""
    
    # Cleanup plan file
    rm -f tfplan
    
    echo ""
    echo "📝 Next Steps:"
    echo "1. Visit the application URL above"
    echo "2. Try to access the protected endpoints"
    echo "3. Explore the system functionality"
    echo "4. Good luck with your challenge!"
    
else
    echo "Deployment cancelled by user"
    rm -f tfplan
    exit 0
fi
