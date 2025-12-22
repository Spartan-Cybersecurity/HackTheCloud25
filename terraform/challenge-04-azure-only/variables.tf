# Variables for Challenge-04-Azure-Only

variable "azure_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "azure_tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "challenge_prefix" {
  description = "Prefix for challenge resources"
  type        = string
  default     = "ctf-25-ch04"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "West US 2"  # Usually has better availability for new accounts
}

variable "docker_image_tag" {
  description = "Docker image tag for the vulnerable Next.js application"
  type        = string
  default     = "latest"
}

variable "app_service_sku" {
  description = "App Service Plan SKU"
  type        = string
  default     = "F1"  # Free tier for Azure free accounts
  
  validation {
    condition     = contains(["F1", "D1", "B1", "B2", "B3", "S1", "S2", "S3"], var.app_service_sku)
    error_message = "App Service SKU must be a valid tier."
  }
}
