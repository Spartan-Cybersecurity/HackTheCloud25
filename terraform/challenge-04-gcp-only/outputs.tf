output "gcp_database_name" {
  description = "GCP Firestore database name"
  value       = google_firestore_database.database.name
}

output "gcp_collection_path" {
  description = "GCP Firestore collection path"
  value       = "medicloudx-store-audit-logs"
}

output "gcp_database_url" {
  description = "GCP Firestore database URL"
  value       = "https://console.cloud.google.com/firestore/data?project=${var.gcp_project_id}"
}

output "challenge_hint" {
  description = "Challenge 4 GCP - Firestore Database Hint"
  value       = "Check the audit logs collection for suspicious entries. One of the logs contains a 'secret' field that shouldn't be there."
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
    challenge_id = "challenge-04-gcp-only"
    name = "Firestore Database Audit Log Analysis"
    provider = "GCP"
    difficulty = "intermediate"
    objective = "Analyze Firestore audit logs to find hidden flag in log entries"
    database = google_firestore_database.database.name
    collection = "medicloudx-store-audit-logs"
    vulnerability = "Sensitive data accidentally stored in audit logs"
    attack_method = "Query Firestore collection to find log entry with embedded secret"
    flag_format = "CLD[UUID]"
    dependencies = []
  }
}

output "attack_vectors" {
  description = "Available attack vectors for this challenge"
  value = {
    vector_1 = {
      name = "Firestore Audit Log Analysis"
      target = "medicloudx-store-audit-logs collection"
      difficulty = "Intermediate"
      prerequisites = ["GCP CLI installed", "Basic knowledge of Firestore"]
      steps = [
        "Access Firestore database: ${google_firestore_database.database.name}",
        "Query the medicloudx-store-audit-logs collection",
        "Analyze log entries for unusual or extra fields",
        "Look for 'secret' field in backup-related entries",
        "Extract flag from the secret field"
      ]
      commands = {
        console_url = "https://console.cloud.google.com/firestore/data?project=${var.gcp_project_id}&database=${google_firestore_database.database.name}"
        gcloud_query = "gcloud firestore collections list --database=${google_firestore_database.database.name}"
        query_collection = "gcloud firestore documents list medicloudx-store-audit-logs --database=${google_firestore_database.database.name}"
      }
      flag_format = "CLD[UUID]"
      hint = "One of the audit logs contains more than standard fields - look for the backup entry"
    }
  }
}

# Original Challenge Summary (Preserved)
output "challenge_info" {
  description = "Challenge 4 GCP - Firestore Database Summary"
  value = {
    database   = google_firestore_database.database.name
    collection = "medicloudx-store-audit-logs"
    hint       = "One of the audit logs contains more than standard fields - look for the backup entry"
  }
}
