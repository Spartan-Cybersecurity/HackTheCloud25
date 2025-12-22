# Challenge 01 - GCP Only: Public Storage Misconfiguration

## 🎯 Challenge Objective

This challenge simulates a common misconfiguration in Google Cloud Platform where a Cloud Storage bucket is configured with public permissions, exposing sensitive files that should be private.

## 🏗️ Challenge Architecture

```
┌─────────────────────────────────────────┐
│           Google Cloud Platform         │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐    │
│  │      Cloud Storage Bucket       │    │
│  │   ctf-25-website-{random}       │    │
│  │                                 │    │
│  │  📄 index.html (public)         │    │
│  │  🚩 flag.txt (public)           │    │
│  │                                 │    │
│  │  IAM: allUsers → objectViewer   │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

## 🚀 Challenge Deployment

### Prerequisites

1. **Google Cloud CLI installed and configured**
   ```bash
   gcloud --version
   gcloud auth list
   ```

2. **Terraform installed**
   ```bash
   terraform --version
   ```

3. **Authentication configured**
   ```bash
   gcloud auth application-default login
   ```

### Deployment Steps

1. **Create bucket for Terraform state**
   ```bash
   gsutil mb gs://ctf-25-terraform-state-gcp
   ```

2. **Initialize Terraform**
   ```bash
   terraform init -backend-config=../../backend-configs/challenge-01-gcs.hcl
   ```

3. **Create variables file (optional)**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit if necessary
   ```

4. **Plan the deployment**
   ```bash
   terraform plan
   ```

5. **Apply the configuration**
   ```bash
   terraform apply
   ```

## 🔍 Deployed Challenge Information

After successful deployment, you will get the following URLs:

- **Website**: `https://storage.googleapis.com/{bucket-name}/index.html`
- **Flag**: `https://storage.googleapis.com/{bucket-name}/flag.txt`
- **Bucket**: `{bucket-name}`

## 🕵️ Information for Participants

You encounter a "MediCloudX Store" web application that appears to be an online store for medical devices. Your objective is to find sensitive information that might be exposed due to security misconfigurations.

The detailed solution can be found in the `SOLUTION.md` file in this directory.

## 🧪 Verification Commands

```bash
# Verify deployment
terraform output

# Test access to flag
curl $(terraform output -raw gcp_flag_url)

# Check bucket permissions
gsutil iam get gs://$(terraform output -raw gcp_bucket_name)

# List bucket objects
gsutil ls gs://$(terraform output -raw gcp_bucket_name)/
```

## 🧹 Cleanup

To destroy the created resources:

```bash
terraform destroy
```

To remove the state bucket (optional):
```bash
gsutil rm -r gs://ctf-25-terraform-state-gcp/
```

## 📚 References

- [Google Cloud Storage Security Best Practices](https://cloud.google.com/storage/docs/best-practices)
- [IAM for Cloud Storage](https://cloud.google.com/storage/docs/access-control/iam)
- [Cloud Storage Access Control](https://cloud.google.com/storage/docs/access-control)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

## 🏷️ Tags

`#CTF` `#GCP` `#CloudStorage` `#IAM` `#SecurityMisconfiguration` `#PublicBucket` `#Challenge01`
