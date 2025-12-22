# S3 resources for the challenge

# S3 bucket for storing daniel.lopez credentials (accessible via EC2 role)
resource "aws_s3_bucket" "credentials_bucket" {
  bucket = "${var.project_name}-medicloudx-credentials-${local.random_suffix}"

  tags = merge(local.common_tags, {
    Name        = "${var.project_name}-medicloudx-credentials-${local.random_suffix}"
    Purpose     = "Store employee credentials"
    Environment = "production"
  })
}

# Block public access for credentials bucket
resource "aws_s3_bucket_public_access_block" "credentials_bucket_pab" {
  bucket = aws_s3_bucket.credentials_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket for storing the final flag (accessible via daniel.lopez credentials)
resource "aws_s3_bucket" "flag_bucket" {
  bucket = "${var.project_name}-medicloudx-patient-data-${local.random_suffix}"

  tags = merge(local.common_tags, {
    Name        = "${var.project_name}-medicloudx-patient-data-${local.random_suffix}"
    Purpose     = "Store sensitive patient data and analytics"
    Environment = "production"
    Compliance  = "HIPAA"
  })
}

# Block public access for flag bucket
resource "aws_s3_bucket_public_access_block" "flag_bucket_pab" {
  bucket = aws_s3_bucket.flag_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Upload daniel.lopez credentials CSV to credentials bucket
resource "aws_s3_object" "daniel_lopez_credentials" {
  bucket = aws_s3_bucket.credentials_bucket.id
  key    = "employees/daniel.lopez/aws-credentials.csv"
  content = "User Name,Access Key Id,Secret Access Key\ndaniel.lopez,${aws_iam_access_key.daniel_lopez_key.id},${aws_iam_access_key.daniel_lopez_key.secret}"
  
  content_type = "text/csv"

  tags = merge(local.common_tags, {
    Name        = "daniel.lopez-credentials"
    Employee    = "daniel.lopez"
    Department  = "Data Analytics"
    Sensitivity = "High"
  })
}

# Upload flag to flag bucket
resource "aws_s3_object" "flag" {
  bucket = aws_s3_bucket.flag_bucket.id
  key    = "analytics/patient-insights/flag.txt"
  content = "CLD[2f8e9d4a-7c1b-4e3a-9f2d-8b6c5e4d3a2f]"
  
  content_type = "text/plain"

  tags = merge(local.common_tags, {
    Name        = "patient-analytics-flag"
    Department  = "Data Analytics"
    Sensitivity = "Critical"
  })
}

# Upload additional decoy files to make the challenge more realistic
resource "aws_s3_object" "patient_data_sample" {
  bucket = aws_s3_bucket.flag_bucket.id
  key    = "analytics/patient-insights/sample-data.csv"
  content = "patient_id,age,diagnosis,treatment_outcome\nP001,45,Diabetes Type 2,Improved\nP002,32,Hypertension,Stable\nP003,67,Heart Disease,Recovered\nP004,28,Anxiety,Improved\nP005,54,Arthritis,Stable"
  
  content_type = "text/csv"

  tags = merge(local.common_tags, {
    Name        = "sample-patient-data"
    Department  = "Data Analytics"
    Sensitivity = "High"
  })
}

resource "aws_s3_object" "analytics_report" {
  bucket = aws_s3_bucket.flag_bucket.id
  key    = "analytics/reports/monthly-health-trends.json"
  content = jsonencode({
    report_date = "2025-01-01"
    total_patients = 50000
    top_diagnoses = [
      { condition = "Diabetes", percentage = 23.5 },
      { condition = "Hypertension", percentage = 18.7 },
      { condition = "Anxiety", percentage = 15.2 }
    ]
    treatment_success_rate = 87.3
    telemedicine_adoption = 92.1
  })
  
  content_type = "application/json"

  tags = merge(local.common_tags, {
    Name        = "monthly-health-trends"
    Department  = "Data Analytics"
    Sensitivity = "Medium"
  })
}
