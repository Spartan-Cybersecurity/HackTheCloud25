terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "gcs" {
    # Configuration will be provided via backend config file
  }
}

# Provider configuration
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# Generate random UUID for the flag
resource "random_uuid" "flag" {}

locals {
  flag_value = "CLD[${random_uuid.flag.result}]"
}

# GCP Secret Manager Resources (converted from module)
resource "google_secret_manager_secret" "medicloudx_store" {
  secret_id = "medicloudx-store-secret"
  
  labels = {
    challenge = "challenge-02-gcp-only"
    cloud     = "gcp"
    project   = var.project_name
  }
  
  replication {
    auto {}
  }
}

# Secret version with flag data
resource "google_secret_manager_secret_version" "medicloudx_store_version" {
  secret      = google_secret_manager_secret.medicloudx_store.id
  secret_data = local.flag_value
}

# IAM policy for specific user access
resource "google_secret_manager_secret_iam_member" "user_access" {
  secret_id = google_secret_manager_secret.medicloudx_store.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "user:${var.gcp_user_email}"
}
