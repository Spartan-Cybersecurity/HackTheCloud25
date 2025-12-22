variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "ctf-25"
}

variable "challenge_name" {
  description = "Challenge name for resource naming"
  type        = string
  default     = "challenge-04-aws-only"
}

variable "domain_name" {
  description = "Active Directory domain name"
  type        = string
  default     = "medicloudx.local"
}

variable "dc_admin_password" {
  description = "Domain Controller administrator password"
  type        = string
  default     = "EkoCloudSec2025!"
  sensitive   = true
}

variable "svc_flag_password" {
  description = "Service account password (intentionally weak for CTF)"
  type        = string
  default     = "Password123!"
  sensitive   = true
}

variable "aws_profile" {
  description = "AWS profile to use for authentication"
  type        = string
  default     = "default"
}

variable "allowed_cidr" {
  description = "CIDR block allowed to access the environment (legacy variable)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "create_key_pair" {
  description = "Whether to create an EC2 key pair"
  type        = bool
  default     = false
}

variable "public_key" {
  description = "Public key for EC2 key pair (only used if create_key_pair is true)"
  type        = string
  default     = ""
}

variable "make_snapshot_public" {
  description = "Make the EBS snapshot public for CTF challenge (intentional vulnerability)"
  type        = bool
  default     = true
}
