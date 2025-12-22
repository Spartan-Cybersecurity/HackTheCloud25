variable "project_name" {
  description = "Name of the CTF project"
  type        = string
  default     = "ctf-25"
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS profile to use for authentication"
  type        = string
  default     = "default"
}

variable "allowed_cidr" {
  description = "CIDR block allowed to access the web application"
  type        = string
  default     = "0.0.0.0/0"
}
