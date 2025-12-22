# Challenge 02 - GCP Secret Manager

## Overview
This challenge focuses on Google Cloud Secret Manager misconfigurations. It creates a secret called `medicloudx-store-secret` with an exposed flag in the UUID format.

## Challenge Description
The fictional MediCloudX healthcare provider has stored sensitive information in Google Cloud Secret Manager. The secret is misconfigured to allow public access through an IAM policy that grants the `roles/secretmanager.secretAccessor` role to `allUsers`. This represents a common security misconfiguration that can expose sensitive data.

## Objective
Participants must:
1. Discover the misconfigured Secret Manager secret
2. Access the secret's contents to obtain the flag
3. The flag follows the format `CLD[UUID]`

## Deployment Instructions

### Prerequisites
- Google Cloud account with billing enabled
- Terraform 1.5.0 or newer
- Google Cloud SDK installed

### Setup

1. Create a `terraform.tfvars` file based on the example:
```
cp terraform.tfvars.example terraform.tfvars
```

2. Update the `terraform.tfvars` file with your GCP project ID:
```
gcp_project_id = "your-project-id"
```

3. Initialize Terraform with the backend configuration:
```
terraform init -backend-config=../../backend-configs/challenge-02-gcs.hcl
```

4. Apply the Terraform configuration:
```
terraform apply
```

5. Review the outputs to get the name of the secret that was created.

### Challenge Information

Participants will need to discover and access the misconfigured Secret Manager secret to obtain the flag. The detailed solution steps are available in the `SOLUTION.md` file.

## Clean Up

To remove all resources created by this challenge:

```
terraform destroy
```
