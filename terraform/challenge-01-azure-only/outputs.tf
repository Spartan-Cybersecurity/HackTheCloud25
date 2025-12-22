# Original Challenge-01 Outputs
output "azure_storage_website_endpoint" {
  description = "Azure Storage static website endpoint URL"
  value       = azurerm_storage_account.website.primary_web_endpoint
}

output "azure_storage_account_name" {
  description = "Azure Storage Account name"
  value       = azurerm_storage_account.website.name
}

output "azure_flag_url" {
  description = "Azure Storage flag URL (Challenge-01)"
  value       = "${azurerm_storage_account.website.primary_web_endpoint}flag.txt"
}

output "azure_flag" {
  description = "Azure Challenge Flag (Vector 1)"
  value       = "CLD[b8c4d0f3-5g9e-5b2c-ad4f-8g3b6e9c7f5d]"
}

output "azure_flag_advanced" {
  description = "Azure Challenge Flag (Vector 2 - Advanced)"
  value       = "CLD[d1f6e8b4-7c2a-4e9f-b5d8-3a1c9e7f2b6d]"
}

# Extended Challenge Outputs (MediCloudX Research Portal)
output "research_portal_url" {
  description = "MediCloudX Research Portal URL"
  value       = "https://${azurerm_storage_account.website.name}.blob.core.windows.net/research-portal/research-portal.html"
}

output "medicloud_sas_token" {
  description = "SAS token for medicloud-research container (intentionally exposed)"
  value       = data.azurerm_storage_account_blob_container_sas.medicloud_sas.sas
  sensitive   = true  # Required by Terraform but intentionally exposed in CTF
}

output "azure_ad_app_id" {
  description = "Azure AD Application Client ID"
  value       = azuread_application.medicloud_app.client_id
}

output "azure_ad_app_display_name" {
  description = "Azure AD Application Display Name"
  value       = azuread_application.medicloud_app.display_name
}

output "certificate_thumbprint" {
  description = "Certificate thumbprint for Azure AD authentication"
  value       = azuread_application_certificate.medicloud_cert.key_id
}


output "medicloud_research_container_url" {
  description = "Private container URL (requires SAS token)"
  value       = "https://${azurerm_storage_account.website.name}.blob.core.windows.net/medicloud-research/"
}

output "challenge_summary" {
  description = "Combined Challenge Summary"
  sensitive   = true
  value = {
    # Challenge-01 (Basic)
    basic_website = azurerm_storage_account.website.primary_web_endpoint
    basic_flag    = "${azurerm_storage_account.website.primary_web_endpoint}flag.txt"
    
    # Challenge-02 (Advanced)
    research_portal = "https://${azurerm_storage_account.website.name}.blob.core.windows.net/research-portal/research-portal.html"
    private_container = "https://${azurerm_storage_account.website.name}.blob.core.windows.net/medicloud-research/"
    sas_token = data.azurerm_storage_account_blob_container_sas.medicloud_sas.sas
    azure_ad_app = azuread_application.medicloud_app.client_id
    
    storage_account = azurerm_storage_account.website.name
  }
}

# Attack Vectors Summary
output "attack_vectors" {
  description = "Available attack vectors in this combined challenge"
  value = {
    vector_1 = {
      name = "Direct Storage Access (Challenge-01)"
      target = "${azurerm_storage_account.website.primary_web_endpoint}flag.txt"
      difficulty = "Basic"
      flag = "CLD[b8c4d0f3-5g9e-5b2c-ad4f-8g3b6e9c7f5d]"
    }
    vector_2 = {
      name = "SAS Token Extraction + Certificate Auth (Challenge-02)"
      target = "https://${azurerm_storage_account.website.name}.blob.core.windows.net/medicloud-research/flag.txt"
      difficulty = "Advanced"
      entry_point = "https://${azurerm_storage_account.website.name}.blob.core.windows.net/research-portal/research-portal.html"
      flag = "CLD[d1f6e8b4-7c2a-4e9f-b5d8-3a1c9e7f2b6d]"
    }
  }
}
