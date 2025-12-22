# App Service Plan for hosting the containerized Next.js application

resource "azurerm_service_plan" "medicloudx_plan" {
  name                = "medicloudx-onboarding-plan-${random_string.suffix.result}"
  location            = azurerm_resource_group.medicloudx_identity.location
  resource_group_name = azurerm_resource_group.medicloudx_identity.name
  os_type             = "Linux"
  sku_name            = var.app_service_sku

  tags = {
    Environment = var.environment
    Challenge   = "04-azure-only"
    Purpose     = "Container Hosting"
    Component   = "App Service Plan"
  }
}

# Linux Web App for Containers
resource "azurerm_linux_web_app" "medicloudx_onboarding" {
  name                = "medicloudx-onboarding-${random_string.suffix.result}"
  location            = azurerm_resource_group.medicloudx_identity.location
  resource_group_name = azurerm_resource_group.medicloudx_identity.name
  service_plan_id     = azurerm_service_plan.medicloudx_plan.id

  # Enable system-assigned managed identity
  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on = false # Must be false for Free (F1) tier
    
    # Configure container settings
    application_stack {
      docker_image     = "${azurerm_container_registry.medicloudx_acr.login_server}/medicloudx-onboarding"
      docker_image_tag = var.docker_image_tag
    }

    # Configure container registry credentials
    container_registry_use_managed_identity = true
  }

  # App settings for the Next.js application
  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "WEBSITES_PORT"                       = "3000"
    "NODE_ENV"                           = "production"
    "NEXT_TELEMETRY_DISABLED"            = "1"
    
    # Azure AD/Microsoft Graph settings (for demonstration)
    "AZURE_CLIENT_ID"     = azuread_application.medicloudx_app.client_id
    "AZURE_TENANT_ID"     = var.azure_tenant_id
    "AZURE_CLIENT_SECRET" = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.medicloudx_vault.name};SecretName=client-secret)"
  }

  # Authentication disabled to allow demonstration of the vulnerability
  # auth_settings_v2 block is omitted to disable App Service authentication

  tags = {
    Environment = var.environment
    Challenge   = "04-azure-only"
    Purpose     = "Vulnerable Web Application"
    Component   = "App Service"
    CVE         = "2025-29927"
  }

  depends_on = [
    null_resource.docker_build_push
  ]
}

# Role assignment for App Service to pull images from ACR
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.medicloudx_acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.medicloudx_onboarding.identity[0].principal_id

  depends_on = [azurerm_linux_web_app.medicloudx_onboarding]
}

# Custom domain (optional - for more realistic setup)
# Uncomment if you have a custom domain configured
# resource "azurerm_app_service_custom_hostname_binding" "medicloudx_domain" {
#   hostname            = "medicloudx-onboarding.${var.custom_domain}"
#   app_service_name    = azurerm_linux_web_app.medicloudx_onboarding.name
#   resource_group_name = azurerm_resource_group.medicloudx_identity.name
# }
