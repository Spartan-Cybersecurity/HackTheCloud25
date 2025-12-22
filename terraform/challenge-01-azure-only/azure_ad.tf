# Azure AD Application for MediCloudX Labs
resource "azuread_application" "medicloud_app" {
  display_name = "MediCloudXApp-${random_string.suffix.result}"
  
  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
    
    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }
    
    resource_access {
      id   = "19dbc75e-c2e2-444c-a770-ec69d8559fc7" # Directory.ReadWrite.All
      type = "Role"
    }
  }
  
  web {
    implicit_grant {
      access_token_issuance_enabled = true
      id_token_issuance_enabled     = true
    }
  }
}

# Upload certificate to Azure AD Application
resource "azuread_application_certificate" "medicloud_cert" {
  application_id = azuread_application.medicloud_app.id
  type           = "AsymmetricX509Cert"
  value          = replace(replace(tls_self_signed_cert.medicloud_cert.cert_pem, "-----BEGIN CERTIFICATE-----", ""), "-----END CERTIFICATE-----", "")
  end_date       = "2026-02-24T02:11:38Z"
  
  depends_on = [tls_self_signed_cert.medicloud_cert]
}

# Service Principal for the Application
resource "azuread_service_principal" "medicloud_sp" {
  client_id = azuread_application.medicloud_app.client_id
}

# Generate TLS private key for certificate
resource "tls_private_key" "medicloud_cert_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Generate self-signed certificate
resource "tls_self_signed_cert" "medicloud_cert" {
  private_key_pem = tls_private_key.medicloud_cert_key.private_key_pem
  
  subject {
    common_name  = "MediCloudX Labs Certificate"
    organization = "MediCloudX Labs"
  }
  
  validity_period_hours = 8760 # 1 year
  
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}

