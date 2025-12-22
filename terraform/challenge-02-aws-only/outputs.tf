output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  value       = aws_cognito_user_pool_client.main.id
}

output "identity_pool_id" {
  description = "Cognito Identity Pool ID"
  value       = aws_cognito_identity_pool.main.id
}

output "web_application_url" {
  description = "Web application URL"
  value       = "http://${aws_s3_bucket_website_configuration.web_bucket.website_endpoint}"
}

output "web_bucket_website_url" {
  description = "S3 website URL for the web application"
  value       = "http://${aws_s3_bucket_website_configuration.web_bucket.website_endpoint}"
}

output "flag_bucket_name" {
  description = "S3 bucket containing the flag"
  value       = aws_s3_bucket.flag_bucket.id
}

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "api_gateway_url" {
  description = "API Gateway URL for patient records API"
  value       = "https://${aws_api_gateway_rest_api.patient_api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.patient_api_stage.stage_name}"
}

output "patient_api_endpoint" {
  description = "Patient API endpoint"
  value       = "https://${aws_api_gateway_rest_api.patient_api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.patient_api_stage.stage_name}/patients"
}

output "dynamodb_table_name" {
  description = "DynamoDB table name for patient data"
  value       = aws_dynamodb_table.data_patience.name
}

output "challenge_instructions" {
  description = "Instructions for the challenge"
  value = <<EOF
Challenge 02 - AWS Cognito Privilege Escalation with API Gateway

1. Navigate to the web application: http://${aws_s3_bucket_website_configuration.web_bucket.website_endpoint}
2. Discover the Cognito User Pool Client ID in the source code
3. Register a new user directly via AWS CLI bypassing frontend validation
4. Login and extract the ID token from browser storage
5. Update your custom:role attribute from 'reader' to 'admin'
6. Use the "Access Patient Records" button to call the API with admin privileges
7. Find the flag hidden in the patient records data

Alternative Advanced Path:
- Obtain Identity Pool credentials using your ID token for S3 access
- Access flag in S3 bucket: ${aws_s3_bucket.flag_bucket.id}
- Or query DynamoDB table directly: ${aws_dynamodb_table.data_patience.name}

API Endpoint: ${aws_api_gateway_rest_api.patient_api.id}.execute-api.${var.aws_region}.amazonaws.com/prod/patients
User Pool ID: ${aws_cognito_user_pool.main.id}
Client ID: ${aws_cognito_user_pool_client.main.id}
Identity Pool ID: ${aws_cognito_identity_pool.main.id}
DynamoDB Table: ${aws_dynamodb_table.data_patience.name}
EOF
}

# Standardized Framework Outputs
output "aws_flag" {
  description = "AWS Challenge 02 Flag"
  value       = "CLD[f2a8d5b7-9c3e-4f1a-8b6d-2e9c7f4a1b5e]"
}

output "challenge_summary" {
  description = "Challenge 02 AWS - Summary"
  value = {
    website      = "http://${aws_s3_bucket_website_configuration.web_bucket.website_endpoint}"
    api_endpoint = "https://${aws_api_gateway_rest_api.patient_api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.patient_api_stage.stage_name}/patients"
    flag_url     = "https://s3.${var.aws_region}.amazonaws.com/${aws_s3_bucket.flag_bucket.id}/flag.txt"
    flag         = "CLD[f2a8d5b7-9c3e-4f1a-8b6d-2e9c7f4a1b5e]"
    user_pool_id = aws_cognito_user_pool.main.id
    client_id    = aws_cognito_user_pool_client.main.id
    dynamodb_table = aws_dynamodb_table.data_patience.name
  }
}

output "attack_vectors" {
  description = "AWS Challenge 02 Attack Vectors"
  value = {
    vector_1 = {
      name = "Cognito User Registration Bypass"
      target = "http://${aws_s3_bucket_website_configuration.web_bucket.website_endpoint}"
      difficulty = "Advanced"
      flag = "CLD[f2a8d5b7-9c3e-4f1a-8b6d-2e9c7f4a1b5e]"
    }
    vector_2 = {
      name = "Privilege Escalation via Custom Attributes"
      target = "https://${aws_api_gateway_rest_api.patient_api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.patient_api_stage.stage_name}/patients"
      difficulty = "Advanced"
      flag = "CLD[f2a8d5b7-9c3e-4f1a-8b6d-2e9c7f4a1b5e]"
    }
    vector_3 = {
      name = "Direct S3 Bucket Access via Identity Pool"
      target = "https://s3.${var.aws_region}.amazonaws.com/${aws_s3_bucket.flag_bucket.id}/flag.txt"
      difficulty = "Expert"
      flag = "CLD[f2a8d5b7-9c3e-4f1a-8b6d-2e9c7f4a1b5e]"
    }
  }
}
