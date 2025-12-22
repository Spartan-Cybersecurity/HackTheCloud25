# Challenge 03 - GCP Private Bucket

## Overview
This challenge focuses on Google Cloud Storage private bucket access. It creates a private bucket called `medicloudx-store-bucket` with a flag stored in the `flag.txt` file.

## Challenge Description
The fictional MediCloudX healthcare provider stores sensitive patient data in a private Google Cloud Storage bucket. Unlike Challenge 01 which featured a public bucket, this bucket is correctly configured as private. However, the challenge is to find a way to access the private content through a vulnerability in the access controls or authentication mechanisms.

## Objective
Participants must:
1. Discover the private bucket called `medicloudx-store-bucket`
2. Find a way to bypass the access controls or exploit a misconfiguration
3. Access the `flag.txt` file to obtain the flag
4. The flag follows the format `CLD[UUID]`

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
terraform init -backend-config=../../backend-configs/challenge-03-gcs.hcl
```

4. Apply the Terraform configuration:
```
terraform apply
```

5. Review the outputs to get the name of the bucket that was created.

### Challenge Information

Participants will need to find a way to access the private bucket and retrieve the flag. The detailed solution steps are available in the `SOLUTION.md` file.

## Clean Up

To remove all resources created by this challenge:

```
terraform destroy
```
