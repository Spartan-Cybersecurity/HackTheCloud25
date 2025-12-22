# Challenge 02 - AWS Cognito Privilege Escalation with API Gateway

## Overview

This enhanced challenge demonstrates multiple vulnerabilities in AWS Cognito implementations where custom user attributes can be manipulated to escalate privileges. Players will exploit weak role mapping configurations and JWT authorization to gain unauthorized access to sensitive patient data through both API Gateway and direct AWS resource access.

## Vulnerability Description

The challenge contains multiple vulnerabilities:

1. **Client-side validation bypass**: Email domain validation is performed only on the frontend, allowing direct registration via AWS CLI
2. **Privilege escalation via custom attributes**: Users can modify their `custom:role` attribute to escalate from `reader` to `admin` role
3. **JWT token exposure**: ID tokens stored in localStorage can be extracted and used to access protected APIs
4. **API authorization bypass**: JWT authorizer validates tokens but relies on mutable custom attributes for access control

## Enhanced Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Web App       │    │   Cognito        │    │   Identity      │
│   (S3 Website)  │◄──►│   User Pool      │◄──►│   Pool          │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                        │
         │                       ▼                        ▼
         │              ┌──────────────────┐    ┌─────────────────┐
         │              │   Lambda         │    │   IAM Roles     │
         │              │   (Post-Confirm) │    │   Reader/Admin  │
         │              └──────────────────┘    └─────────────────┘
         │                                                │
         ▼                                                ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   API Gateway   │◄──►│   Lambda         │    │   S3 Bucket     │
│   (JWT Auth)    │    │   (JWT Auth)     │    │   (Flag)        │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                        
         ▼                       ▼                        
┌─────────────────┐    ┌──────────────────┐              
│   Lambda        │    │   DynamoDB       │              
│   (Read Data)   │◄──►│   (Patient Data) │              
└─────────────────┘    └──────────────────┘              
```

## Challenge Information

Participants will receive the web application URL and basic scenario description after deployment. The detailed attack flow and solution steps are available in the `SOLUTION.md` file.

## Key Learning Points

1. **Client-side validation is insufficient**: Always implement server-side validation for security controls
2. **Custom attributes security**: Carefully consider which attributes users can modify and implement proper authorization checks
3. **Identity Pool role mapping**: Use fine-grained role mapping rules and avoid overly permissive configurations
4. **Token exposure**: Sensitive tokens stored in browser storage can be extracted and misused
5. **API Gateway security**: JWT authorizers must validate not only token validity but also user permissions
6. **Database access control**: Sensitive data in DynamoDB should have proper access controls and monitoring

## Enhanced Attack Vectors

### Primary Path (Web Application + API)
1. **Frontend Analysis**: Discover Cognito configuration in application source code
2. **Registration Bypass**: Use AWS CLI to register with any email domain
3. **Authentication**: Login and extract JWT tokens from browser storage
4. **Privilege Escalation**: Modify `custom:role` attribute from 'reader' to 'admin'
5. **API Access**: Use the web interface to call the Patient API with admin privileges
6. **Flag Discovery**: Find the flag hidden in patient records data

### Alternative Path (Direct AWS Access)
1. Follow steps 1-4 above for privilege escalation
2. **Identity Pool Credentials**: Obtain temporary AWS credentials via Identity Pool
3. **S3 Access**: Use admin credentials to access the flag bucket directly
4. **DynamoDB Access**: Query the patient database directly for the flag

## Security Recommendations

1. **Server-side validation**: Implement email domain validation on the backend
2. **Attribute protection**: Mark sensitive custom attributes as admin-only or implement proper authorization
3. **Role mapping**: Use more specific role mapping rules based on verified claims
4. **Least privilege**: Apply principle of least privilege to IAM roles and API permissions
5. **Token security**: Consider using secure, httpOnly cookies instead of localStorage for token storage
6. **API authorization**: Implement proper authorization checks beyond just JWT validation
7. **Data classification**: Implement proper data classification and access controls for sensitive information

## Deployment

### Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- Python 3.8+ (for Lambda dependencies)
- SES domain verification for email notifications

### Steps
1. **Prepare Lambda dependencies**:
   ```bash
   chmod +x install_dependencies.sh
   ./install_dependencies.sh
   ```

2. **Configure variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Deploy infrastructure**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Verify deployment**:
   - Check the web application URL in terraform outputs
   - Test the API Gateway endpoint
   - Verify DynamoDB table has seed data

## Infrastructure Components

### Core Services
- **Cognito User Pool**: User authentication with custom attributes
- **Cognito Identity Pool**: Role-based access to AWS resources  
- **API Gateway**: REST API for patient records with JWT authorization
- **Lambda Functions**: 
  - Post-confirmation trigger
  - JWT authorizer for API Gateway
  - Patient data reader
- **DynamoDB**: Patient records database with hidden flag
- **S3 Buckets**: Web hosting and flag storage
- **IAM Roles**: Reader and admin roles with different permissions

### Key Configurations
- **JWT Authorizer**: Validates tokens and checks `custom:role` attribute
- **Role Mapping**: Maps custom:role values to appropriate IAM roles
- **Seed Data**: 10 patient records including one with the flag
- **CORS**: Enabled for cross-origin API requests

## Flag Locations

The flag `CTF{m3d1cl0udx_d4t4b4s3_4cc3ss_pr1v1l3g3_3sc4l4t10n}` can be found in:
1. **DynamoDB**: Hidden in patient record ADMIN_SYS_007 notes field
2. **S3**: Traditional flag file in the admin-accessible bucket

## Troubleshooting

### Common Issues
- **Lambda deployment errors**: Run `./install_dependencies.sh` to create proper packages
- **API Gateway CORS**: Check that OPTIONS method is properly configured
- **Role mapping not working**: Verify Identity Pool role mapping configuration
- **SES emails not sending**: Ensure domain is verified in SES console

## Resources

- [AWS Cognito Security Best Practices](https://docs.aws.amazon.com/cognito/latest/developerguide/security.html)
- [API Gateway Lambda Authorizers](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-lambda-authorizer-lambda-function-create.html)
- [Identity Pool Role Mapping](https://docs.aws.amazon.com/cognito/latest/developerguide/role-based-access-control.html)
- [CloudGoat Vulnerable Cognito](https://github.com/RhinoSecurityLabs/cloudgoat)
- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)
