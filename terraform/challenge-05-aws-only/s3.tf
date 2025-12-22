# S3 Bucket for patient data and flag
resource "aws_s3_bucket" "patient_data" {
  bucket = "${local.base_name}-records-${local.resource_suffix}"

  tags = {
    Name        = "MediCloudX Patient Records"
    Purpose     = "Secure Patient Data Storage"
    Application = "Healthcare Management System"
  }
}

# S3 Bucket Public Access Block (private bucket)
resource "aws_s3_bucket_public_access_block" "patient_data_pab" {
  bucket = aws_s3_bucket.patient_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Server Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "patient_data_encryption" {
  bucket = aws_s3_bucket.patient_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "patient_data_versioning" {
  bucket = aws_s3_bucket.patient_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Upload flag file
resource "aws_s3_object" "flag" {
  bucket       = aws_s3_bucket.patient_data.bucket
  key          = "admin/system_backup/flag.txt"
  content      = var.flag_content
  content_type = "text/plain"

  tags = {
    Name        = "System Flag"
    Purpose     = "CTF Challenge"
    Sensitivity = "High"
  }
}

# Upload sample patient record files
resource "aws_s3_object" "patient_manifest" {
  bucket       = aws_s3_bucket.patient_data.bucket
  key          = "exports/patient_manifest.json"
  content_type = "application/json"
  
  content = jsonencode({
    export_info = {
      system       = "MediCloudX Patient Management v2.1"
      export_date  = "2024-10-05"
      total_records = var.patient_records_count
      format       = "JSON"
      compliance   = "HIPAA Compliant"
    }
    records_available = [
      "cardiovascular_patients.json",
      "diabetes_monitoring.json", 
      "surgical_procedures.json",
      "lab_results.json"
    ]
    access_level = "Healthcare Provider Access Required"
    contact = "admin@medicloudx.com"
  })

  tags = {
    Name = "Patient Export Manifest"
    Type = "Medical Records"
  }
}

# Upload sample medical data files
resource "aws_s3_object" "cardiovascular_data" {
  bucket       = aws_s3_bucket.patient_data.bucket
  key          = "exports/cardiovascular_patients.json"
  content_type = "application/json"
  
  content = jsonencode({
    records = [
      {
        patient_id = "CVD-001"
        condition  = "Hypertension"
        last_visit = "2024-09-15"
        status     = "Stable"
      },
      {
        patient_id = "CVD-002" 
        condition  = "Arrhythmia"
        last_visit = "2024-09-20"
        status     = "Monitoring Required"
      }
    ]
  })

  tags = {
    Name = "Cardiovascular Patient Data"
    Type = "Medical Records"
  }
}

resource "aws_s3_object" "lab_results" {
  bucket       = aws_s3_bucket.patient_data.bucket
  key          = "exports/lab_results.json"
  content_type = "application/json"
  
  content = jsonencode({
    lab_data = [
      {
        test_id    = "LAB-2024-001"
        patient_id = "PT-4521"
        test_type  = "Blood Chemistry Panel"
        result     = "Normal ranges"
        date       = "2024-09-25"
      },
      {
        test_id    = "LAB-2024-002"
        patient_id = "PT-4522"
        test_type  = "Lipid Panel" 
        result     = "Elevated cholesterol"
        date       = "2024-09-26"
      }
    ]
  })

  tags = {
    Name = "Laboratory Results"
    Type = "Medical Records"
  }
}
