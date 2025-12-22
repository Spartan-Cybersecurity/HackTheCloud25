# IAM User for the reverse engineering challenge
resource "aws_iam_user" "exporter_user" {
  name = "${local.base_name}-service-${local.resource_suffix}"

  tags = {
    Name        = "MediCloudX Exporter Service Account"
    Purpose     = "Medical Data Export Tool"
    Application = "Patient Records Management System"
  }
}

# IAM Access Keys for the user
resource "aws_iam_access_key" "exporter_keys" {
  user = aws_iam_user.exporter_user.name
}

# IAM Policy for S3 access
resource "aws_iam_policy" "exporter_policy" {
  name        = "${local.base_name}-policy-${local.resource_suffix}"
  description = "Policy for MediCloudX Data Exporter access to patient records"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.patient_data.arn,
          "${aws_s3_bucket.patient_data.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach policy to user
resource "aws_iam_user_policy_attachment" "exporter_attach" {
  user       = aws_iam_user.exporter_user.name
  policy_arn = aws_iam_policy.exporter_policy.arn
}
