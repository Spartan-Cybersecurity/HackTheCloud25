# Challenge 03 - GCP Private Bucket Solution

## Solution Walkthrough

### Challenge Overview

This challenge focuses on accessing a private Google Cloud Storage bucket called `medicloudx-store-bucket`. Unlike Challenge 01 which featured a public bucket, this bucket is correctly configured as private, requiring participants to find alternative methods to access the content.

### Step 1: Attempt Direct Access

First, try to access the bucket directly to confirm it's private:

```bash
gsutil ls gs://medicloudx-store-bucket
```

Without proper authentication, this should fail with an access denied error.

### Step 2: Explore Alternative Access Methods

Since the bucket is private, participants need to find alternative ways to access it:

1. **Check for Service Account Keys**: Look for exposed service account keys in the environment
2. **Examine Application Default Credentials**: Check if ADC is configured with sufficient permissions
3. **Look for Credential Files**: Search for JSON key files or other credential artifacts
4. **Check for Metadata Service**: If running on GCP, check the metadata service for attached service accounts

### Step 3: Use Found Credentials

Once credentials are obtained, access the bucket:

```bash
# If using a service account key file
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
gsutil ls gs://medicloudx-store-bucket

# Access the flag
gsutil cat gs://medicloudx-store-bucket/flag.txt
```

### Step 4: Extract the Flag

The flag is stored in `flag.txt` and follows the format `CLD[UUID]`.

## Key Learning Points

1. **Private vs Public Buckets**: Understanding the difference in access controls
2. **Credential Management**: How service account keys and ADC work in GCP
3. **Metadata Service**: How GCP instances can access resources through attached service accounts
4. **Least Privilege**: Importance of minimal permissions for service accounts

## Security Recommendations

1. **Secure Credential Storage**: Never expose service account keys in code or configuration files
2. **Use IAM Conditions**: Implement conditional access based on IP, time, or other factors
3. **Regular Key Rotation**: Rotate service account keys regularly
4. **Monitor Access**: Use Cloud Audit Logs to monitor bucket access
5. **Use Workload Identity**: For GKE workloads, use Workload Identity instead of service account keys
