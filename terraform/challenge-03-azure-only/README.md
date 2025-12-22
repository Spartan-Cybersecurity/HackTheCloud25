# Challenge-03-Azure-Only: Azure Key Vault Privilege Escalation

## Overview
This challenge demonstrates privilege escalation from a compromised Service Principal to Azure Key Vault access. Participants must use the Service Principal compromised in Challenge-01 to escalate privileges and access sensitive secrets stored in Azure Key Vault.

## Challenge Description
**Scenario**: MediCloudX Labs has implemented Azure Key Vault to store sensitive credentials and configuration data. However, the Service Principal from the previous incident (Challenge-01) has been granted excessive permissions to the Key Vault infrastructure.

**Objective**: Use the compromised Service Principal certificate and credentials from Challenge-01 to:
1. Generate appropriate Azure access tokens
2. Discover and enumerate Key Vault resources
3. Access sensitive secrets via REST API calls
4. Extract the flag from Key Vault

## Prerequisites
- **REQUIRED**: Completed Challenge-01-Azure-Only successfully
- Access to the Service Principal certificate (`medicloud_cert.pfx`) from Challenge-01
- PowerShell with Azure PowerShell modules
- `New-AccessToken.ps1` module from Challenge-01

## Infrastructure Components
- **Azure Key Vault**: Stores sensitive secrets and credentials
- **Resource Group**: Dedicated resource group for Key Vault resources
- **RBAC Permissions**: Service Principal granted Key Vault access roles
- **Secrets**: Flag secret stored in Key Vault

## Attack Vector
This challenge focuses on **Azure RBAC privilege escalation** and demonstrates:
- Certificate-based authentication to Azure AD
- Token generation for different Azure scopes
- Key Vault REST API exploitation
- Cross-resource privilege escalation

## Key Vault Configuration
- **Authorization Model**: RBAC (Role-Based Access Control)
- **Network Access**: Public (required for CTF participation)
- **SKU**: Standard
- **Soft Delete**: Enabled with 7-day retention

## Role Assignments
The Service Principal from Challenge-01 has been granted:
- **Key Vault Secrets User**: Read access to secret values
- **Key Vault Reader**: Read access to Key Vault metadata
- **Reader**: Read access to the resource group

## Target Secret
- `flag`: Contains the CTF flag

## Expected Skills
- Azure PowerShell and CLI usage
- Certificate-based authentication
- Azure REST API interaction
- Token scope understanding
- RBAC permission analysis

## Difficulty Level
**Advanced** - Requires understanding of:
- Azure authentication flows
- Key Vault REST API
- PowerShell scripting
- Token generation and scoping

## Success Criteria
Successfully extract the flag from the Key Vault secret named `flag` using the compromised Service Principal from Challenge-01.

## Deployment
```bash
# Navigate to challenge directory
cd terraform/challenges/challenge-03-azure-only

# Initialize Terraform
terraform init

# Plan deployment (ensure Challenge-01 is deployed first)
terraform plan

# Deploy challenge
terraform apply
```

## Important Notes
1. **Challenge-01 Dependency**: This challenge requires Challenge-01 to be deployed first
2. **Service Principal Reuse**: Uses the existing Service Principal, does not create a new one
3. **Public Access**: Key Vault is configured for public access to enable CTF participation
4. **RBAC Model**: Uses modern RBAC authorization instead of legacy access policies

## Learning Objectives
- Understand Azure Key Vault RBAC permissions
- Learn certificate-based authentication flows
- Practice REST API exploitation techniques
- Recognize overpermissive role assignments
- Understand cross-resource privilege escalation

## Cleanup
```bash
terraform destroy
```

**Warning**: Ensure you have extracted all necessary information before destroying the infrastructure.

---

*This challenge is part of the EkoCloudSec CTF-25 series focusing on Azure cloud security vulnerabilities and attack techniques.*
