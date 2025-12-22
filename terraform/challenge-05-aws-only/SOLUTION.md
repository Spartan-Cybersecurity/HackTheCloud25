# Challenge 05 - MediCloudX Data Exporter - Solution Guide

## Overview

This challenge demonstrates credential extraction from a compiled C binary through reverse engineering techniques. The binary contains hardcoded AWS credentials that can be discovered through static and dynamic analysis.

## Vulnerability Summary

**CVE Class**: CWE-798 - Use of Hard-coded Credentials  
**Severity**: Critical  
**Impact**: Complete compromise of AWS resources accessible by embedded service account

## Attack Vector

The MediCloudX Data Exporter binary contains:
1. Hardcoded AWS Access Key ID as a string literal
2. AWS Secret Access Key split across multiple variables
3. S3 bucket naming patterns and endpoints
4. Functional AWS API integration for data access

## Step-by-Step Solution

### Step 1: Initial Binary Analysis

First, examine the binary to understand its purpose:

```bash
# Build the binary
make

# Check basic information
file medicloudx_exporter
./medicloudx_exporter --version
```

**Expected Output:**
```
MediCloudX Data Exporter v2.1.3
Build: Release
AWS SDK Integration: Embedded
Security: HIPAA Compliant
```

### Step 2: Extract AWS Access Key with Static Analysis

Use the `strings` command to extract all readable strings from the binary:

```bash
strings medicloudx_exporter_linux_x86 | grep AKIA
```

**Expected Output:**
```
AKIAIOSFODNN7EXAMPLE
```

This reveals the AWS Access Key ID: **`AKIAIOSFODNN7EXAMPLE`**

You can also run a full string analysis to understand the binary structure:

```bash
strings medicloudx_exporter_linux_x86
```

This will show various interesting strings including:
- AWS-related functions: `AWS4-HMAC-SHA256`, `aws4_request`, `s3.amazonaws.com`
- Crypto libraries: `HMAC`, `SHA256_Init`, `SHA256_Update`, `EVP_sha256`
- Export endpoints: `exports/patient_manifest.json`, `exports/cardiovascular_patients.json`
- Region: `us-east-1`
- Access Key: `AKIAIOSFODNN7EXAMPLE`

### Step 3: Extract AWS Secret Access Key with Dynamic Analysis

The AWS Secret Access Key is **NOT** directly visible with `strings` because it's constructed at runtime from multiple parts. We need to use **dynamic analysis** with `gdb` to extract it from memory.

#### Method 1: Intercept HMAC Function (Recommended)

The secret key is used in HMAC operations during AWS Signature Version 4 signing. We can intercept the `HMAC` function to capture it:

```bash
# Start GDB with the binary
gdb -q ./medicloudx_exporter_linux_x86

# Set a breakpoint on the HMAC function
(gdb) break HMAC
Breakpoint 1 at 0x401100

# Run the binary with a bucket suffix argument
(gdb) run --bucket a1b2c3d4

# When the program stops, the breakpoint will be hit
# The HMAC function signature is: HMAC(evp, key, keylen, data, datalen, result, resultlen)
# The key parameter (RSI register) contains our secret
```

**At the breakpoint, extract the key from memory:**

```gdb
# Capture the key pointer and length from registers
(gdb) set $key = (unsigned char *)$rsi
(gdb) set $len = (int)$rdx

# Examine the first 4 bytes (should show "AWS4")
(gdb) x/4cb $key
0x7fffffffcb20: 65 'A'  87 'W'  83 'S'  52 '4'

# Dump the complete key to a file
(gdb) dump memory /tmp/aws_hmac_key.bin $key ($key+$len)

# Dump only the secret part (skip "AWS4" prefix)
(gdb) dump memory /tmp/aws_secret.bin ($key+4) ($key+$len)

# Exit GDB
(gdb) quit
```

**Convert the binary dump to readable format:**

```bash
# Convert binary to hex
xxd -p /tmp/aws_secret.bin
# Output: 774a616c72585574464e454d492f4b374d44454e472f62507852666943594558414d504c454b4559

# Convert hex to ASCII to get the actual secret key
echo 774a616c72585574464e454d492f4b374d44454e472f62507852666943594558414d504c454b4559 | xxd -r -p; echo
```

**Expected Output:**
```
wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

This reveals the AWS Secret Access Key: **`wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`**

#### Method 2: Alternative - Disassemble and Analyze Code (Advanced)

For those interested in deeper analysis, you can disassemble the binary to understand how the secret key is constructed:

```bash
# Disassemble the binary
objdump -d medicloudx_exporter_linux_x86 | grep -A 30 "get_aws_secret_key"

