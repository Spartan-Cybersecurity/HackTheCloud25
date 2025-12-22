terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    # Configuration loaded from backend-configs/azure.hcl
  }
}

# Provider configuration
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  tenant_id       = var.azure_tenant_id
}

provider "azuread" {
  tenant_id = var.azure_tenant_id
}

# Random suffix for unique resource names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Azure Storage Infrastructure (migrated from module)
# Random suffix for unique resource naming
resource "random_id" "storage_suffix" {
  byte_length = 4
}

# Resource group
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-rg-${random_id.storage_suffix.hex}"
  location = var.azure_location

  tags = {
    Challenge = "challenge-01-azure-only"
    Cloud     = "azure"
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

# Storage account
resource "azurerm_storage_account" "website" {
  name                     = "ctf25sa${random_id.storage_suffix.hex}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  # Enable static website hosting
  static_website {
    index_document     = "index.html"
    error_404_document = "error.html"
  }

  # Allow public access (intentionally misconfigured for CTF)
  allow_nested_items_to_be_public = true
  public_network_access_enabled   = true

  tags = {
    Challenge = "challenge-01-azure-only"
    Cloud     = "azure"
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

# Upload index.html
resource "azurerm_storage_blob" "index" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.website.name
  storage_container_name = "$web"
  type                   = "Block"
  source                 = "${path.module}/../../web-content/azure-challenge-01/index.html"
  content_type           = "text/html"
}

# Upload flag.txt
resource "azurerm_storage_blob" "flag" {
  name                   = "flag.txt"
  storage_account_name   = azurerm_storage_account.website.name
  storage_container_name = "$web"
  type                   = "Block"
  source                 = "${path.module}/../../web-content/azure-challenge-01/flag.txt"
  content_type           = "text/plain"
}
