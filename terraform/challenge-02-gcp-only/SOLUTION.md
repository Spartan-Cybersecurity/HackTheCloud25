# Challenge 02 - GCP Secret Manager Solution

## Solution Walkthrough

### Step 1: Discover the Secret

The challenge creates a misconfigured Secret Manager secret called `medicloudx-store-secret` with public access through an IAM policy that grants the `roles/secretmanager.secretAccessor` role to `allUsers`.

### Step 2: Access the Secret

Use the Google Cloud CLI to access the secret's contents:

```bash
gcloud secrets versions access 1 --secret="medicloudx-store-secret"
```

You should be able to view the secret value without authentication, which contains the flag.

### Step 3: Extract the Flag

The secret contains the flag in the format `CLD[UUID]`.

## Key Vulnerabilities

1. **Public Secret Access**: The secret is configured with `allUsers` having `secretmanager.secretAccessor` role
2. **Overpermissive IAM Policy**: The IAM binding allows anyone to access the secret
3. **No Authentication Required**: Public access means no GCP credentials are needed

## Security Recommendations

1. **Remove Public Access**: Remove the `allUsers` binding from the secret
2. **Implement Least Privilege**: Only grant access to specific users or service accounts that need it
3. **Use Service Accounts**: For application access, use dedicated service accounts with minimal permissions
4. **Enable Audit Logging**: Monitor secret access through Cloud Audit Logs
5. **Regular Access Reviews**: Periodically review and audit secret access permissions

## Mitigation Commands

```bash
# Remove public access
gcloud secrets remove-iam-policy-binding medicloudx-store-secret \
    --member="allUsers" \
    --role="roles/secretmanager.secretAccessor"

# Grant access to specific user instead
gcloud secrets add-iam-policy-binding medicloudx-store-secret \
    --member="user:admin@company.com" \
    --role="roles/secretmanager.secretAccessor"
```
