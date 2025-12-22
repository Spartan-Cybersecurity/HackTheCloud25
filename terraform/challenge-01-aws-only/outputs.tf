output "aws_s3_website_endpoint" {
  description = "AWS S3 website endpoint URL"
  value       = "http://${aws_s3_bucket_website_configuration.website.website_endpoint}"
}

output "aws_s3_bucket_name" {
  description = "AWS S3 bucket name"
  value       = aws_s3_bucket.website.id
}

output "aws_flag_url" {
  description = "AWS S3 flag URL"
  value       = "http://${aws_s3_bucket_website_configuration.website.website_endpoint}/flag.txt"
}

output "aws_flag" {
  description = "AWS Challenge Flag"
  value       = "CLD[a7b3c9e2-4f8d-4a1b-9c3e-7f2a5d8b6e4c]"
}

output "challenge_summary" {
  description = "Challenge 1 AWS - Summary"
  value = {
    website = "http://${aws_s3_bucket_website_configuration.website.website_endpoint}"
    flag_url = "http://${aws_s3_bucket_website_configuration.website.website_endpoint}/flag.txt"
    flag     = "CLD[a7b3c9e2-4f8d-4a1b-9c3e-7f2a5d8b6e4c]"
    bucket   = aws_s3_bucket.website.id
  }
}

output "attack_vectors" {
  description = "AWS Challenge Attack Vectors"
  value = {
    vector_1 = {
      name = "Direct S3 Bucket Access"
      target = "http://${aws_s3_bucket_website_configuration.website.website_endpoint}/flag.txt"
      difficulty = "Basic"
      flag = "CLD[a7b3c9e2-4f8d-4a1b-9c3e-7f2a5d8b6e4c]"
    }
  }
}
