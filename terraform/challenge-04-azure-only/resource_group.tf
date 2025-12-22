# Resource Group for MediCloudX Identity Management

resource "azurerm_resource_group" "medicloudx_identity" {
  name     = "medicloudx-identity-${random_string.suffix.result}"
  location = var.location

  tags = {
    Environment = var.environment
    Challenge   = "04-azure-only"
    Purpose     = "MediCloudX Workforce Onboarding"
    Component   = "Identity Management"
    CVE         = "2025-29927"
    Framework   = "Next.js"
  }
}
