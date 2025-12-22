output "gcp_website_url" {
  description = "GCP Cloud Storage website URL"
  value       = "https://storage.googleapis.com/${google_storage_bucket.website.name}/index.html"
}

output "gcp_bucket_name" {
  description = "GCP Cloud Storage bucket name"
  value       = google_storage_bucket.website.name
}

output "gcp_flag_url" {
  description = "GCP Cloud Storage flag URL"
  value       = "https://storage.googleapis.com/${google_storage_bucket.website.name}/flag.txt"
}

output "gcp_discovery_key_url" {
  description = "GCP Cloud Storage discovery key URL"
  value       = "https://storage.googleapis.com/${google_storage_bucket.website.name}/medicloudx-discovery-key.json.b64"
}

output "gcp_flag" {
  description = "GCP Challenge Flag"
  value       = "CLD[c9d5e1g4-6h0f-6c3d-be5g-9h4c7f0d8g6e]"
}

output "challenge_summary" {
  description = "Challenge 1 GCP - Summary"
  value = {
    website       = "https://storage.googleapis.com/${google_storage_bucket.website.name}/index.html"
    flag_url      = "https://storage.googleapis.com/${google_storage_bucket.website.name}/flag.txt"
    flag          = "CLD[c9d5e1g4-6h0f-6c3d-be5g-9h4c7f0d8g6e]"
    bucket        = google_storage_bucket.website.name
    discovery_key = "https://storage.googleapis.com/${google_storage_bucket.website.name}/medicloudx-discovery-key.json.b64"
  }
}

output "attack_vectors" {
  description = "GCP Challenge Attack Vectors"
  value = {
    vector_1 = {
      name = "Public Bucket Enumeration"
      target = "https://storage.googleapis.com/${google_storage_bucket.website.name}/flag.txt"
      difficulty = "Basic"
      flag = "CLD[c9d5e1g4-6h0f-6c3d-be5g-9h4c7f0d8g6e]"
    }
  }
}
