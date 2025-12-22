# Key Vault secrets for Challenge-03
# Contains the flag for the privilege escalation challenge

# Sleep to allow RBAC role propagation
# Azure RBAC assignments can take time to propagate
resource "time_sleep" "wait_for_rbac_propagation" {
  depends_on = [azurerm_role_assignment.terraform_keyvault_secrets_officer]
  create_duration = "60s"
}

# Flag secret - the main target for the challenge
resource "azurerm_key_vault_secret" "flag" {
  name         = "flag"
  value        = "CLD[8f2e9b5a-3c7d-4a1e-9f6b-2d8c5e4a7f3b]"
  key_vault_id = azurerm_key_vault.challenge_03_vault.id
  
  content_type = "text/plain"
  
  tags = {
    Purpose     = "CTF Flag"
    Challenge   = "Challenge-03"
    Difficulty  = "Advanced"
  }
  
  depends_on = [
    azurerm_key_vault.challenge_03_vault,
    azurerm_role_assignment.sp_keyvault_secrets_user,
    azurerm_role_assignment.terraform_keyvault_secrets_officer,
    time_sleep.wait_for_rbac_propagation
  ]
}
