# Role assignments for the Service Principal from Challenge-01
# These assignments enable privilege escalation to Key Vault access

# Key Vault Secrets Officer - allows terraform user to create/update secrets
resource "azurerm_role_assignment" "terraform_keyvault_secrets_officer" {
  scope                = azurerm_key_vault.challenge_03_vault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
  
  depends_on = [azurerm_key_vault.challenge_03_vault]
}

# Key Vault Secrets User - allows reading secret values via REST API
resource "azurerm_role_assignment" "sp_keyvault_secrets_user" {
  scope                = azurerm_key_vault.challenge_03_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = data.azuread_service_principal.medicloud_sp.object_id
  
  depends_on = [azurerm_key_vault.challenge_03_vault]
}

# Key Vault Reader - provides read access to Key Vault metadata
resource "azurerm_role_assignment" "sp_keyvault_reader" {
  scope                = azurerm_key_vault.challenge_03_vault.id
  role_definition_name = "Key Vault Reader"
  principal_id         = data.azuread_service_principal.medicloud_sp.object_id
  
  depends_on = [azurerm_key_vault.challenge_03_vault]
}

# Reader on Resource Group - for discovery and enumeration
resource "azurerm_role_assignment" "sp_rg_reader" {
  scope                = azurerm_resource_group.challenge_03.id
  role_definition_name = "Reader"
  principal_id         = data.azuread_service_principal.medicloud_sp.object_id
  
  depends_on = [azurerm_resource_group.challenge_03]
}