# Or use radare2 for interactive analysis
r2 -A ./medicloudx_exporter_linux_x86
[0x00000000]> aaa
[0x00000000]> afl | grep secret
[0x00000000]> pdf @ sym.get_aws_secret_key
```

Looking at the code, you'll find that the secret key is split into three parts:
- `part1`: "wJalrXUtnFEMI/K7MDENG/"
- `part2`: "bPxRfiCY"
- `part3`: "EXAMPLEKEY"

These parts are concatenated at runtime to form the complete secret key.

#### Why Dynamic Analysis is Necessary

The secret key is **NOT** stored as a single string in the binary. Instead:
1. It's stored as **three separate variables** (`part1`, `part2`, `part3`)
2. These are **static variables** inside the `get_aws_secret_key()` function
3. They are concatenated into a **heap-allocated buffer** at runtime
4. The complete key is then prefixed with "AWS4" for HMAC operations

This is why `strings` alone won't reveal the complete secret - you need to either:
- Debug the running process and capture it from memory (Method 1)
- Manually reconstruct it by finding the parts in the disassembly (Method 2)

**Pro Tip:** If you run `strings` on the binary, you'll actually see fragments like:
```
wJalrXUtnFEMI/K7MDENG/
bPxRfiCY
EXAMPLEKEY
```

These are the parts of the secret key scattered throughout the binary. An observant analyst might piece them together manually, but the GDB approach is more reliable and educational.

### Step 4: Extract S3 Bucket Pattern

Find the S3 bucket naming pattern:

```bash
strings medicloudx_exporter_linux | grep exporter
```

**Expected Output:**
```
ctf-25-medical-exporter-records-%s
medicloudx_exporter.c
```

This reveals the bucket naming pattern: `ctf-25-medical-exporter-records-[suffix]`

### Step 5: Configure AWS CLI Profile

Create an AWS CLI profile with the extracted credentials:

```bash
aws configure --profile exporter
# AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
# AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
# Default region name [None]: us-east-1
# Default output format [None]: json
```

Or configure it directly with commands:

```bash
aws configure set aws_access_key_id AKIAIOSFODNN7EXAMPLE --profile exporter
aws configure set aws_secret_access_key wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY --profile exporter
aws configure set region us-east-1 --profile exporter
```

### Step 5.1: Verify AWS Credentials

Verify that the extracted credentials are valid:

```bash
aws sts get-caller-identity --profile exporter
```

**Expected Output:**
```json
{
    "UserId": "AIDAIOSFODNN7EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/ctf-25-medical-exporter-service-a1b2c3d4"
}
```

This confirms:
- The credentials are **valid**
- The IAM user is: `ctf-25-medical-exporter-service-a1b2c3d4`
- The AWS account ID is: `123456789012`
- The bucket suffix is: **`a1b2c3d4`** (extracted from the IAM username)

### Step 6: Explore S3 Bucket Structure

List the contents of the S3 bucket using the suffix discovered from the IAM username:

```bash
aws s3 ls s3://ctf-25-medical-exporter-records-a1b2c3d4 --profile exporter
```

**Expected Output:**
```
                           PRE admin/
                           PRE exports/
```

Explore the admin directory:

```bash
aws s3 ls s3://ctf-25-medical-exporter-records-a1b2c3d4/admin/ --profile exporter
```

**Expected Output:**
```
                           PRE system_backup/
```

Check the system_backup directory:

```bash
aws s3 ls s3://ctf-25-medical-exporter-records-a1b2c3d4/admin/system_backup/ --profile exporter
```

**Expected Output:**
```
2025-10-12 01:00:00         51 flag.txt
```

### Step 7: Download and Read the Flag

Download the flag file:

```bash
aws s3 cp s3://ctf-25-medical-exporter-records-a1b2c3d4/admin/system_backup/flag.txt ./ --profile exporter
```

**Expected Output:**
```
download: s3://ctf-25-medical-exporter-records-a1b2c3d4/admin/system_backup/flag.txt to ./flag.txt
```

Read the flag:

```bash
cat flag.txt
```

**Flag:** `CTF{m3d1cl0udx_r3v3rs3_3ng1n33r1ng_4ws_cr3d3nt14ls}`

## Complete Solution Summary

The challenge requires a combination of **static** and **dynamic analysis**:

```bash
# Step 1: Extract AWS Access Key (Static Analysis)
strings medicloudx_exporter_linux_x86 | grep AKIA
# Result: AKIAIOSFODNN7EXAMPLE

