# Challenge 05 - MediCloudX Data Exporter

## Scenario

You are a security researcher investigating MediCloudX, a healthcare technology company that provides cloud-based patient management solutions. During a compliance audit, you discovered an unusual binary file on one of their development servers.

The file appears to be a command-line tool called "MediCloudX Data Exporter" (version 2.1.3) designed for healthcare professionals to export patient records from their cloud infrastructure. The tool claims to be HIPAA compliant and requires proper authentication to access medical data.

Your task is to analyze this binary and determine if it contains any security issues that could compromise patient data or provide unauthorized access to the healthcare system.

## Background

MediCloudX operates a comprehensive patient management platform that stores sensitive medical records, lab results, and administrative data in secure cloud storage. Healthcare providers use various tools to access and export patient information for treatment, research, and compliance purposes.

The data exporter tool was developed by the MediCloudX engineering team to provide healthcare staff with a convenient way to extract patient records in JSON format for integration with other medical systems.

## Your Mission

Analyze the provided binary file and investigate whether proper security controls are in place for accessing patient data. Your goal is to determine if unauthorized access to medical records is possible and locate any sensitive administrative information that may be stored in the system.

## Getting Started

1. Deploy the challenge infrastructure using Terraform
2. Build the binary from the provided source code
3. Analyze the binary using appropriate security assessment tools
4. Investigate the data access mechanisms used by the tool
5. Document any security findings or potential data exposure

## Infrastructure Deployment

### Prerequisites

- Terraform installed
- AWS CLI configured with appropriate permissions
- Docker (for cross-platform compilation)

### Deploy the Challenge

```bash
# Navigate to the challenge directory
cd terraform/challenges/challenge-05-aws-only

# Initialize Terraform
terraform init

# Deploy the infrastructure
terraform apply -auto-approve
```

**Important:** Save the terraform outputs, especially the `embedded_credentials` and `challenge_info` which contain the AWS credentials and bucket suffix needed for the challenge.

### Destroy Infrastructure (Cleanup)

```bash
# When finished with the challenge
terraform destroy -auto-approve
```

## Challenge Files

- `medicloudx_exporter.c` - Source code for the data export tool
- `Makefile` - Build configuration for compilation
- `terraform/` - Infrastructure deployment files

## Infrastructure

The challenge deploys:
- Secure cloud storage for patient records
- Authentication and access control systems
- Medical data in JSON format (simulated patient records)
- Administrative backup systems

## Compliance Notice

All medical data used in this challenge is simulated and does not contain real patient information. This exercise is designed for educational purposes to demonstrate security assessment techniques in healthcare IT environments.

## Technical Requirements

- C compiler (gcc)
- libcurl development libraries
- Basic reverse engineering tools (strings, objdump, etc.)
- AWS CLI (optional)

## Binary Compilation

### Method 1: Native Compilation (macOS/Linux)

```bash
# Install dependencies (Ubuntu/Debian)
sudo apt-get install libcurl4-openssl-dev gcc make

# macOS with Homebrew
brew install curl openssl

# Get credentials from terraform output
terraform output embedded_credentials

# Build with embedded credentials
AWS_ACCESS_KEY_ID="[access_key]" AWS_SECRET_ACCESS_KEY="[secret_key]" make

# Test the binary
./medicloudx_exporter --version
```

### Method 2: Cross-Platform Compilation (Docker)

For maximum compatibility across different systems, use Docker to compile both ARM and x86_64 versions:

#### ARM64 Version (Apple Silicon, ARM servers)

```bash
# Build ARM64 binary
docker build --build-arg AWS_ACCESS_KEY_ID="[access_key]" --build-arg AWS_SECRET_ACCESS_KEY="[secret_key]" -t medicloudx-builder-arm .

# Extract binary
docker create --name temp-container medicloudx-builder-arm
docker cp temp-container:/build/medicloudx_exporter ./medicloudx_exporter_linux_arm
docker rm temp-container
```

#### x86_64 Version (Intel/AMD processors)

```bash
# Build x86_64 binary with platform specification
docker build --platform linux/amd64 --build-arg AWS_ACCESS_KEY_ID="[access_key]" --build-arg AWS_SECRET_ACCESS_KEY="[secret_key]" -t medicloudx-builder-x86 .

# Extract binary
docker create --name temp-container-x86 medicloudx-builder-x86
docker cp temp-container-x86:/build/medicloudx_exporter ./medicloudx_exporter_linux_x86
docker rm temp-container-x86
```

#### Verify Binary Architecture

```bash
# Check ARM64 binary
file medicloudx_exporter_linux_arm
# Expected: ELF 64-bit LSB executable, ARM aarch64

# Check x86_64 binary  
file medicloudx_exporter_linux_x86
# Expected: ELF 64-bit LSB executable, x86-64
```

### Replace Placeholders

After running `terraform apply`, replace the placeholders with actual values:

```bash
# Get the credentials
terraform output embedded_credentials

# Example output:
# {
#   "access_key" = "AKIAIOSFODNN7EXAMPLE"
#   "secret_key" = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
# }

# Use these values in the compilation commands above
```

## Expected Outcome

Successful completion of this challenge will demonstrate understanding of:
- Binary analysis techniques
- Security assessment methodologies  
- Cloud authentication mechanisms
- Healthcare data security principles

Submit your findings including any discovered security issues and recommendations for improving the data export process.
