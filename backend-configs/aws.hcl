bucket         = "ctf-25-terraform-state"
key            = "challenges/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "ctf-25-terraform-locks"
use_lockfile   = true
profile        = "ekocloudsec"
