# Challenge-04-Azure-Only: MediCloudX Workforce Onboarding

## 📋 Overview

Welcome to MediCloudX, a leading healthcare technology company that provides cloud-based solutions for medical institutions worldwide. As part of their digital transformation initiative, MediCloudX has developed an automated workforce onboarding system to streamline the registration of clinical and administrative staff.

The HR department uses this Next.js web application to quickly provision Azure Active Directory accounts for new healthcare employees, ensuring they have the appropriate access to MediCloudX systems from day one.

## 🎯 Objective

Your task is to gain access to the MediCloudX Workforce Onboarding system and demonstrate the ability to create Azure AD user accounts. The system is designed to be accessible only to authorized HR personnel.

## 🏗️ Infrastructure Components

- **Azure Resource Group**: `medicloudx-identity` - Container for all identity management resources
- **Azure Container Registry**: Private registry hosting the Next.js application container
- **App Service Plan**: Linux-based hosting infrastructure for containerized applications
- **Azure Web App**: The MediCloudX Workforce Onboarding portal
- **Azure Active Directory**: Application registration with Microsoft Graph API integration
- **Azure Key Vault**: Secure storage for application secrets and configuration

## 🚀 Getting Started

### Prerequisites

- Azure CLI installed and configured
- Terraform >= 1.0
- Docker (for container image building)
- Valid Azure subscription with appropriate permissions

### Deployment

1. Clone the repository and navigate to the challenge directory:
   ```bash
   cd terraform/challenges/challenge-04-azure-only
   ```

2. Copy the example variables file and configure your Azure details:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your subscription and tenant IDs
   ```

3. Initialize and deploy the infrastructure:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. Note the application URL from the terraform output:
   ```bash
   terraform output app_service_url
   ```

### Accessing the Application

- **Application URL**: `https://medicloudx-onboarding-<random-suffix>.azurewebsites.net`
- **Purpose**: Automated clinical and administrative staff registration
- **Target Endpoint**: `/api/create-user` - Creates new Azure AD users

## 🔧 System Features

- **Automated User Provisioning**: Creates Azure AD accounts with temporary passwords
- **Microsoft Graph Integration**: Direct integration with Azure Active Directory
- **Security Compliance**: Follows MediCloudX enterprise security policies
- **Role-Based Access**: Designed for HR administrators and authorized personnel

## 🏥 Business Context

MediCloudX operates in a highly regulated healthcare environment where proper access management is critical. The onboarding system ensures:

- New staff receive appropriate system access quickly
- Temporary passwords are generated following security policies
- All account creation activities are logged for compliance
- Integration with existing Azure AD infrastructure

## 📝 System Requirements

- Modern web browser with JavaScript enabled
- Network access to Azure services
- Valid authentication credentials
- Understanding of healthcare data privacy requirements

## 🔍 Technical Architecture

The system is built using modern cloud-native technologies:

- **Frontend**: Next.js React application with modern UI components
- **Backend**: Node.js API endpoints with Azure integration
- **Container**: Docker-based deployment for consistency and scalability
- **Authentication**: Integration with Azure Active Directory
- **Storage**: Azure Key Vault for secure credential management

## ⚠️ Important Notes

- This system is for authorized personnel only
- All user creation activities are monitored and logged
- Temporary passwords must be changed on first login
- Contact IT support for access issues or questions

## 🎓 Learning Objectives

This challenge demonstrates:

- Modern web application security considerations
- Azure Active Directory integration patterns
- Container-based application deployment
- Healthcare industry compliance requirements
- Cloud-native security architectures

## 📞 Support

For technical support or questions about the MediCloudX Workforce Onboarding system, please contact the IT Security team or refer to the internal documentation portal.

---

*MediCloudX is committed to providing secure, reliable healthcare technology solutions that protect patient data and enable healthcare providers to focus on delivering excellent care.*
