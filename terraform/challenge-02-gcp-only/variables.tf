variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
  default     = "arctic-bee-470901-c4"
}

variable "gcp_region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-east1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "ctf-25"
}

variable "gcp_user_email" {
  description = "Email address of the GCP user who will have access to the secret"
  type        = string
}
