# Template processing for dynamic content injection

# Process research portal HTML with SAS token
resource "local_file" "processed_research_html" {
  content = templatefile("${path.module}/../../web-content/azure-challenge-02/index.html.tftpl", {
    storage_account_name = azurerm_storage_account.website.name
    sas_token           = data.azurerm_storage_account_blob_container_sas.medicloud_sas.sas
    azure_tenant_id     = var.azure_tenant_id
    app_client_id       = azuread_application.medicloud_app.client_id
  })
  filename = "${path.module}/../../web-content/azure-challenge-01/research-portal.html"
}

# Process PowerShell script with dynamic values
resource "local_file" "processed_script" {
  content = templatefile("${path.module}/../../web-content/azure-challenge-02/script.ps1.tftpl", {
    azure_tenant_id     = var.azure_tenant_id
    app_client_id       = azuread_application.medicloud_app.client_id
    storage_account_name = azurerm_storage_account.website.name
  })
  filename = "${path.module}/../../web-content/azure-challenge-02/script.ps1"
}

# Upload processed research portal HTML to public container
resource "azurerm_storage_blob" "research_portal_html" {
  name                   = "research-portal.html"
  storage_account_name   = azurerm_storage_account.website.name
  storage_container_name = azurerm_storage_container.research_portal.name
  type                   = "Block"
  content_type           = "text/html"
  source                 = local_file.processed_research_html.filename
  
  depends_on = [local_file.processed_research_html]
}
