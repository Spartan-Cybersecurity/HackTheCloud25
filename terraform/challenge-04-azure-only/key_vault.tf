# Azure Key Vault for storing application secrets

resource "azurerm_key_vault" "medicloudx_vault" {
  name                = "medicloudx-kv-${random_string.suffix.result}"
  location            = azurerm_resource_group.medicloudx_identity.location
  resource_group_name = azurerm_resource_group.medicloudx_identity.name
  tenant_id           = var.azure_tenant_id
  sku_name            = "standard"

  # RBAC authorization model (modern approach)
  enable_rbac_authorization   = true
  public_network_access_enabled = true

  # Soft delete and purge protection
  soft_delete_retention_days = 7
  purge_protection_enabled   = false # Disabled for easier cleanup in CTF environment

  tags = {
    Environment = var.environment
    Challenge   = "04-azure-only"
    Purpose     = "Secret Management"
    Component   = "Key Vault"
  }
}

# Role assignment for the current user (deployer) to manage secrets
resource "azurerm_role_assignment" "kv_admin_current_user" {
  scope                = azurerm_key_vault.medicloudx_vault.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azuread_client_config.current.object_id
}

# Role assignment for App Service to read secrets
resource "azurerm_role_assignment" "kv_secrets_user_app_service" {
  scope                = azurerm_key_vault.medicloudx_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.medicloudx_onboarding.identity[0].principal_id

  depends_on = [azurerm_linux_web_app.medicloudx_onboarding]
}

# Role assignment for the Service Principal to read secrets
resource "azurerm_role_assignment" "kv_secrets_user_sp" {
  scope                = azurerm_key_vault.medicloudx_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azuread_service_principal.medicloudx_sp.object_id
}

# Wait for role assignments to propagate
resource "time_sleep" "wait_for_rbac" {
  depends_on = [
    azurerm_role_assignment.kv_admin_current_user,
    azurerm_role_assignment.kv_secrets_user_app_service,
    azurerm_role_assignment.kv_secrets_user_sp
  ]

  create_duration = "60s"
}
