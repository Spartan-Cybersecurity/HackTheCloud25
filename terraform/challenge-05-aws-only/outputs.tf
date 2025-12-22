output "challenge_info" {
  description = "Challenge information and access details"
  value = {
    challenge_name   = "Challenge 05 - MediCloudX Reverse Engineering"
    bucket_name     = aws_s3_bucket.patient_data.bucket
    bucket_suffix   = local.resource_suffix
    iam_user        = aws_iam_user.exporter_user.name
    flag_location   = "admin/system_backup/flag.txt"
  }
}

output "binary_build_info" {
  description = "Information for building the challenge binary"
  value = {
    source_file     = "medicloudx_exporter.c"
    makefile        = "Makefile"
    binary_name     = "medicloudx_exporter_linux_x86"
    build_command   = "Automated via Terraform"
    build_status    = "Automatically compiled and uploaded to S3"
    platform        = "Linux x86_64 via Docker"
  }
}

output "embedded_credentials" {
  description = "AWS credentials embedded in the binary"
  value = {
    access_key = aws_iam_access_key.exporter_keys.id
    secret_key = aws_iam_access_key.exporter_keys.secret
  }
  sensitive = true
}

output "s3_details" {
  description = "S3 bucket information for the challenge"
  value = {
    bucket_arn      = aws_s3_bucket.patient_data.arn
    bucket_region   = aws_s3_bucket.patient_data.region
    objects = {
      flag_file           = "admin/system_backup/flag.txt"
      patient_manifest    = "exports/patient_manifest.json"
      cardiovascular_data = "exports/cardiovascular_patients.json"
      lab_results        = "exports/lab_results.json"
      compiled_binary     = "tools/medicloudx_exporter_linux_x86"
    }
  }
}

output "binary_download" {
  description = "Information for downloading the compiled binary"
  value = {
    s3_location = "s3://${aws_s3_bucket.patient_data.bucket}/tools/medicloudx_exporter_linux_x86"
    download_script = "download_binary.sh"
    aws_cli_command = "aws s3 cp s3://${aws_s3_bucket.patient_data.bucket}/tools/medicloudx_exporter_linux_x86 . --profile ${var.aws_profile} --region ${var.aws_region}"
    platform = "Linux x86_64"
    purpose = "Reverse engineering target with embedded AWS credentials"
  }
  depends_on = [aws_s3_object.compiled_binary]
}

output "challenge_instructions" {
  description = "Challenge completion instructions"
  value = <<-EOT
    
    =============================================================
    Challenge 05 - MediCloudX Data Exporter (Reverse Engineering)
    =============================================================
    
    Bucket Name: ${aws_s3_bucket.patient_data.bucket}
    Bucket Suffix: ${local.resource_suffix}
    
    Binary Information:
    - Source: medicloudx_exporter.c
    - Build: make
    - Target: medicloudx_exporter
    
    Usage:
    ./medicloudx_exporter --bucket ${local.resource_suffix}
    
    Flag Location: admin/system_backup/flag.txt
    
    =============================================================
  EOT
}

# Export bucket suffix to file for easy access
resource "local_file" "bucket_suffix" {
  content  = local.resource_suffix
  filename = "${path.module}/bucket_suffix.txt"
}

# Export the complete binary usage example
resource "local_file" "usage_example" {
  content = <<-EOT
#!/bin/bash
# MediCloudX Data Exporter - Usage Example
# 
# Build the binary:
make

# Run the exporter:
./medicloudx_exporter --bucket ${local.resource_suffix}

# Show version:
./medicloudx_exporter --version

# The binary contains embedded AWS credentials that can be extracted through:
# - Static analysis (strings, objdump, ghidra)
# - Dynamic analysis (gdb, strace)
# - Reverse engineering tools
EOT
  filename = "${path.module}/run_example.sh"
  file_permission = "0755"
}

# Framework standardized outputs
output "aws_flag" {
  description = "AWS Challenge Flag"
  value       = "CLD[6b2e7f8a-5d3c-4a1e-9b8f-2c6d8e4a7f9b]"
}

output "challenge_summary" {
  description = "Challenge summary and metadata"
  value = {
    name         = "challenge-05-aws-only"
    provider     = "aws"
    difficulty   = "advanced"
    description  = "MediCloudX Data Exporter - Binary reverse engineering to extract embedded AWS credentials"
    learning_objectives = [
      "Binary reverse engineering techniques",
      "Static analysis with strings and objdump", 
      "Dynamic analysis with gdb and strace",
      "AWS credential extraction from compiled binaries",
      "Healthcare IT security assessment",
      "Cross-platform binary compilation with Docker"
    ]
    estimated_time = "1-2 hours"
    attack_technique = "T1552.001 - Unsecured Credentials: Credentials In Files"
    flag = "CLD[6b2e7f8a-5d3c-4a1e-9b8f-2c6d8e4a7f9b]"
  }
}

output "attack_vectors" {
  description = "Available attack vectors and entry points"
  value = {
    primary_vector = {
      name = "Static Binary Analysis"
      description = "Extract hardcoded AWS Access Key ID using strings command and binary analysis tools"
      entry_point = "medicloudx_exporter compiled binary"
      target = "AWS Access Key ID embedded as string literal in binary"
      objective = "Identify AWS Access Key format (AKIA...) using: strings medicloudx_exporter | grep AKIA"
      difficulty = "intermediate"
    }
    secondary_vector = {
      name = "Dynamic Memory Analysis"
      description = "Extract AWS Secret Access Key through runtime debugging and HMAC function interception"
      entry_point = "Running binary under GDB debugger"
      target = "AWS Secret Access Key reconstructed from multiple string parts during HMAC operations"
      objective = "Set breakpoint on HMAC function and capture secret key parameter"
      difficulty = "advanced"
    }
    final_objective = {
      name = "AWS S3 Data Access"
      description = "Use extracted credentials to access S3 bucket containing medical records and flag"
      entry_point = "Extracted AWS credentials from binary analysis"
      target = "S3 bucket admin/system_backup/flag.txt containing final flag"
      objective = "Access S3 bucket using discovered credentials and retrieve flag: CLD[6b2e7f8a-5d3c-4a1e-9b8f-2c6d8e4a7f9b]"
      difficulty = "intermediate"
    }
  }
}
