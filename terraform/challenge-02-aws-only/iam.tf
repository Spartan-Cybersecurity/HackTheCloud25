# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role-${random_string.suffix.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy-${random_string.suffix.result}"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:AdminUpdateUserAttributes"
        ]
        Resource = aws_cognito_user_pool.main.arn
      }
    ]
  })
}

# IAM role for authenticated users (reader role)
resource "aws_iam_role" "authenticated_reader" {
  name = "${var.project_name}-cognito-authenticated-reader-${random_string.suffix.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.main.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })
}

# IAM role for authenticated users (admin role)
resource "aws_iam_role" "authenticated_admin" {
  name = "${var.project_name}-cognito-authenticated-admin-${random_string.suffix.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.main.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })
}

# Policy for reader role (limited permissions)
resource "aws_iam_role_policy" "reader_policy" {
  name = "${var.project_name}-reader-policy-${random_string.suffix.result}"
  role = aws_iam_role.authenticated_reader.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Resource = [
          aws_s3_bucket.web_bucket.arn,
          "${aws_s3_bucket.web_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Policy for admin role (access to flag bucket)
resource "aws_iam_role_policy" "admin_policy" {
  name = "${var.project_name}-admin-policy-${random_string.suffix.result}"
  role = aws_iam_role.authenticated_admin.id

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
      }
    ]
  })
}

# IAM role for JWT Authorizer Lambda
resource "aws_iam_role" "jwt_authorizer_role" {
  name = "${var.project_name}-jwt-authorizer-role-${random_string.suffix.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-jwt-authorizer-role"
  })
}

# IAM policy for JWT Authorizer Lambda
resource "aws_iam_role_policy" "jwt_authorizer_policy" {
  name = "${var.project_name}-jwt-authorizer-policy"
  role = aws_iam_role.jwt_authorizer_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# IAM role for ReadDataPatience Lambda
resource "aws_iam_role" "read_data_patience_role" {
  name = "${var.project_name}-read-data-patience-role-${random_string.suffix.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-read-data-patience-role"
  })
}

# IAM policy for ReadDataPatience Lambda
resource "aws_iam_role_policy" "read_data_patience_policy" {
  name = "${var.project_name}-read-data-patience-policy"
  role = aws_iam_role.read_data_patience_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:GetItem"
        ]
        Resource = [
          aws_dynamodb_table.data_patience.arn,
          "${aws_dynamodb_table.data_patience.arn}/index/*"
        ]
      }
    ]
  })
}
