# Challenge Information
output "challenge_info" {
  description = "Challenge 5 GCP - Mobile Security Information"
  value = {
    challenge_name = "Challenge-05-GCP: Mobile Security - Android APK Analysis"
    challenge_type = "Manual Analysis"
    target_app = "MediCloudX Health Manager"
    package_name = "com.medicloudx.healthmanager"
  }
}

# Android Project Path
output "android_project_path" {
  description = "Path to Android project for compilation"
  value = local.android_project_path
}

# Google Services Configuration Path
output "google_services_path" {
  description = "Required path for google-services.json file"
  value = local.google_services_path
}

# Manual Setup Instructions
output "setup_instructions" {
  description = "Step-by-step instructions for manual challenge setup"
  value = {
    title = "🚀 Challenge-05-GCP Manual Setup Instructions"
    steps = local.manual_instructions
    important_notes = [
      "⚠️  This is a MANUAL challenge - no cloud resources are deployed",
      "📱 You need to generate your own Firebase API key",
      "🔧 APK compilation is required for analysis",
      "🔍 Use jadx or Android Studio APK Analyzer for reverse engineering"
    ]
  }
}

# APK Build Information
output "apk_build_info" {
  description = "Information about APK building process"
  value = {
    build_command = "cd ${local.android_project_path} && ./gradlew assembleDebug"
    output_location = "${local.android_project_path}/app/build/outputs/apk/debug/"
    analysis_tools = [
      "jadx -d output_folder app-debug.apk",
      "Android Studio → Build → Analyze APK",
      "aapt dump badging app-debug.apk"
    ]
  }
}

# Framework Standard Outputs
output "gcp_flag" {
  description = "GCP Challenge Flag (actual value hidden for security)"
  value       = "CLD[generated-uuid-from-terraform]"
  sensitive   = false
}

output "challenge_summary" {
  description = "Challenge summary for framework integration"
  value = {
    challenge_id = "challenge-05-gcp-only"
    name = "Mobile Security - Android APK Analysis"
    provider = "GCP"
    difficulty = "advanced"
    objective = "Analyze Android APK to extract Firebase configurations and find hidden flag"
    vulnerability = "Hardcoded Firebase credentials in APK resources"
    attack_method = "Static analysis of Android APK using reverse engineering tools"
    flag_format = "CLD[UUID]"
    dependencies = []
    challenge_type = "manual_analysis"
  }
}

output "attack_vectors" {
  description = "Available attack vectors for this challenge"
  value = {
    vector_1 = {
      name = "Android APK Static Analysis"
      target = "MediCloudX Health Manager APK"
      difficulty = "Advanced"
      prerequisites = ["Android Studio or jadx", "Basic knowledge of Android development", "APK analysis tools"]
      steps = [
        "Generate Firebase API key and save to ${local.google_services_path}",
        "Compile APK: cd ${local.android_project_path} && ./gradlew assembleDebug",
        "Extract APK resources using jadx or Android Studio",
        "Analyze res/values/strings.xml for hardcoded credentials",
        "Look for Firebase configuration and API endpoints",
        "Find flag embedded in application resources"
      ]
      commands = {
        setup_firebase = "Save your google-services.json to: ${local.google_services_path}"
        build_apk = "cd ${local.android_project_path} && ./gradlew assembleDebug"
        analyze_jadx = "jadx -d medicloudx_decompiled app-debug.apk"
        check_strings = "cd medicloudx_decompiled/resources/res/values/ && cat strings.xml"
      }
      flag_format = "CLD[UUID]"
      note = "This is a manual analysis challenge - no cloud resources deployed"
    }
  }
}
