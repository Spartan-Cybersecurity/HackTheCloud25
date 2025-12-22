# Challenge 04 - GCP Firestore Database

## Overview
This challenge focuses on Google Cloud Firestore database security and audit log analysis. It creates a database with a collection named `medicloudx-store-audit-logs` containing application logs, one of which has an embedded flag.

## Challenge Description
The fictional MediCloudX healthcare provider stores system audit logs in a Firestore database. The logs track user activity, system events, and other operations. During a recent backup operation, an administrator accidentally included a secret flag in one of the log entries. Participants need to search through the logs to find the hidden flag.

## Objective
Participants must:
1. Access the Firestore database named `medicloudx-store`
2. Examine the `medicloudx-store-audit-logs` collection
3. Analyze the log entries to find the one containing the hidden flag
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
terraform init -backend-config=../../backend-configs/challenge-04-gcs.hcl
```

4. Apply the Terraform configuration:
```
terraform apply
```

5. Review the outputs to get the name of the Firestore database and collection that were created.

### Challenge Information

Participants will need to access the Firestore database and analyze the audit logs to find the hidden flag. The detailed solution steps are available in the `SOLUTION.md` file.

## Clean Up

To remove all resources created by this challenge:

```
terraform destroy
```
