# Challenge 01 - GCP Public Storage Solution

## 🕵️ Challenge Resolution

### Scenario

You encounter a "MediCloudX Store" web application that appears to be an online store for medical devices. Your objective is to find sensitive information that might be exposed due to security misconfigurations.

### Method 1: Manual URL Exploration

1. **Access the main website**
   ```bash
   curl https://storage.googleapis.com/ctf-25-website-{random}/index.html
   ```

2. **Try to access common files**
   ```bash
   # Test typical files that might contain sensitive information
   curl https://storage.googleapis.com/ctf-25-website-{random}/flag.txt
   curl https://storage.googleapis.com/ctf-25-website-{random}/admin.txt
   curl https://storage.googleapis.com/ctf-25-website-{random}/config.txt
   ```

### Method 2: Enumeration with gsutil (if you have access)

1. **List bucket content**
   ```bash
   gsutil ls gs://ctf-25-website-{random}/
   ```

2. **Get detailed information**
   ```bash
   gsutil ls -l gs://ctf-25-website-{random}/
   ```

### Method 3: IAM Permissions Analysis

1. **Check bucket permissions**
   ```bash
   gsutil iam get gs://ctf-25-website-{random}/
   ```

2. **Look for public access configurations**
   ```bash
   gsutil iam ch -d allUsers:objectViewer gs://ctf-25-website-{random}/
   ```

### Method 4: Web Reconnaissance

1. **Inspect the website source code**
   - Look for hidden comments
   - Check references to other files
   - Analyze directory structure

2. **Use reconnaissance tools**
   ```bash
   # With curl and grep to search for patterns
   curl -s https://storage.googleapis.com/ctf-25-website-{random}/index.html | grep -i "flag\|secret\|admin\|config"
   ```

## 🚩 Flag Acquisition

The flag is located in the `flag.txt` file that is publicly accessible due to incorrect permission configuration:

```bash
curl https://storage.googleapis.com/ctf-25-website-{random}/flag.txt
```

**Flag**: `CLD[c9d5e1g4-6h0f-6c3d-be5g-9h4c7f0d8g6e]`

## 🔒 Identified Vulnerabilities

### 1. Excessive Public Permissions
- **Problem**: The bucket has `allUsers:objectViewer` permissions
- **Impact**: Anyone can access all objects in the bucket
- **Risk**: Exposure of sensitive data

### 2. Lack of Granular Access Controls
- **Problem**: No restrictions per individual object
- **Impact**: Sensitive files are exposed alongside public content
- **Risk**: Confidential information leakage

### 3. Insecure Bucket Configuration
- **Problem**: `uniform_bucket_level_access` enabled with public permissions
- **Impact**: Simplifies access but increases attack surface
- **Risk**: Unauthorized access to resources

## 🛡️ Recommended Mitigations

### 1. Implement Principle of Least Privilege
```bash
# Remove public access
gsutil iam ch -d allUsers:objectViewer gs://bucket-name/

# Grant specific access only to authorized users
gsutil iam ch user:user@domain.com:objectViewer gs://bucket-name/
```

### 2. Separate Public and Private Content
```bash
# Create separate buckets
gsutil mb gs://company-public-content/
gsutil mb gs://company-private-content/
```

### 3. Implement Object-Level Access Controls
```bash
# Configure specific ACLs per object
gsutil acl ch -u AllUsers:R gs://bucket/public-file.html
gsutil acl ch -d AllUsers gs://bucket/private-file.txt
```

### 4. Monitoring and Auditing
```bash
# Enable access logging
gsutil logging set on -b gs://logs-bucket/ gs://target-bucket/

# Review configurations periodically
gsutil iam get gs://bucket-name/
```

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
