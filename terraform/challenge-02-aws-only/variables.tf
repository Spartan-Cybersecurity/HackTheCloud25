variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "ekocloudsec"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "ctf-25"
}
