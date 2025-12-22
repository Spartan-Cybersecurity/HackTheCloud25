# Azure Key Vault for Challenge-03
# Configured with RBAC authorization and public access for CTF purposes

resource "azurerm_key_vault" "challenge_03_vault" {
  name                = "kv-ctf25-ch03-${random_string.suffix.result}"
  location            = azurerm_resource_group.challenge_03.location
  resource_group_name = azurerm_resource_group.challenge_03.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  
  # Use RBAC authorization model (modern approach)
  enable_rbac_authorization = true
  
  # Enable public network access for CTF participants
  public_network_access_enabled = true
  
  # Standard SKU for production-like scenario
  sku_name = "standard"
  
  # Soft delete configuration
  soft_delete_retention_days = 7
  purge_protection_enabled   = false  # Disabled for easier cleanup in CTF
  
  # Network access configuration
  network_acls {
    default_action = "Allow"  # Allow public access for CTF
    bypass         = "AzureServices"
  }
  
  tags = merge(var.tags, {
    Name        = "Challenge-03 Key Vault"
    Description = "Key Vault for privilege escalation challenge"
    VaultType   = "CTF-Challenge"
  })
}
