# Challenge 05 - Mobile Security

## 🏥 MediCloudX Health Manager

Welcome to the security analysis of MediCloudX Health Manager, an Android mobile application designed for healthcare professionals.

## 📱 Challenge Description

MediCloudX Health Manager is an enterprise Android application for comprehensive patient management and medical records. The application uses modern Firebase technologies for data synchronization and dynamic configuration.

### Application Features

- **Patient Management**: Complete patient registration and tracking system
- **Secure Authentication**: Login with validated medical credentials
- **Real-time Synchronization**: Integration with Firebase Firestore
- **Dynamic Configuration**: Adjustable parameters via Firebase
- **Professional Medical Interface**: Design optimized for healthcare professionals
- **HIPAA Compliance**: Architecture designed for secure medical data handling

## 🎯 Objective

Analyze the MediCloudX Health Manager mobile application to identify configuration vulnerabilities and find sensitive information that may be exposed.

## 🚀 Quick Start

### 1. Download the Application

The Android application is available in the `android-project/` directory as a compilable project, or you can use the precompiled APK if available.

### 2. Recommended Tools

- **Android Studio** with APK Analyzer
- **jadx** (Java Decompiler)
- **aapt** (Android Asset Packaging Tool)
- **curl** for REST API calls
- **Static analysis tools**

### 3. Initial Analysis

```bash
# If you have the APK
aapt dump badging medicloudx-health-manager.apk
jadx -d output_folder medicloudx-health-manager.apk

# Or analyze the Android project directly
cd android-project/app/src/main/res/values/
cat strings.xml
```

## 🔍 Analysis Points

- **Embedded Configurations**: Resource files and strings
- **Cloud Services**: Integration with Firebase services
- **API Configurations**: Credentials and access tokens
- **Data Management**: Database structure and administrative parameters

## 📋 Technical Information

### App Specifications

- **Package Name**: `com.medicloudx.healthmanager`
- **Version**: 1.0.0
- **Minimum SDK**: Android 7.0 (API 24)
- **Services**: Firebase Auth, Firestore, Remote Config

## 🎖️ Success Criteria

To successfully complete this challenge, you must:

1. ✅ **Analyze** the APK/project structure and identify key components
2. ✅ **Extract** embedded configurations and credentials
3. ✅ **Access** backend services using extracted information
4. ✅ **Locate** the challenge's target information

## 🏆 Additional Resources

### Test Credentials (for functional testing)

The application includes predefined credentials for functionality testing:

- Email: `dr.martinez@medicloudx.com`
- Password: `MediCloud2024!`

*Note: These credentials are only for verifying application functionality*

---

**MediCloudX Corporation © 2024**  
*Digital Health Solutions Development*
