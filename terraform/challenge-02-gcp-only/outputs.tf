# Basic Secret Information
output "gcp_secret_name" {
  description = "GCP Secret Manager secret name"
  value       = google_secret_manager_secret.medicloudx_store.secret_id
}

output "gcp_secret_id" {
  description = "GCP Secret Manager secret ID"
  value       = google_secret_manager_secret.medicloudx_store.id
}

output "gcp_secret_version" {
  description = "GCP Secret Manager secret version"
  value       = google_secret_manager_secret_version.medicloudx_store_version.id
}

output "secret_full_name" {
  description = "Full resource name of the secret"
  value       = google_secret_manager_secret.medicloudx_store.name
}

# Challenge Information
output "flag_identifier" {
  description = "Flag identifier (but not the actual value for security)"
  value       = "medicloudx-store-secret contains a flag with UUID format"
}

output "challenge_info" {
  description = "Challenge 2 GCP - Secret Manager Information"
  value = {
    challenge_name = "Challenge-02-GCP: Secret Manager User Access"
    secret_name    = google_secret_manager_secret.medicloudx_store.secret_id
    vulnerability  = "User-specific access to Secret Manager"
    objective      = "Access Secret Manager with authenticated user to retrieve flag"
    attack_method  = "Use gcloud secrets versions access with authenticated user"
  }
}

# API Information
output "api_endpoints" {
  description = "Important API endpoints and commands for the challenge"
  value = {
    gcloud_command = "gcloud secrets versions access 1 --secret=medicloudx-store-secret"
    rest_api       = "https://secretmanager.googleapis.com/v1/projects/${var.gcp_project_id}/secrets/medicloudx-store-secret/versions/1:access"
    project_id     = var.gcp_project_id
    secret_id      = "medicloudx-store-secret"
  }
}

# Framework Standard Outputs
output "gcp_flag" {
  description = "GCP Challenge Flag (actual value hidden for security)"
  value       = "CLD[generated-uuid-from-terraform]"
  sensitive   = false
}

output "challenge_summary" {
  description = "Challenge summary for framework integration"
  value = {
    challenge_id = "challenge-02-gcp-only"
    name = "Secret Manager User Access"
    provider = "GCP"
    difficulty = "basic"
    objective = "Access Secret Manager with authenticated user to retrieve flag"
    secret_name = google_secret_manager_secret.medicloudx_store.secret_id
    vulnerability = "IAM policy grants roles/secretmanager.secretAccessor to specific user"
    attack_method = "Authenticated access via gcloud CLI"
    flag_format = "CLD[UUID]"
    dependencies = []
  }
}

output "attack_vectors" {
  description = "Available attack vectors for this challenge"
  value = {
    vector_1 = {
      name = "Secret Manager Authenticated Access"
      target = "medicloudx-store-secret"
      difficulty = "Basic"
      prerequisites = ["GCP CLI installed and authenticated", "Basic knowledge of Secret Manager"]
      steps = [
        "Authenticate with gcloud CLI using provided credentials",
        "Discover the secret name: medicloudx-store-secret",
        "Execute: gcloud secrets versions access 1 --secret=medicloudx-store-secret",
        "Extract flag from secret value"
      ]
      commands = {
        gcloud = "gcloud secrets versions access 1 --secret=medicloudx-store-secret"
        curl = "curl -H 'Authorization: Bearer $(gcloud auth print-access-token)' https://secretmanager.googleapis.com/v1/projects/${var.gcp_project_id}/secrets/medicloudx-store-secret/versions/1:access"
      }
      flag_format = "CLD[UUID]"
      user_credentials = "${var.gcp_user_email} has access"
    }
  }
}
