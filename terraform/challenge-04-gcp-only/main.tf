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

# Generate random suffix for unique database name
resource "random_id" "database_suffix" {
  byte_length = 4
}

locals {
  flag_value = "CLD[${random_uuid.flag.result}]"
  database_name = "medicloudx-store-${random_id.database_suffix.hex}"
  
  # Create sample audit log entries for the challenge
  log_entries = {
    "log_entry_001" = {
      timestamp = { string_value = "2025-09-01T12:00:01Z" }
      action    = { string_value = "LOGIN_SUCCESS" }
      user      = { string_value = "admin@medicloudx.com" }
      ip        = { string_value = "192.168.1.100" }
      details   = { string_value = "Successfully authenticated via password" }
    },
    "log_entry_002" = {
      timestamp = { string_value = "2025-09-01T12:05:23Z" }
      action    = { string_value = "VIEW_PATIENT_RECORD" }
      user      = { string_value = "doctor1@medicloudx.com" }
      ip        = { string_value = "192.168.1.105" }
      details   = { string_value = "Viewed patient record #12345" }
    },
    "log_entry_003" = {
      timestamp = { string_value = "2025-09-01T12:10:45Z" }
      action    = { string_value = "UPDATE_PATIENT_RECORD" }
      user      = { string_value = "nurse2@medicloudx.com" }
      ip        = { string_value = "192.168.1.110" }
      details   = { string_value = "Updated vitals for patient record #12345" }
    },
    "log_entry_004" = {
      timestamp = { string_value = "2025-09-01T12:15:12Z" }
      action    = { string_value = "FAILED_LOGIN" }
      user      = { string_value = "unknown@medicloudx.com" }
      ip        = { string_value = "203.0.113.45" }
      details   = { string_value = "Failed login attempt - password incorrect" }
    },
    "log_entry_005" = {
      timestamp = { string_value = "2025-09-01T12:20:33Z" }
      action    = { string_value = "SYSTEM_UPDATE" }
      user      = { string_value = "system@medicloudx.com" }
      ip        = { string_value = "127.0.0.1" }
      details   = { string_value = "Applied security patches - version 2.3.4" }
    },
    "log_entry_006" = {
      timestamp = { string_value = "2025-09-01T13:01:19Z" }
      action    = { string_value = "API_ACCESS" }
      user      = { string_value = "api-service@medicloudx.com" }
      ip        = { string_value = "10.0.0.8" }
      details   = { string_value = "Called patient data API" }
    },
    "flag_entry" = {
      timestamp = { string_value = "2025-09-01T13:37:42Z" }
      action    = { string_value = "SECRET_BACKUP" }
      user      = { string_value = "backup-service@medicloudx.com" }
      ip        = { string_value = "10.0.0.10" }
      details   = { string_value = "Backup process completed" }
      secret    = { string_value = local.flag_value }
    },
    "log_entry_007" = {
      timestamp = { string_value = "2025-09-01T14:15:08Z" }
      action    = { string_value = "LOGOUT" }
      user      = { string_value = "doctor1@medicloudx.com" }
      ip        = { string_value = "192.168.1.105" }
      details   = { string_value = "User session ended" }
    }
  }
}

# Create the Firestore database directly
resource "google_firestore_database" "database" {
  name        = local.database_name
  location_id = var.gcp_region
  type        = "FIRESTORE_NATIVE"
  project     = var.gcp_project_id

  # Set delete protection to false for easy cleanup
  delete_protection_state = "DELETE_PROTECTION_DISABLED"
}

# Create only the special document with the flag
resource "google_firestore_document" "flag_document" {
  project     = google_firestore_database.database.project
  database    = google_firestore_database.database.name
  collection  = "medicloudx-store-audit-logs"
  document_id = "flag_entry"

  fields = jsonencode({
    timestamp = { stringValue = "2025-09-01T13:37:42Z" },
    action    = { stringValue = "SECRET_BACKUP" },
    user      = { stringValue = "backup-service@medicloudx.com" },
    ip        = { stringValue = "10.0.0.10" },
    details   = { stringValue = "Backup process completed" },
    secret    = { stringValue = "CLD[${random_uuid.flag.result}]" }
  })

  # Wait for database to be fully ready
  depends_on = [google_firestore_database.database]

  timeouts {
    create = "2m"
    update = "2m"
    delete = "2m"
  }
}
