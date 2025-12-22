# Challenge 01: Azure Combined Storage & Identity Challenge

This combined challenge implements multiple attack vectors in Azure Storage and Azure AD for CTF educational purposes.

## Challenge Description

**Objective**: Find and access flags through two different attack routes:

### Vector 1: Direct Access (Basic)
- Azure Storage Account with public read access
- Static website hosting enabled
- Basic flag stored in `flag.txt`

### Vector 2: MediCloudX Research Portal (Advanced)
- Research portal with embedded SAS tokens
- Private container with sensitive data
- Azure AD App Registration with certificate authentication
- Azure AD user with known credentials
- Advanced flag in private container

**Demonstrated vulnerabilities**:
- Container with public read access (CWE-200)
- SAS token exposed in client code (CWE-200)
- SAS token with excessive permissions and long expiration (CWE-732)
- Certificate stored in accessible location (CWE-522)
- Weak certificate password (CWE-521)

## Prerequisites

### 1. Required Tools
- Terraform >= 1.5.0
- Azure CLI
- Active Azure subscription

### 2. Azure Configuration

#### Configure Azure CLI
```bash
# Login to Azure
az login

# List available subscriptions
az account list --output table

# Set active subscription
az account set --subscription "your-subscription-id"

# Verify authentication
az account show --query "{subscriptionId: id, tenantId: tenantId}" --output table
```

### 3. Required Azure Permissions
Your Azure user/role needs the following permissions:
- `Microsoft.Storage/storageAccounts/*`
- `Microsoft.Resources/resourceGroups/*`
- Contributor role on subscription (recommended for CTF)

## Deployment

### 1. Configure Variables
```bash
cd terraform/challenges/challenge-01-azure-only

# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your Azure credentials
# azure_subscription_id = "your-subscription-id"
# azure_tenant_id = "your-tenant-id"
```

### 2. Configure Terraform Backend
```bash
# Initialize with Azure backend
terraform init -backend-config=../../backend-configs/azurerm.hcl
```

### 3. Deploy Infrastructure
```bash
# Review deployment plan
terraform plan

# Apply changes
terraform apply
```

### 4. Get Challenge URLs
After deployment, Terraform will show:
```
Outputs:

azure_flag_url = "https://ctf25sa9ed81dc6.z13.web.core.windows.net/flag.txt"
azure_storage_account_name = "ctf25sa9ed81dc6"
azure_storage_website_endpoint = "https://ctf25sa9ed81dc6.z13.web.core.windows.net/"
challenge_summary = {
  "flag" = "https://ctf25sa9ed81dc6.z13.web.core.windows.net/flag.txt"
  "storage_account" = "ctf25sa9ed81dc6"
  "website" = "https://ctf25sa9ed81dc6.z13.web.core.windows.net/"
}
```

## Information for Participants

Once the infrastructure is deployed, participants will receive the necessary URLs to complete the challenge. The detailed solution can be found in the `SOLUTION.md` file in this directory.

## Cleanup

To remove all resources:
```bash
terraform destroy
```

## Troubleshooting

### Common Issues

**Error: "Authentication failed"**
- Verify your Azure CLI is authenticated: `az account show`
- Confirm you have the necessary permissions on the subscription
- Check the configured region

**Error: "Backend initialization failed"**
- Ensure the Resource Group for the backend exists
- Verify you have access to the backend Storage Account
- Confirm the `tfstate` container exists

**Error: "Storage account name conflicts"**
- Storage account names are globally unique
- The module uses random suffixes to avoid conflicts
- If it persists, change the `project_name` in `terraform.tfvars`

### Enumeration Issues

For detailed troubleshooting of enumeration issues, check the `SOLUTION.md` file.

### Detailed Logs
```bash
# Enable detailed logging
export TF_LOG=DEBUG
terraform apply

# Azure CLI logs
az storage blob list --account-name ctf25sa9ed81dc6 --container-name '$web' --debug
```

## Advanced Configuration

### Customizable Variables

| Variable | Description | Default Value |
|----------|-------------|---------------|
| `azure_location` | Azure Region | `East US` |
| `azure_subscription_id` | Azure subscription ID | (required) |
| `azure_tenant_id` | Azure tenant ID | (required) |
| `project_name` | Project name | `ctf-25` |

### Custom terraform.tfvars Example
```hcl
azure_subscription_id = "your-subscription-id"
azure_tenant_id       = "your-tenant-id"
azure_location        = "West Europe"
project_name          = "my-ctf"
```

## Security Notes

⚠️ **WARNING**: This challenge intentionally creates security vulnerabilities for educational purposes. 

- DO NOT deploy in production environments
- DO NOT use with sensitive data
- Remove resources after completing the challenge
- Public storage accounts may incur costs if they receive massive traffic
- Azure charges for storage and data transfer
