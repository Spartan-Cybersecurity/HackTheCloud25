# S3 bucket for storing the flag
resource "aws_s3_bucket" "flag_bucket" {
  bucket = "${var.project_name}-cognito-flag-${random_string.suffix.result}"
}

resource "aws_s3_bucket_public_access_block" "flag_bucket_pab" {
  bucket = aws_s3_bucket.flag_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_object" "flag" {
  bucket = aws_s3_bucket.flag_bucket.id
  key    = "flag.txt"
  content = "CLD[f2a8d5b7-9c3e-4f1a-8b6d-2e9c7f4a1b5e]"
  content_type = "text/plain"
}

# S3 bucket for web content
resource "aws_s3_bucket" "web_bucket" {
  bucket = "${var.project_name}-cognito-web-${random_string.suffix.result}"
}

resource "aws_s3_bucket_website_configuration" "web_bucket" {
  bucket = aws_s3_bucket.web_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "web_bucket_pab" {
  bucket = aws_s3_bucket.web_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "web_bucket_policy" {
  bucket = aws_s3_bucket.web_bucket.id
  depends_on = [aws_s3_bucket_public_access_block.web_bucket_pab]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.web_bucket.arn}/*"
      }
    ]
  })
}

# Template for index.html with Cognito configuration
locals {
  index_html_content = templatefile("${path.module}/../../web-content/aws-challenge-02/index.html.tftpl", {
    user_pool_id     = aws_cognito_user_pool.main.id
    client_id        = aws_cognito_user_pool_client.main.id
    identity_pool_id = aws_cognito_identity_pool.main.id
    region          = var.aws_region
    api_endpoint     = "https://${aws_api_gateway_rest_api.patient_api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.patient_api_stage.stage_name}/patients"
  })
}

# Upload web content to S3
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.web_bucket.id
  key          = "index.html"
  content      = local.index_html_content
  content_type = "text/html"
  
  depends_on = [
    aws_cognito_user_pool.main,
    aws_cognito_user_pool_client.main,
    aws_cognito_identity_pool.main,
    aws_api_gateway_rest_api.patient_api,
    aws_api_gateway_stage.patient_api_stage
  ]
}
