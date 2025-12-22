# Cognito User Pool
resource "aws_cognito_user_pool" "main" {
  name = "${var.project_name}-cognito-pool-${random_string.suffix.result}"

  # Allow users to sign up themselves
  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  # User attributes
  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true
  }

  schema {
    name                = "given_name"
    attribute_data_type = "String"
    required            = false
    mutable             = true
  }

  schema {
    name                = "family_name"
    attribute_data_type = "String"
    required            = false
    mutable             = true
  }

  # Custom attribute for role - this is the vulnerability
  schema {
    name                = "role"
    attribute_data_type = "String"
    required            = false
    mutable             = true
    developer_only_attribute = false
  }

  # Password policy
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  # Email verification - ENABLED with SES integration
  auto_verified_attributes = ["email"]
  
  # Username configuration
  username_attributes = ["email"]
  
  # SES email configuration
  email_configuration {
    email_sending_account = "DEVELOPER"
    from_email_address    = "administrator@ekocloudsec.com"
    source_arn           = "arn:aws:ses:${var.aws_region}:${data.aws_caller_identity.current.account_id}:identity/ekocloudsec.com"
  }
  
  # Lambda Triggers
  lambda_config {
    post_confirmation = aws_lambda_function.post_confirmation.arn
  }

  tags = {
    Name = "${var.project_name}-cognito-pool"
  }
}

# Cognito User Pool Client
resource "aws_cognito_user_pool_client" "main" {
  name         = "${var.project_name}-cognito-client-${random_string.suffix.result}"
  user_pool_id = aws_cognito_user_pool.main.id

  # Allow self-registration and user management
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
  ]

  # Token validity
  access_token_validity  = 60
  id_token_validity     = 60
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  # Read and write attributes
  read_attributes = [
    "email",
    "given_name", 
    "family_name",
    "custom:role"
  ]

  write_attributes = [
    "email",
    "given_name",
    "family_name", 
    "custom:role"  # This allows users to modify their role - VULNERABILITY
  ]

  # Prevent user existence errors
  prevent_user_existence_errors = "ENABLED"

  # Token revocation
  enable_token_revocation = true

  # Generate secret
  generate_secret = false
}

# Lambda config se incluye directamente en el recurso aws_cognito_user_pool

# Cognito Identity Pool
resource "aws_cognito_identity_pool" "main" {
  identity_pool_name               = "${var.project_name}-identity-pool-${random_string.suffix.result}"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.main.id
    provider_name           = "cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.main.id}"
    server_side_token_check = false
  }

  tags = {
    Name = "${var.project_name}-identity-pool"
  }
}

# Identity Pool Role Attachment with role mapping for privilege escalation
resource "aws_cognito_identity_pool_roles_attachment" "main" {
  identity_pool_id = aws_cognito_identity_pool.main.id

  roles = {
    "authenticated" = aws_iam_role.authenticated_reader.arn
  }

  role_mapping {
    identity_provider         = "cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.main.id}:${aws_cognito_user_pool_client.main.id}"
    ambiguous_role_resolution = "Deny"
    type                      = "Rules"

    mapping_rule {
      claim      = "custom:role"
      match_type = "Equals"
      value      = "admin"
      role_arn   = aws_iam_role.authenticated_admin.arn
    }

    mapping_rule {
      claim      = "custom:role"
      match_type = "Equals"
      value      = "reader"
      role_arn   = aws_iam_role.authenticated_reader.arn
    }
  }

  depends_on = [
    aws_cognito_identity_pool.main,
    aws_cognito_user_pool.main,
    aws_cognito_user_pool_client.main,
    aws_iam_role.authenticated_reader,
    aws_iam_role.authenticated_admin
  ]
}
