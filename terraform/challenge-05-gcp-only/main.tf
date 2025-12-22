terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "gcs" {
    # Configuration will be provided via backend config file
  }
}

# Generate random UUID for the flag (even though it's manual)
resource "random_uuid" "flag" {}

locals {
  # Challenge paths and instructions
  android_project_path = "${path.module}/android-project"
  google_services_path = "${path.module}/android-project/app/google-services.json"
  
  # Instructions for manual setup
  manual_instructions = [
    "1. Generate your own Firebase API key from Google Cloud Console",
    "2. Download google-services.json from Firebase Console",
    "3. Save it to: ${local.google_services_path}",
    "4. Navigate to: ${local.android_project_path}",
    "5. Run: ./gradlew assembleDebug",
    "6. APK will be generated in: app/build/outputs/apk/debug/",
    "7. Analyze the APK using jadx or Android Studio APK Analyzer"
  ]
}

# This challenge doesn't deploy any cloud resources
# It's a manual analysis challenge for Android APK security
