# Output values for the challenge

output "web_application_url" {
  description = "Public URL of the MediCloudX Health web application"
  value       = "http://${aws_eip.web_app_eip.public_ip}"
}

output "web_application_ip" {
  description = "Public IP address of the web application"
  value       = aws_eip.web_app_eip.public_ip
}

output "ec2_instance_id" {
  description = "ID of the EC2 instance running the web application"
  value       = aws_instance.web_app.id
}

output "credentials_bucket_name" {
  description = "Name of the S3 bucket containing daniel.lopez credentials"
  value       = aws_s3_bucket.credentials_bucket.id
}

output "flag_bucket_name" {
  description = "Name of the S3 bucket containing the flag"
  value       = aws_s3_bucket.flag_bucket.id
}

output "daniel_lopez_access_key" {
  description = "Access key for daniel.lopez user (for verification)"
  value       = aws_iam_access_key.daniel_lopez_key.id
  sensitive   = true
}

output "daniel_lopez_secret_key" {
  description = "Secret key for daniel.lopez user (for verification)"
  value       = aws_iam_access_key.daniel_lopez_key.secret
  sensitive   = true
}

output "challenge_instructions" {
  description = "Instructions for participants"
  value = <<-EOT
    Challenge 03 - AWS EC2 SSRF to S3 Access
    
    🎯 Objetivo: Obtener el flag final desde el bucket de datos de pacientes
    
    📋 Información inicial:
    - URL del Portal: http://${aws_eip.web_app_eip.public_ip}
    - Sistema: MediCloudX Health - Portal de Análisis de Datos
    
    🔍 Flujo de ataque esperado:
    1. Explorar el portal web de MediCloudX Health
    2. Identificar la funcionalidad vulnerable a SSRF
    3. Usar SSRF para acceder al servicio de metadatos de EC2
    4. Obtener credenciales temporales de AWS desde el metadata service
    5. Usar las credenciales para acceder al bucket de credenciales
    6. Obtener las credenciales de daniel.lopez desde el archivo CSV
    7. Usar las credenciales de daniel.lopez para acceder al bucket de datos de pacientes
    8. Recuperar el flag final
    
    🏁 Flag format: CLD[uuidv4]
  EOT
}

# Framework standardized outputs
output "aws_flag" {
  description = "AWS Challenge Flag"
  value       = "CLD[2f8e9d4a-7c1b-4e3a-9f2d-8b6c5e4d3a2f]"
}

output "challenge_summary" {
  description = "Challenge summary and metadata"
  value = {
    name         = "challenge-03-aws-only"
    provider     = "aws"
    difficulty   = "intermediate"
    description  = "AWS EC2 SSRF to S3 Access - Exploit SSRF vulnerability to access EC2 metadata and retrieve AWS credentials for S3 bucket access"
    learning_objectives = [
      "SSRF vulnerability exploitation",
      "AWS EC2 metadata service abuse",
      "IAM role and policy misconfigurations",
      "S3 bucket security patterns",
      "Cloud security attack chains"
    ]
    estimated_time = "30-45 minutes"
    flag = "CLD[2f8e9d4a-7c1b-4e3a-9f2d-8b6c5e4d3a2f]"
  }
}

output "attack_vectors" {
  description = "Available attack vectors and entry points"
  value = {
    primary_vector = {
      name = "SSRF to Metadata Service"
      description = "Exploit SSRF vulnerability in connectivity checker to access EC2 metadata service"
      entry_point = "http://${aws_eip.web_app_eip.public_ip}"
      target = "EC2 Instance Metadata Service (169.254.169.254)"
      objective = "Extract temporary AWS credentials from metadata service"
      difficulty = "intermediate"
    }
    secondary_vector = {
      name = "Credential Escalation"
      description = "Use EC2 role credentials to access credentials bucket and escalate to daniel.lopez user"
      entry_point = "S3 credentials bucket access"
      target = "daniel.lopez IAM user credentials in CSV format"
      objective = "Escalate privileges to access flag bucket"
      difficulty = "intermediate"
    }
    final_objective = {
      name = "S3 Flag Retrieval"
      description = "Use daniel.lopez credentials to access patient data bucket and retrieve flag"
      entry_point = "daniel.lopez AWS credentials"
      target = "S3 flag bucket - analytics/patient-insights/flag.txt"
      objective = "Retrieve final flag: CLD[2f8e9d4a-7c1b-4e3a-9f2d-8b6c5e4d3a2f]"
      difficulty = "basic"
    }
  }
}
