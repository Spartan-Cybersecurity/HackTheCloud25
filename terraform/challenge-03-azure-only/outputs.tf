# Outputs for Challenge-03-Azure-Only

output "key_vault_name" {
  description = "Name of the Azure Key Vault"
  value       = azurerm_key_vault.challenge_03_vault.name
}

output "key_vault_uri" {
  description = "URI of the Azure Key Vault"
  value       = azurerm_key_vault.challenge_03_vault.vault_uri
}

output "resource_group_name" {
  description = "Name of the resource group containing the Key Vault"
  value       = azurerm_resource_group.challenge_03.name
}

output "service_principal_object_id" {
  description = "Object ID of the Service Principal from Challenge-01"
  value       = data.azuread_service_principal.medicloud_sp.object_id
}

output "service_principal_client_id" {
  description = "Client ID of the Service Principal from Challenge-01"
  value       = data.azuread_service_principal.medicloud_sp.client_id
}

output "challenge_info" {
  description = "Challenge information and attack targets"
  value = {
    challenge_name = "Challenge-03: Azure Key Vault Privilege Escalation"
    objective      = "Use compromised Service Principal from Challenge-01 to access Key Vault secrets"
    key_vault_name = azurerm_key_vault.challenge_03_vault.name
    key_vault_uri  = azurerm_key_vault.challenge_03_vault.vault_uri
    target_secrets = [
      "flag"
    ]
    required_tokens = [
      "https://management.azure.com/.default",
      "https://vault.azure.net/.default"
    ]
  }
}

output "role_assignments" {
  description = "Role assignments granted to the Service Principal"
  value = {
    key_vault_secrets_user = {
      scope = azurerm_key_vault.challenge_03_vault.id
      role  = "Key Vault Secrets User"
    }
    key_vault_reader = {
      scope = azurerm_key_vault.challenge_03_vault.id
      role  = "Key Vault Reader"
    }
    resource_group_reader = {
      scope = azurerm_resource_group.challenge_03.id
      role  = "Reader"
    }
  }
}

output "api_endpoints" {
  description = "Key Vault API endpoints for the challenge"
  value = {
    secrets_base_url = "${azurerm_key_vault.challenge_03_vault.vault_uri}secrets/"
    flag_secret_url  = "${azurerm_key_vault.challenge_03_vault.vault_uri}secrets/flag/?api-version=7.3"
    api_version = "7.3"
  }
}

output "attack_summary" {
  description = "Summary of the attack flow for this challenge"
  sensitive   = true
  value = {
    step_1 = "Use Service Principal certificate from Challenge-01"
    step_2 = "Generate management.azure.com token and connect with Connect-AzAccount"
    step_3 = "Verify permissions with Get-AzRoleAssignment"
    step_4 = "Generate vault.azure.net token for Key Vault access"
    step_5 = "Access secrets via REST API with Invoke-WebRequest"
    flag_location = "${azurerm_key_vault.challenge_03_vault.vault_uri}secrets/flag/?api-version=7.3"
    flag_value = "CLD[8f2e9b5a-3c7d-4a1e-9f6b-2d8c5e4a7f3b]"
  }
}

# Framework Standard Outputs
output "azure_flag" {
  description = "Azure Challenge Flag"
  value       = "CLD[8f2e9b5a-3c7d-4a1e-9f6b-2d8c5e4a7f3b]"
}

output "challenge_summary" {
  description = "Challenge summary for framework integration"
  value = {
    challenge_id = "challenge-03-azure-only"
    name = "Azure Key Vault Privilege Escalation"
    provider = "Azure"
    difficulty = "advanced"
    objective = "Use compromised Service Principal from Challenge-01 to access Key Vault secrets"
    key_vault_name = azurerm_key_vault.challenge_03_vault.name
    key_vault_uri = azurerm_key_vault.challenge_03_vault.vault_uri
    service_principal_id = data.azuread_service_principal.medicloud_sp.client_id
    flag_location = "${azurerm_key_vault.challenge_03_vault.vault_uri}secrets/flag/?api-version=7.3"
    dependencies = ["challenge-01-azure-only"]
  }
}

output "attack_vectors" {
  description = "Available attack vectors for this challenge"
  value = {
    vector_1 = {
      name = "Key Vault Privilege Escalation"
      target = "${azurerm_key_vault.challenge_03_vault.vault_uri}secrets/flag/?api-version=7.3"
      difficulty = "Advanced"
      prerequisites = ["Service Principal certificate from Challenge-01"]
      steps = [
        "Generate management.azure.com token with certificate authentication",
        "Connect to Azure with Connect-AzAccount using certificate",
        "Verify permissions with Get-AzRoleAssignment",
        "Generate vault.azure.net token for Key Vault access",
        "Access secrets via REST API with proper authentication"
      ]
      flag = "CLD[8f2e9b5a-3c7d-4a1e-9f6b-2d8c5e4a7f3b]"
    }
  }
}
