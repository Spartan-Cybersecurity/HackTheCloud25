# Challenge 02 - AWS Cognito Privilege Escalation
# Main configuration file - contains only basic setup
# Resources are organized in separate files for better maintainability

# Local values for common configurations
locals {
  common_tags = {
    Project   = var.project_name
    Challenge = "challenge-02-aws-only"
    ManagedBy = "terraform"
  }
}
