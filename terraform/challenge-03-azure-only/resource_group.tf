# Resource Group for Challenge-03 Key Vault resources

resource "azurerm_resource_group" "challenge_03" {
  name     = "rg-ctf-25-challenge-03-keyvault-${random_string.suffix.result}"
  location = var.azure_location
  
  tags = merge(var.tags, {
    Description = "Resource group for Challenge-03 Azure Key Vault privilege escalation"
    Suffix      = random_string.suffix.result
  })
}
