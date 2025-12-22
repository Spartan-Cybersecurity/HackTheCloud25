# Variables for Challenge-03-Azure-Only

variable "azure_location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "azure_tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "azure_ad_app_display_name" {
  description = "Azure AD Application display name from Challenge-01 deployment"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "CTF-25"
    Challenge   = "Challenge-03-Azure-Only"
    Purpose     = "Key Vault Privilege Escalation"
    Owner       = "EkoCloudSec"
  }
}
