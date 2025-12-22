# Challenge 03 - AWS EC2 SSRF to S3 Access
# Main configuration file - contains only basic setup
# Resources are organized in separate files for better maintainability

# Local values for common configurations
locals {
  common_tags = {
    Project   = var.project_name
    Challenge = "challenge-03-aws-only"
    ManagedBy = "terraform"
  }
  
  # Generate random suffix for unique resource names
  random_suffix = random_string.suffix.result
}

# Random string for unique resource naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}
