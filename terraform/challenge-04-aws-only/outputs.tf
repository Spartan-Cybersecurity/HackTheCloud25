# Outputs for CTF Challenge 04 - CloudCopy Attack

output "challenge_info" {
  description = "Challenge information and instructions"
  value = {
    challenge_name        = var.challenge_name
    challenge_description = "CloudCopy - Stealing NTDS hashes via EBS snapshots"
    domain_name          = var.domain_name
    attack_technique     = "EBS Snapshot NTDS Extraction"
  }
}

output "domain_controller_info" {
  description = "Domain Controller instance information"
  value = {
    instance_id   = aws_instance.domain_controller.id
    instance_name = aws_instance.domain_controller.tags.Name
    public_ip     = aws_instance.domain_controller.public_ip
    private_ip    = aws_instance.domain_controller.private_ip
    domain_name   = var.domain_name
  }
}

output "snapshot_info" {
  description = "EBS Snapshot information for the attack"
  value = {
    snapshot_id          = aws_ebs_snapshot.dc_snapshot.id
    snapshot_description = aws_ebs_snapshot.dc_snapshot.description
    volume_id           = data.aws_ebs_volume.dc_root_volume.id
    volume_size         = data.aws_ebs_volume.dc_root_volume.size
  }
}

output "iam_user_credentials" {
  description = "IAM user credentials for CTF participants"
  value = {
    username          = aws_iam_user.carlos_cardenas.name
    access_key_id     = aws_iam_access_key.carlos_access_key.id
    secret_access_key = aws_iam_access_key.carlos_access_key.secret
  }
  sensitive = true
}

output "attack_flow_summary" {
  description = "Summary of the attack flow for participants"
  value = {
    step_1 = "Use carlos.cardenas credentials to list EBS snapshots"
    step_2 = "Find the EkoCloudSecDC snapshot using ec2:DescribeSnapshots"
    step_3 = "Snapshot is already PUBLIC - accessible from any AWS account"
    step_4 = "In your personal account, copy the public snapshot directly"
    step_5 = "Create a volume from the copied snapshot in the same AZ as your attack instance"
    step_6 = "Launch an attack instance and attach the volume"
    step_7 = "Mount the volume and extract C:\\Windows\\NTDS\\ntds.dit and C:\\Windows\\System32\\config\\SYSTEM"
    step_8 = "Use secretsdump.py to extract hashes: secretsdump.py -system ./SYSTEM -ntds ./ntds.dit local"
    step_9 = "Find the NT hash for svc-flag user - this is your flag"
  }
}

output "target_credentials" {
  description = "Information about target credentials (for challenge validation)"
  value = {
    target_user     = "svc-flag"
    domain         = var.domain_name
    password_hint  = "Weak password following common patterns"
  }
  sensitive = true
}

output "networking_info" {
  description = "Network configuration information"
  value = {
    vpc_id              = aws_vpc.main.id
    public_subnet_id    = aws_subnet.public.id
    security_group_id   = aws_security_group.dc.id
    availability_zone   = aws_subnet.public.availability_zone
  }
}

# Framework standardized outputs
output "aws_flag" {
  description = "AWS Challenge Flag"
  value       = "CLD[4d8f7e3a-9c2b-4e1a-8f3d-7b5e9a2c4f6e]"
}

output "challenge_summary" {
  description = "Challenge summary and metadata"
  value = {
    name         = "challenge-04-aws-only"
    provider     = "aws"
    difficulty   = "advanced"
    description  = "CloudCopy Attack - Exploit EBS snapshot permissions to extract NTDS hashes from Windows Domain Controller"
    learning_objectives = [
      "AWS EBS snapshot exploitation",
      "Active Directory NTDS database analysis", 
      "IAM permission abuse and misconfiguration",
      "Cross-account resource sharing attacks",
      "Windows credential extraction techniques",
      "CloudCopy attack methodology"
    ]
    estimated_time = "2-3 hours"
    attack_technique = "T1003.003 - OS Credential Dumping: NTDS"
    flag = "CLD[4d8f7e3a-9c2b-4e1a-8f3d-7b5e9a2c4f6e]"
  }
}

output "attack_vectors" {
  description = "Available attack vectors and entry points"
  value = {
    primary_vector = {
      name = "EBS Snapshot Privilege Escalation"
      description = "Exploit misconfigured IAM permissions to access and share Domain Controller EBS snapshots"
      entry_point = "carlos.cardenas IAM user with ec2:DescribeSnapshots and ec2:ModifySnapshotAttribute"
      target = "Windows Domain Controller EBS snapshot containing NTDS database"
      objective = "Share snapshot with personal AWS account for offline analysis"
      difficulty = "advanced"
    }
    secondary_vector = {
      name = "Cross-Account Snapshot Copy"
      description = "Copy shared snapshot to personal account and create volume for analysis"
      entry_point = "Personal AWS account with shared snapshot access"
      target = "EBS volume created from Domain Controller snapshot"
      objective = "Mount volume and extract NTDS.dit and SYSTEM registry hive"
      difficulty = "intermediate"
    }
    final_objective = {
      name = "NTDS Hash Extraction"
      description = "Extract NT hashes from NTDS database using secretsdump.py"
      entry_point = "Mounted Windows volume with NTDS.dit and SYSTEM files"
      target = "svc-flag service account NT hash"
      objective = "Extract and submit NT hash as flag: CLD[4d8f7e3a-9c2b-4e1a-8f3d-7b5e9a2c4f6e]"
      difficulty = "intermediate"
    }
  }
}

