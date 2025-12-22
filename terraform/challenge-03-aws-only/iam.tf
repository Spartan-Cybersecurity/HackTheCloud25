# IAM resources for the challenge

# IAM role for EC2 instance - data analysis portal
resource "aws_iam_role" "ec2_data_analysis_role" {
  name = "${var.project_name}-ec2-data-analysis-role-${local.random_suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ec2-data-analysis-role-${local.random_suffix}"
  })
}

# IAM policy for EC2 instance - allows reading S3 bucket
resource "aws_iam_policy" "ec2_s3_read_policy" {
  name        = "${var.project_name}-ec2-s3-read-${local.random_suffix}"
  description = "Policy allowing EC2 to read from S3 bucket containing credentials"

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
          aws_s3_bucket.credentials_bucket.arn,
          "${aws_s3_bucket.credentials_bucket.arn}/*"
        ]
      }
    ]
  })

  tags = local.common_tags
}

# Attach policy to EC2 role
resource "aws_iam_role_policy_attachment" "ec2_s3_read_attachment" {
  role       = aws_iam_role.ec2_data_analysis_role.name
  policy_arn = aws_iam_policy.ec2_s3_read_policy.arn
}

# Instance profile for EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile-${local.random_suffix}"
  role = aws_iam_role.ec2_data_analysis_role.name

  tags = local.common_tags
}

# IAM user daniel.lopez (credentials will be stored in S3)
resource "aws_iam_user" "daniel_lopez" {
  name = "daniel.lopez"
  path = "/"

  tags = merge(local.common_tags, {
    Name = "daniel.lopez"
    Role = "MediCloudX-DataAnalyst"
  })
}

# Access keys for daniel.lopez
resource "aws_iam_access_key" "daniel_lopez_key" {
  user = aws_iam_user.daniel_lopez.name
}

# IAM policy for daniel.lopez - limited S3 access with flag
resource "aws_iam_policy" "daniel_lopez_policy" {
  name        = "${var.project_name}-daniel-lopez-policy-${local.random_suffix}"
  description = "Policy for daniel.lopez with access to flag bucket"

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
          aws_s3_bucket.flag_bucket.arn,
          "${aws_s3_bucket.flag_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

# Attach policy to daniel.lopez
resource "aws_iam_user_policy_attachment" "daniel_lopez_attachment" {
  user       = aws_iam_user.daniel_lopez.name
  policy_arn = aws_iam_policy.daniel_lopez_policy.arn
}