# Step 2: Extract AWS Secret Key (Dynamic Analysis with GDB)
gdb -q ./medicloudx_exporter_linux_x86
(gdb) break HMAC
(gdb) run --bucket test
(gdb) set $key = (unsigned char *)$rsi
(gdb) set $len = (int)$rdx
(gdb) dump memory /tmp/aws_secret.bin ($key+4) ($key+$len)
(gdb) quit

# Convert binary dump to ASCII
xxd -p /tmp/aws_secret.bin | xxd -r -p
# Result: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

# Step 3: Configure AWS CLI
aws configure --profile exporter
# Access Key: AKIAIOSFODNN7EXAMPLE
# Secret Key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
# Region: us-east-1

# Step 4: Verify credentials and get bucket suffix
aws sts get-caller-identity --profile exporter
# Extract suffix from username: a1b2c3d4

# Step 5: Navigate S3 and download flag
aws s3 ls s3://ctf-25-medical-exporter-records-a1b2c3d4 --profile exporter
aws s3 ls s3://ctf-25-medical-exporter-records-a1b2c3d4/admin/ --profile exporter
aws s3 ls s3://ctf-25-medical-exporter-records-a1b2c3d4/admin/system_backup/ --profile exporter
aws s3 cp s3://ctf-25-medical-exporter-records-a1b2c3d4/admin/system_backup/flag.txt ./ --profile exporter
cat flag.txt
```

## Technical Analysis

### Vulnerability Details

1. **Hard-coded Credentials (CWE-798)**
   - AWS credentials embedded as string literals
   - No encryption or obfuscation applied
   - Credentials visible in binary without special tools

2. **Information Disclosure (CWE-200)**  
   - Bucket naming patterns exposed in binary
   - Service endpoints and API calls visible
   - Authentication methods discoverable

3. **Insufficient Access Controls (CWE-284)**
   - Service account has broad S3 permissions
   - No runtime authentication required
   - Administrative files accessible via standard user account

### Security Implications

- **Complete AWS Account Compromise**: Extracted credentials provide full access to S3 resources
- **Data Exfiltration**: All patient records and administrative files can be accessed
- **Privilege Escalation**: Service account may have additional AWS permissions
- **Compliance Violation**: HIPAA violations due to inadequate access controls

## Mitigation Recommendations

1. **Remove Hard-coded Credentials**
   - Use AWS IAM roles and temporary credentials
   - Implement environment variables or secure key management
   - Use AWS Systems Manager Parameter Store or AWS Secrets Manager

2. **Implement Runtime Authentication**
   - Require user authentication before AWS access
   - Use multi-factor authentication for administrative functions
   - Implement session management and token expiration

3. **Apply Principle of Least Privilege**
   - Restrict service account permissions to minimum required
   - Separate read-only and administrative access
   - Implement resource-level access controls

4. **Add Binary Protection**
   - Implement code obfuscation for sensitive applications
   - Use binary packing or encryption
   - Add anti-debugging and tamper detection

5. **Monitor and Audit**
   - Log all AWS API calls using CloudTrail
   - Monitor for unusual access patterns
   - Implement automated security scanning for binaries

## Tools Used

- **Static Analysis**: `strings`, `file`
- **Dynamic Analysis**: `gdb` (GNU Debugger)
- **Binary Analysis**: `xxd` (hexdump utility)
- **Cloud Tools**: AWS CLI
- **Optional Advanced Tools**: `objdump`, `radare2`, `Ghidra`, `IDA Pro`

## Attack Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ Step 1: Static Analysis                                     │
│ strings medicloudx_exporter_linux_x86 | grep AKIA           │
│ → Extract AWS Access Key ID: AKIAIOSFODNN7EXAMPLE           │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 2: Dynamic Analysis with GDB                           │
│ • Set breakpoint on HMAC function                           │
│ • Extract key from RSI register (parameter 2)               │
│ • Dump memory to file                                       │
│ → Extract AWS Secret Key: wJalrXUtnFEMI/K7MDENG...          │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 3: AWS Authentication                                  │
│ aws configure --profile exporter                            │
│ → Create AWS CLI profile with extracted credentials         │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 4: Identity Verification                               │
│ aws sts get-caller-identity --profile exporter              │
│ → Confirm valid credentials                                 │
│ → Extract bucket suffix from IAM username: a1b2c3d4         │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 5: S3 Enumeration                                      │
│ aws s3 ls s3://ctf-25-medical-exporter-records-a1b2c3d4     │
│ → Navigate: / → admin/ → system_backup/ → flag.txt         │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 6: Flag Extraction                                     │
│ aws s3 cp s3://.../flag.txt ./                              │
│ → CTF{m3d1cl0udx_r3v3rs3_3ng1n33r1ng_4ws_cr3d3nt14ls}      │
└─────────────────────────────────────────────────────────────┘
```

