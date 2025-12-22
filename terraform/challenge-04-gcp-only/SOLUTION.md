# Challenge 04 - GCP Firestore Database Solution

## Solution Walkthrough

### Challenge Overview

This challenge focuses on Google Cloud Firestore database security and audit log analysis. The goal is to find a hidden flag embedded in one of the audit log entries stored in the `medicloudx-store-audit-logs` collection.

### Step 1: Access the Firestore Database

Navigate to the Firestore console in your Google Cloud project:

```
https://console.cloud.google.com/firestore/data
```

### Step 2: Examine the Collection

1. Look for the `medicloudx-store-audit-logs` collection
2. Browse through the documents in the collection
3. Each document represents a log entry with various fields like timestamp, user, action, etc.

### Step 3: Search for the Flag

Analyze the log entries to find the one containing the hidden flag. The flag may be embedded in:
- Log message fields
- Error descriptions
- System event details
- User activity logs

### Step 4: Alternative Access Methods

If console access is not available, use the gcloud CLI or client libraries:

```bash
# List collections
gcloud firestore collections list

# Query the audit logs collection
gcloud firestore documents list --collection-path=medicloudx-store-audit-logs

# Read specific documents
gcloud firestore documents describe --collection-path=medicloudx-store-audit-logs --document-id=[DOCUMENT_ID]
```

### Step 5: Extract the Flag

Once you find the log entry containing the flag, extract it. The flag follows the format `CLD[UUID]`.

## Key Learning Points

1. **Database Security**: Understanding Firestore access controls and permissions
2. **Log Analysis**: Importance of reviewing audit logs for security incidents
3. **Data Discovery**: Techniques for finding sensitive information in databases
4. **NoSQL Queries**: Working with document-based databases like Firestore

## Security Recommendations

1. **Access Controls**: Implement proper IAM policies for Firestore access
2. **Data Classification**: Classify and protect sensitive data appropriately
3. **Log Monitoring**: Implement automated monitoring for sensitive data in logs
4. **Data Loss Prevention**: Use DLP tools to prevent accidental data exposure
5. **Regular Audits**: Conduct regular audits of database contents and access patterns

## Firestore Security Best Practices

```bash
# Example of secure Firestore rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Only authenticated users can read audit logs
    match /medicloudx-store-audit-logs/{document} {
      allow read: if request.auth != null && request.auth.token.admin == true;
      allow write: if false; // Audit logs should be write-only by system
    }
  }
}
```
