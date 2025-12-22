# Provider configuration
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
  
  default_tags {
    tags = {
      Project   = "ctf-25"
      Challenge = "challenge-02-aws-only"
      ManagedBy = "terraform"
    }
  }
}

# Random suffix for unique resource names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}
