# Key Vault Secrets for the MediCloudX Onboarding application

# Client Secret for Azure AD Application
resource "azurerm_key_vault_secret" "client_secret" {
  name         = "client-secret"
  value        = azuread_application_password.medicloudx_secret.value
  key_vault_id = azurerm_key_vault.medicloudx_vault.id

  depends_on = [
    time_sleep.wait_for_rbac,
    azuread_application_password.medicloudx_secret
  ]

  tags = {
    Purpose = "Azure AD Authentication"
    Type    = "ClientSecret"
  }
}

# Application Configuration
resource "azurerm_key_vault_secret" "app_config" {
  name         = "app-config"
  key_vault_id = azurerm_key_vault.medicloudx_vault.id
  
  value = jsonencode({
    tenant_id     = var.azure_tenant_id
    client_id     = azuread_application.medicloudx_app.client_id
    redirect_uri  = "https://medicloudx-onboarding-${random_string.suffix.result}.azurewebsites.net/auth/callback"
    scopes        = ["https://graph.microsoft.com/User.ReadWrite.All"]
  })

  depends_on = [time_sleep.wait_for_rbac]

  tags = {
    Purpose = "Application Configuration"
    Type    = "Config"
  }
}

# Demo credentials for the web application
resource "azurerm_key_vault_secret" "demo_credentials" {
  name         = "demo-credentials"
  key_vault_id = azurerm_key_vault.medicloudx_vault.id
  
  value = jsonencode({
    username = "hradmin"
    password = "MediCloudX2025!"
    note     = "Demo credentials for accessing the MediCloudX Onboarding portal"
  })

  depends_on = [time_sleep.wait_for_rbac]

  tags = {
    Purpose = "Demo Authentication"
    Type    = "Credentials"
  }
}

# Vulnerability information (for CTF participants to understand the challenge)
resource "azurerm_key_vault_secret" "vulnerability_info" {
  name         = "vulnerability-info"
  key_vault_id = azurerm_key_vault.medicloudx_vault.id
  
  value = jsonencode({
    cve_id          = "CVE-2025-29927"
    description     = "Next.js Middleware Authorization Bypass"
    bypass_header   = "x-middleware-subrequest"
    bypass_value    = "middleware:middleware:middleware:middleware:middleware"
    affected_endpoint = "/api/create-user"
    impact          = "Unauthorized Azure AD user creation"
  })

  depends_on = [time_sleep.wait_for_rbac]

  tags = {
    Purpose = "CTF Information"
    Type    = "Documentation"
  }
}
