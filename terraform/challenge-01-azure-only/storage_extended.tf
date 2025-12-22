# Extended Storage Resources for MediCloudX Research Portal
# This adds the private container and SAS token functionality to challenge-01

# Private container for sensitive research files
resource "azurerm_storage_container" "medicloud_research" {
  name                  = "medicloud-research"
  storage_account_name  = azurerm_storage_account.website.name
  container_access_type = "private"
}

# Research portal container (public)
resource "azurerm_storage_container" "research_portal" {
  name                  = "research-portal"
  storage_account_name  = azurerm_storage_account.website.name
  container_access_type = "blob"
}

# Upload research image to private container
resource "azurerm_storage_blob" "research_image" {
  name                   = "close-up-doctor-holding-red-heart.jpg"
  storage_account_name   = azurerm_storage_account.website.name
  storage_container_name = azurerm_storage_container.medicloud_research.name
  type                   = "Block"
  source                 = "${path.module}/../../web-content/azure-challenge-02/close-up-doctor-holding-red-heart.jpg"
}

# Upload base64 encoded certificate to private container
resource "azurerm_storage_blob" "certificate_b64" {
  name                   = "certificadob64delpfx.txt"
  storage_account_name   = azurerm_storage_account.website.name
  storage_container_name = azurerm_storage_container.medicloud_research.name
  type                   = "Block"
  content_type           = "text/plain"
  source_content         = data.local_file.medicloud_pfx.content_base64
}

# Upload PowerShell script to private container
resource "azurerm_storage_blob" "powershell_script" {
  name                   = "script.ps1"
  storage_account_name   = azurerm_storage_account.website.name
  storage_container_name = azurerm_storage_container.medicloud_research.name
  type                   = "Block"
  content_type           = "text/plain"
  source_content         = local_file.processed_script.content
}

# Upload flag to private container
resource "azurerm_storage_blob" "medicloud_flag" {
  name                   = "flag.txt"
  storage_account_name   = azurerm_storage_account.website.name
  storage_container_name = azurerm_storage_container.medicloud_research.name
  type                   = "Block"
  content_type           = "text/plain"
  source                 = "${path.module}/../../web-content/azure-challenge-02/flag.txt"
}

# Create proper PKCS#12 certificate using external openssl command
resource "null_resource" "create_pfx" {
  provisioner "local-exec" {
    command = <<-EOT
      openssl pkcs12 -export -out "${path.module}/../../web-content/azure-challenge-02/medicloud_cert.pfx" \
        -inkey <(echo '${tls_private_key.medicloud_cert_key.private_key_pem}') \
        -in <(echo '${tls_self_signed_cert.medicloud_cert.cert_pem}') \
        -passout pass:M3d1Cl0ud25!
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
  
  triggers = {
    cert_pem = tls_self_signed_cert.medicloud_cert.cert_pem
    key_pem  = tls_private_key.medicloud_cert_key.private_key_pem
  }
  
  depends_on = [
    tls_self_signed_cert.medicloud_cert,
    tls_private_key.medicloud_cert_key
  ]
}

# Read the generated PFX file for base64 encoding
data "local_file" "medicloud_pfx" {
  filename = "${path.module}/../../web-content/azure-challenge-02/medicloud_cert.pfx"
  depends_on = [null_resource.create_pfx]
}

# Generate SAS token for private container access
data "azurerm_storage_account_blob_container_sas" "medicloud_sas" {
  connection_string = azurerm_storage_account.website.primary_connection_string
  container_name    = azurerm_storage_container.medicloud_research.name
  https_only        = true
  
  start  = timestamp()
  expiry = timeadd(timestamp(), "8760h")  # 1 año
  
  permissions {
    read   = true
    add    = false
    create = false
    write  = false
    delete = false
    list   = true
  }
}
