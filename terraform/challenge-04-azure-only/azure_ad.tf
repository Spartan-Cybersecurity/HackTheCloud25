# Azure AD Application Registration for MediCloudX Onboarding

# Get current client configuration
data "azuread_client_config" "current" {}

# Azure AD Application
resource "azuread_application" "medicloudx_app" {
  display_name     = "MediCloudX-Onboarding-${random_string.suffix.result}"
  owners           = [data.azuread_client_config.current.object_id]
  sign_in_audience = "AzureADMyOrg"

  # Required resource access for Microsoft Graph API
  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    # Application permissions (requires admin consent)
    resource_access {
      id   = "62a82d76-70ea-41e2-9197-370581804d09" # Group.ReadWrite.All
      type = "Role"
    }

    resource_access {
      id   = "741f803b-c850-494e-b5df-cde7c675a1ca" # User.ReadWrite.All
      type = "Role"
    }

    resource_access {
      id   = "19dbc75e-c2e2-444c-a770-ec69d8559fc7" # Directory.ReadWrite.All
      type = "Role"
    }

    # Delegated permissions
    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }
  }

  # Web application configuration
  web {
    homepage_url  = "https://medicloudx-onboarding-${random_string.suffix.result}.azurewebsites.net"
    redirect_uris = [
      "https://medicloudx-onboarding-${random_string.suffix.result}.azurewebsites.net/auth/callback",
      "https://medicloudx-onboarding-${random_string.suffix.result}.azurewebsites.net/login"
    ]

    implicit_grant {
      access_token_issuance_enabled = true
      id_token_issuance_enabled     = true
    }
  }

  # API configuration
  api {
    mapped_claims_enabled          = false
    requested_access_token_version = 2
  }

  tags = ["MediCloudX", "Onboarding", "CTF", "Challenge-04"]
}

# Service Principal for the application
resource "azuread_service_principal" "medicloudx_sp" {
  client_id                    = azuread_application.medicloudx_app.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]

  tags = ["MediCloudX", "Onboarding", "ServicePrincipal"]
}

# Application Password (Client Secret)
resource "azuread_application_password" "medicloudx_secret" {
  application_id = azuread_application.medicloudx_app.id
  display_name          = "MediCloudX-Onboarding-Secret"
  end_date_relative     = "8760h" # 1 year
}

# Grant admin consent for the required permissions
# This is typically done manually in the Azure portal, but can be automated
resource "azuread_app_role_assignment" "user_readwrite_all" {
  app_role_id         = "741f803b-c850-494e-b5df-cde7c675a1ca" # User.ReadWrite.All
  principal_object_id = azuread_service_principal.medicloudx_sp.object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

resource "azuread_app_role_assignment" "group_readwrite_all" {
  app_role_id         = "62a82d76-70ea-41e2-9197-370581804d09" # Group.ReadWrite.All
  principal_object_id = azuread_service_principal.medicloudx_sp.object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

resource "azuread_app_role_assignment" "directory_readwrite_all" {
  app_role_id         = "19dbc75e-c2e2-444c-a770-ec69d8559fc7" # Directory.ReadWrite.All
  principal_object_id = azuread_service_principal.medicloudx_sp.object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

# Microsoft Graph Service Principal (built-in)
data "azuread_service_principal" "msgraph" {
  client_id = "00000003-0000-0000-c000-000000000000"
}

# Additional role assignment: Assign the App Service Managed Identity the User.ReadWrite.All role
resource "azuread_app_role_assignment" "app_service_user_readwrite" {
  app_role_id         = "741f803b-c850-494e-b5df-cde7c675a1ca" # User.ReadWrite.All
  principal_object_id = azurerm_linux_web_app.medicloudx_onboarding.identity[0].principal_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id

  depends_on = [azurerm_linux_web_app.medicloudx_onboarding]
}
