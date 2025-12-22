# Challenge 01: AWS-Only Public Storage

This challenge implements a public S3 bucket with vulnerable security configurations for CTF educational purposes.

## Challenge Description

**Objective**: Find and access a flag stored in a publicly accessible S3 bucket.

**Deployed resources**:
- S3 bucket with public read access
- Static website hosting enabled
- Flag stored in `flag.txt`

**Demonstrated vulnerability**:
- Bucket policy that allows public read access
- No access restrictions
- Static web hosting enabled

## Prerequisites

### 1. Required Tools
- Terraform >= 1.5.0
- AWS CLI v2
- Configured AWS profile

### 2. AWS Configuration

#### Option A: AWS CLI (Recommended)
```bash
# Configure AWS CLI
aws configure --profile ekocloudsec

# Verify authentication
aws sts get-caller-identity --profile ekocloudsec
```

#### Option B: Environment Variables
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
export AWS_PROFILE="ekocloudsec"
```

### 3. Required AWS Permissions
Your AWS user/role needs the following permissions:
- `s3:CreateBucket`
- `s3:DeleteBucket`
- `s3:GetBucketPolicy`
- `s3:PutBucketPolicy`
- `s3:PutBucketWebsite`
- `s3:PutObject`
- `s3:GetObject`
- `s3:DeleteObject`

## Deployment

### 1. Configure Variables
```bash
cd terraform/challenges/challenge-01-aws-only

# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit variables (optional)
# Default variables work with 'ekocloudsec' profile
```

### 2. Configure Terraform Backend
```bash
# Initialize with S3 backend
terraform init -backend-config=../../backend-configs/s3.hcl
```

### 3. Deploy Infrastructure
```bash
# Review deployment plan
terraform plan

# Apply changes
terraform apply
```

### 4. Get Challenge URLs
After deployment, Terraform will show:
```
Outputs:

aws_flag_url = "http://bucket-name.s3-website-us-east-1.amazonaws.com/flag.txt"
aws_s3_bucket_name = "bucket-name"
aws_s3_website_endpoint = "http://bucket-name.s3-website-us-east-1.amazonaws.com"
challenge_summary = {
  "bucket" = "bucket-name"
  "flag" = "http://bucket-name.s3-website-us-east-1.amazonaws.com/flag.txt"
  "website" = "http://bucket-name.s3-website-us-east-1.amazonaws.com"
}
```

## Information for Participants

Once the infrastructure is deployed, participants will receive the necessary URLs to complete the challenge. The detailed solution can be found in the `SOLUTION.md` file in this directory.

## Cleanup

To remove all resources:
```bash
terraform destroy
```

## Troubleshooting

### Common Issues

**Error: "Access Denied"**
- Verify your AWS profile is configured correctly
- Confirm you have the necessary S3 permissions
- Check the configured region

**Error: "Backend initialization failed"**
- Ensure the S3 bucket for the backend exists
- Verify you have access to the backend bucket
- Confirm the DynamoDB table for locks exists

**Error: "Bucket name conflicts"**
- S3 bucket names are globally unique
- The module uses random suffixes to avoid conflicts
- If it persists, change the `project_name` in `terraform.tfvars`

### Enumeration Issues

For detailed troubleshooting of enumeration issues, check the `SOLUTION.md` file.

### Detailed Logs
```bash
# Enable detailed logging
export TF_LOG=DEBUG
terraform apply
```

## Advanced Configuration

### Customizable Variables

| Variable | Description | Default Value |
|----------|-------------|---------------|
| `aws_region` | AWS Region | `us-east-1` |
| `aws_profile` | AWS CLI Profile | `ekocloudsec` |
| `project_name` | Project Name | `ctf-25` |

### Custom terraform.tfvars Example
```hcl
aws_region   = "us-west-2"
aws_profile  = "my-profile"
project_name = "my-ctf"
```

## Security Notes

⚠️ **WARNING**: This challenge intentionally creates security vulnerabilities for educational purposes. 

- DO NOT deploy in production environments
- DO NOT use with sensitive data
- Remove resources after completing the challenge
- Public buckets may incur costs if they receive massive traffic
