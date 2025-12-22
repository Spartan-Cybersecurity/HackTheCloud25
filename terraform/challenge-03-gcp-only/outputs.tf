# Basic Bucket Information
output "gcp_bucket_name" {
  description = "GCP Cloud Storage bucket name"
  value       = google_storage_bucket.medicloudx_store.name
}

output "gcp_bucket_url" {
  description = "GCP Cloud Storage bucket URL"
  value       = google_storage_bucket.medicloudx_store.url
}

output "bucket_self_link" {
  description = "GCP Cloud Storage bucket self link"
  value       = google_storage_bucket.medicloudx_store.self_link
}

output "flag_path" {
  description = "Path to the flag file in the private bucket"
  value       = "flag.txt"
}

output "flag_url" {
  description = "GS URL to the flag file"
  value       = "gs://${google_storage_bucket.medicloudx_store.name}/flag.txt"
}

# Challenge Information
output "challenge_info" {
  description = "Challenge 3 GCP - Private Bucket Information"
  value = {
    challenge_name = "Challenge-03-GCP: Private Bucket Access"
    bucket_name    = google_storage_bucket.medicloudx_store.name
    vulnerability  = "Private bucket requires proper authentication to access"
    objective      = "Find a way to access private bucket and retrieve flag"
    attack_method  = "Bypass access controls or exploit authentication mechanisms"
  }
}

# API Information
output "api_endpoints" {
  description = "Important API endpoints and commands for the challenge"
  value = {
    gsutil_command = "gsutil cat gs://${google_storage_bucket.medicloudx_store.name}/flag.txt"
    gcloud_command = "gcloud storage cat gs://${google_storage_bucket.medicloudx_store.name}/flag.txt"
    rest_api       = "https://storage.googleapis.com/storage/v1/b/${google_storage_bucket.medicloudx_store.name}/o/flag.txt?alt=media"
    bucket_name    = google_storage_bucket.medicloudx_store.name
    note           = "Private bucket requires proper authentication"
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
    challenge_id = "challenge-03-gcp-only"
    name = "Private Bucket Access"
    provider = "GCP"
    difficulty = "intermediate"
    objective = "Find a way to access private bucket and retrieve flag"
    bucket_name = google_storage_bucket.medicloudx_store.name
    vulnerability = "Private bucket with access control bypass potential"
    attack_method = "Bypass access controls or exploit authentication mechanisms"
    flag_format = "CLD[UUID]"
    dependencies = []
  }
}

output "attack_vectors" {
  description = "Available attack vectors for this challenge"
  value = {
    vector_1 = {
      name = "Private Bucket Access Challenge"
      target = google_storage_bucket.medicloudx_store.name
      difficulty = "Intermediate"
      prerequisites = ["GCP CLI installed", "Basic knowledge of Cloud Storage"]
      steps = [
        "Discover the private bucket: ${google_storage_bucket.medicloudx_store.name}",
        "Attempt anonymous access (should fail)",
        "Find alternative authentication or access method",
        "Access flag file once proper method is found"
      ]
      commands = {
        anonymous_attempt = "gsutil cat gs://${google_storage_bucket.medicloudx_store.name}/flag.txt"
        authenticated_access = "# Find proper authentication method"
      }
      flag_format = "CLD[UUID]"
      note = "Private bucket requires finding proper access method"
    }
  }
}