## Learning Objectives

This challenge demonstrates:

**Reverse Engineering Skills:**
- Static analysis with `strings` and `objdump`
- Dynamic analysis with `gdb` debugger
- Memory dumping and register inspection
- Function hooking and breakpoint usage
- Hexadecimal to ASCII conversion

**Cloud Security Concepts:**
- AWS credential structure (Access Key ID + Secret Access Key)
- AWS Signature Version 4 signing process
- S3 bucket enumeration and access patterns
- IAM user permissions and identity verification
- CloudTrail logging bypass considerations

**Security Vulnerabilities:**
- CWE-798: Hard-coded credentials in binaries
- CWE-200: Information disclosure through binaries
- Credential extraction from compiled code
- Risks of embedding secrets in applications

**Analysis Techniques:**
- Difference between static and dynamic analysis
- When to use each approach
- Combining multiple techniques for complete analysis
- Understanding HMAC-SHA256 operations in AWS authentication

## Troubleshooting & Tips

### GDB Breakpoint Not Hitting

If the `HMAC` breakpoint doesn't trigger:
```bash
# Verify the binary has HMAC calls
nm -D medicloudx_exporter_linux_x86 | grep HMAC

# Try breaking on generate_aws_auth_header instead
(gdb) break generate_aws_auth_header
```

### Finding the Right Memory Address

The key is passed in the **RSI register** (second parameter in x86-64 calling convention):
- **RDI**: First parameter (EVP method)
- **RSI**: Second parameter (key pointer) ← This is what we want
- **RDX**: Third parameter (key length)

### Alternative Memory Extraction

If `dump memory` fails, try:
```gdb
(gdb) x/40xb $rsi
# Manually copy the hex values and convert
```

### Understanding the AWS4 Prefix

When you dump the key from HMAC, you'll see it starts with "AWS4" because AWS Signature Version 4 derives signing keys using:
```
kSecret = "AWS4" + SecretAccessKey
kDate = HMAC("AWS4" + Secret, Date)
kRegion = HMAC(kDate, Region)
kService = HMAC(kRegion, Service)
kSigning = HMAC(kService, "aws4_request")
```

That's why we skip the first 4 bytes (`$key+4`) when dumping the actual secret.

## Technical Deep Dive: How the Binary Works

### AWS Signature Version 4 Process

The binary implements AWS Signature Version 4 authentication:

1. **Canonical Request**: Creates a standardized request string
   ```
   GET
   /exports/cardiovascular_patients.json
   
   host:ctf-25-medical-exporter-records-a1b2c3d4.s3.amazonaws.com
   x-amz-content-sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
   x-amz-date:20251012T010000Z
   ```

2. **String to Sign**: Combines timestamp, credential scope, and canonical request hash
   ```
   AWS4-HMAC-SHA256
   20251012T010000Z
   20251012/us-east-1/s3/aws4_request
   <hash_of_canonical_request>
   ```

3. **Signing Key Derivation**: Uses HMAC-SHA256 in a chain
   - This is where we intercept the secret key!

4. **Calculate Signature**: HMAC of string-to-sign with signing key

5. **Authorization Header**: Includes access key, credential scope, and signature

### Key Functions in the Binary

From the `strings` output, we can identify these key functions:

- `get_aws_secret_key()`: Assembles the secret from three parts
- `generate_aws_auth_header()`: Creates the Authorization header
- `hmac_sha256()`: Wrapper around OpenSSL's HMAC
- `sha256_hash()`: SHA256 hashing for request payloads
- `download_from_s3()`: Main function that uses libcurl to fetch from S3

### Why This Approach Works

The binary must:
1. Construct the complete secret key in memory (for HMAC operations)
2. Call OpenSSL's `HMAC()` function (external library call)
3. Pass the key as a pointer to the function

This creates the perfect opportunity to intercept the key at the function boundary using GDB.

## References

- [CWE-798: Use of Hard-coded Credentials](https://cwe.mitre.org/data/definitions/798.html)
- [CWE-200: Exposure of Sensitive Information](https://cwe.mitre.org/data/definitions/200.html)
- [OWASP: Cryptographic Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html)  
- [AWS Security Best Practices](https://docs.aws.amazon.com/security/)
- [AWS Signature Version 4 Signing Process](https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html)
- [GDB Documentation - Memory Dump](https://sourceware.org/gdb/onlinedocs/gdb/Dump_002fRestore-Files.html)
