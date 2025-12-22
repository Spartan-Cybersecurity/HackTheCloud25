# Data sources to reference existing resources from Challenge-01

# Get current Azure client configuration
data "azurerm_client_config" "current" {}

# Reference the existing Service Principal from Challenge-01
# We directly reference the specific app from Challenge-01
data "azuread_application" "medicloud_app" {
  display_name = var.azure_ad_app_display_name
}

data "azuread_service_principal" "medicloud_sp" {
  client_id = data.azuread_application.medicloud_app.client_id
}
