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

# First let's create the content directory if it doesn't exist
resource "local_file" "flag_file" {
  content  = "CLD[${random_uuid.flag.result}]"
  filename = "${path.module}/../../../web-content/gcp-challenge-03/flag.txt"

  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/../../../web-content/gcp-challenge-03"
  }
}

# Generate random UUID for the flag
resource "random_uuid" "flag" {}

# Random suffix for unique bucket name
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

locals {
  bucket_name = "medicloudx-store-bucket-${random_id.bucket_suffix.hex}"
}

# GCP Private Cloud Storage Bucket
resource "google_storage_bucket" "medicloudx_store" {
  name          = local.bucket_name
  location      = var.gcp_region
  force_destroy = true
  
  # Private bucket configuration
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  
  labels = {
    challenge = "challenge-03-gcp-only"
    cloud     = "gcp"
    project   = var.project_name
  }
}

# Upload flag file to private bucket
resource "google_storage_bucket_object" "flag" {
  name   = "flag.txt"
  bucket = google_storage_bucket.medicloudx_store.name
  source = local_file.flag_file.filename
  
  depends_on = [local_file.flag_file]
}

# IAM binding to give user access to the bucket (for challenge solution)
resource "google_storage_bucket_iam_member" "user_access" {
  bucket = google_storage_bucket.medicloudx_store.name
  role   = "roles/storage.objectViewer"
  member = "user:${var.gcp_user_email}"
}
