variable "aws_region" {
  description = "AWS region for the challenge resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS profile to use for authentication"
  type        = string
  default     = "default"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "flag_content" {
  description = "CTF flag content"
  type        = string
  default     = "CLD[6b2e7f8a-5d3c-4a1e-9b8f-2c6d8e4a7f9b]"
}


variable "patient_records_count" {
  description = "Number of fake patient records to generate"
  type        = number
  default     = 50
}
