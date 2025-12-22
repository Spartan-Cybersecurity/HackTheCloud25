# Challenge 03 - AWS EC2 SSRF to S3 Access

## Overview

This challenge simulates a real-world scenario where a healthcare organization (MediCloudX Health) has deployed a web application with a Server-Side Request Forgery (SSRF) vulnerability. Participants must exploit this vulnerability to gain access to AWS credentials and ultimately retrieve sensitive data from S3 buckets.

## Challenge Description

**Scenario**: You've discovered the internal data analytics portal for MediCloudX Health, a telemedicine platform. The portal includes a connectivity checker tool that appears to be vulnerable to SSRF attacks. Your goal is to exploit this vulnerability to gain access to sensitive patient data.

**Difficulty**: Intermediate  
**Estimated Time**: 30-45 minutes  
**Skills Required**: SSRF exploitation, AWS metadata service, S3 access

## Architecture

The challenge deploys the following AWS resources:

- **EC2 Instance**: Runs a vulnerable PHP web application with SSRF vulnerability
- **IAM Roles**: EC2 instance role with S3 read permissions
- **IAM User**: `daniel.lopez` with access to the flag bucket
- **S3 Buckets**:
  - Credentials bucket: Contains daniel.lopez AWS credentials in CSV format
  - Flag bucket: Contains the final flag and decoy patient data
- **VPC**: Isolated network environment with public subnet

## Attack Flow

1. **Reconnaissance**: Access the MediCloudX Health data analytics portal
2. **Vulnerability Discovery**: Identify the SSRF vulnerability in the connectivity checker
3. **Bucket Discovery**: Use SSRF to access EC2 user-data or configuration files to discover bucket names
4. **Metadata Exploitation**: Use SSRF to access EC2 metadata service (`http://169.254.169.254/`)
5. **Credential Extraction**: Retrieve temporary AWS credentials from metadata service
6. **S3 Access**: Use EC2 credentials to access the credentials bucket
7. **Credential Escalation**: Download daniel.lopez credentials from CSV file
8. **Flag Retrieval**: Use daniel.lopez credentials to access the flag bucket and retrieve the flag

## Deployment

### Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate permissions
- AWS account with permissions to create EC2, IAM, S3, and VPC resources

### Deploy the Challenge

1. **Clone the repository and navigate to the challenge directory**:
   ```bash
   cd terraform/challenges/challenge-03-aws-only
   ```

2. **Copy and customize the variables file**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars as needed
   ```

3. **Initialize and deploy**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Note the outputs**:
   ```bash
   terraform output
   ```

## Challenge Information

After deployment, participants will receive:
- **Web Application URL**: The public IP/URL of the MediCloudX Health portal
- **Challenge Instructions**: Basic scenario description

The detailed solution walkthrough is available in the `SOLUTION.md` file.

## Flag Format

The flag follows the standard CTF format.

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

## Cleanup

To destroy the challenge resources:

```bash
terraform destroy
```

## Security Notes

- This challenge creates intentionally vulnerable infrastructure
- Only deploy in isolated/testing environments
- Ensure proper cleanup after use
- Monitor AWS costs during deployment

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

## References

- [CloudGoat EC2 SSRF Scenario](https://github.com/RhinoSecurityLabs/cloudgoat/tree/master/cloudgoat/scenarios/aws/ec2_ssrf)
- [AWS Instance Metadata Service](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html)
- [OWASP SSRF Prevention](https://cheatsheetseries.owasp.org/cheatsheets/Server_Side_Request_Forgery_Prevention_Cheat_Sheet.html)
