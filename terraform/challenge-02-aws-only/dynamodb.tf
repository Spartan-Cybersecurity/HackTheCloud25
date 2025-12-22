# DynamoDB Table for Patient Data
resource "aws_dynamodb_table" "data_patience" {
  name           = "${var.project_name}-DataPatience-${random_string.suffix.result}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "patient_id"

  attribute {
    name = "patient_id"
    type = "S"
  }

  attribute {
    name = "department"
    type = "S"
  }

  # Global Secondary Index for department queries
  global_secondary_index {
    name            = "DepartmentIndex"
    hash_key        = "department"
    projection_type = "ALL"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-DataPatience"
  })
}

# Seed data for DynamoDB table
resource "aws_dynamodb_table_item" "patient_data" {
  for_each   = local.patient_data
  table_name = aws_dynamodb_table.data_patience.name
  hash_key   = aws_dynamodb_table.data_patience.hash_key

  item = jsonencode(each.value)
}

# Local values for patient data with hidden flag
locals {
  patient_data = {
    "001" = {
      patient_id = { S = "MED001" }
      name       = { S = "Dr. Maria Rodriguez" }
      department = { S = "cardiology" }
      diagnosis  = { S = "Hypertension management" }
      status     = { S = "active" }
      created_at = { S = "2025-01-15T10:30:00Z" }
      notes      = { S = "Regular follow-up required for blood pressure monitoring" }
    }
    "002" = {
      patient_id = { S = "MED002" }
      name       = { S = "James Anderson" }
      department = { S = "neurology" }
      diagnosis  = { S = "Migraine treatment" }
      status     = { S = "active" }
      created_at = { S = "2025-01-16T14:20:00Z" }
      notes      = { S = "Patient responding well to current medication regimen" }
    }
    "003" = {
      patient_id = { S = "MED003" }
      name       = { S = "Sarah Johnson" }
      department = { S = "pediatrics" }
      diagnosis  = { S = "Routine vaccination" }
      status     = { S = "completed" }
      created_at = { S = "2025-01-17T09:15:00Z" }
      notes      = { S = "All vaccines up to date, next appointment in 6 months" }
    }
    "004" = {
      patient_id = { S = "MED004" }
      name       = { S = "Robert Chen" }
      department = { S = "orthopedics" }
      diagnosis  = { S = "Post-surgery rehabilitation" }
      status     = { S = "active" }
      created_at = { S = "2025-01-18T11:45:00Z" }
      notes      = { S = "Physical therapy sessions scheduled twice weekly" }
    }
    "005" = {
      patient_id = { S = "MED005" }
      name       = { S = "Elena Vasquez" }
      department = { S = "internal_medicine" }
      diagnosis  = { S = "Diabetes type 2 management" }
      status     = { S = "active" }
      created_at = { S = "2025-01-19T16:00:00Z" }
      notes      = { S = "HbA1c levels improving, continue current treatment plan" }
    }
    "006" = {
      patient_id = { S = "MED006" }
      name       = { S = "Michael Thompson" }
      department = { S = "emergency" }
      diagnosis  = { S = "Acute appendicitis" }
      status     = { S = "discharged" }
      created_at = { S = "2025-01-20T03:30:00Z" }
      notes      = { S = "Emergency surgery completed successfully, recovery on track" }
    }
    "007" = {
      patient_id = { S = "ADMIN_SYS_007" }
      name       = { S = "System Administrator" }
      department = { S = "administration" }
      diagnosis  = { S = "System Maintenance" }
      status     = { S = "active" }
      created_at = { S = "2025-01-21T08:00:00Z" }
      notes      = { S = "CLD[f2a8d5b7-9c3e-4f1a-8b6d-2e9c7f4a1b5e]" }
      access_level = { S = "admin_only" }
    }
    "008" = {
      patient_id = { S = "MED008" }
      name       = { S = "Linda Garcia" }
      department = { S = "dermatology" }
      diagnosis  = { S = "Skin cancer screening" }
      status     = { S = "active" }
      created_at = { S = "2025-01-22T13:20:00Z" }
      notes      = { S = "Annual screening completed, all results negative" }
    }
    "009" = {
      patient_id = { S = "MED009" }
      name       = { S = "David Kim" }
      department = { S = "psychiatry" }
      diagnosis  = { S = "Anxiety disorder treatment" }
      status     = { S = "active" }
      created_at = { S = "2025-01-23T15:45:00Z" }
      notes      = { S = "Therapy sessions showing positive progress" }
    }
    "010" = {
      patient_id = { S = "MED010" }
      name       = { S = "Amanda Wilson" }
      department = { S = "obstetrics" }
      diagnosis  = { S = "Prenatal care - 32 weeks" }
      status     = { S = "active" }
      created_at = { S = "2025-01-24T10:10:00Z" }
      notes      = { S = "Baby development progressing normally, next ultrasound scheduled" }
    }
  }
}
