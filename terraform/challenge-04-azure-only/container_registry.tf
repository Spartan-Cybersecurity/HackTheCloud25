# Azure Container Registry for hosting the vulnerable Next.js application

resource "azurerm_container_registry" "medicloudx_acr" {
  name                = "medicloudxacr${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.medicloudx_identity.name
  location            = azurerm_resource_group.medicloudx_identity.location
  sku                 = "Basic"
  
  # Enable admin user to allow App Service to pull images
  admin_enabled = true

  tags = {
    Environment = var.environment
    Challenge   = "04-azure-only"
    Purpose     = "Container Image Storage"
    Component   = "ACR"
  }
}

# Local provisioner to build and push the Docker image
# This requires Docker to be installed and running locally
resource "null_resource" "docker_build_push" {
  depends_on = [azurerm_container_registry.medicloudx_acr]
  
  triggers = {
    # Rebuild when ACR changes or when the application code changes
    acr_id = azurerm_container_registry.medicloudx_acr.id
    # Force rebuild on every apply for development
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Create temporary directory for application
      mkdir -p ./app-build
      
      # Create the vulnerable Next.js application files
      cat > ./app-build/package.json << 'EOF'
{
  "name": "medicloudx-onboarding",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "15.2.1",
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "@azure/msal-node": "^2.6.6",
    "@azure/identity": "^4.0.1",
    "@microsoft/microsoft-graph-client": "^3.0.7"
  },
  "devDependencies": {
    "eslint": "^9",
    "eslint-config-next": "15.2.1"
  }
}
EOF

      cat > ./app-build/Dockerfile << 'EOF'
FROM node:18-alpine AS base

# Install dependencies only when needed
FROM base AS deps
WORKDIR /app

# Install dependencies based on the preferred package manager
COPY package*.json ./
RUN npm install --omit=dev

# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

RUN npm run build

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000
ENV HOSTNAME "0.0.0.0"

CMD ["node", "server.js"]
EOF

      cat > ./app-build/next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  reactStrictMode: true,
  swcMinify: true,
  experimental: {
    appDir: true,
  }
}

module.exports = nextConfig
EOF
      # Create src directory structure
      mkdir -p ./app-build/src/app/{api/create-user,api/update-departament,api/validate/support,docs,login,support}
      mkdir -p ./app-build/src/app/support/{login,callback,dashboard}
      mkdir -p ./app-build/src/components
      mkdir -p ./app-build/public
      
      # Remove middleware from root (if exists)
      rm -f ./app-build/middleware.js
      
      # Create middleware.js in SRC (where it worked before)
      cat > ./app-build/src/middleware.js << 'EOF'
import { NextResponse } from 'next/server'

export const config = {
    matcher: ['/api/create-user', '/api/update-departament'],
}

export function middleware(request) {
    // Debug: Confirm middleware is executing
    console.log('🚨 MIDDLEWARE EJECUTÁNDOSE - URL:', request.url);
    console.log('🚨 HEADERS:', Object.fromEntries(request.headers.entries()));

    const token = request.headers.get("x-super-secret-auth");

    if (!token) {
        console.log('❌ NO TOKEN - Redirecting to /login');
        return NextResponse.redirect(new URL('/login', request.url))
    }

    console.log('✅ TOKEN FOUND - Allowing request');
    return NextResponse.next();
}
EOF

      # Create main page
      cat > ./app-build/src/app/page.js << 'EOF'
'use client'
import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'

export default function Home() {
  const [isAuthenticated, setIsAuthenticated] = useState(false)
  const [userInfo, setUserInfo] = useState(null)
  const router = useRouter()

  useEffect(() => {
    const token = document.cookie.includes('auth-token=')
    if (!token) {
      router.push('/login')
    } else {
      setIsAuthenticated(true)
      // In a real app, you'd decode the JWT to get user info
      setUserInfo({ name: 'HR Administrator', role: 'admin' })
    }
  }, [router])

  const handleCreateUser = async () => {
    try {
      const response = await fetch('/api/create-user', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({}),
      })

      if (response.ok) {
        const userData = await response.json()
        alert('User created successfully!\\n\\nUser Principal Name: ' + userData.userPrincipalName + '\\nDisplay Name: ' + userData.displayName + '\\nTemporary Password: ' + userData.tempPassword)
      } else {
        const error = await response.text()
        alert('Error creating user: ' + error)
      }
    } catch (error) {
      console.error('Error:', error)
      alert('Error creating user')
    }
  }

  if (!isAuthenticated) {
    return <div>Loading...</div>
  }

  return (
    <div style={{ padding: '40px', fontFamily: 'system-ui, sans-serif', backgroundColor: '#f8fafc', minHeight: '100vh' }}>
      <div style={{ maxWidth: '800px', margin: '0 auto', backgroundColor: 'white', padding: '32px', borderRadius: '12px', boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)' }}>
        <header style={{ borderBottom: '1px solid #e2e8f0', paddingBottom: '24px', marginBottom: '32px' }}>
          <h1 style={{ fontSize: '32px', fontWeight: 'bold', color: '#1e293b', marginBottom: '8px' }}>
            🏥 MediCloudX Workforce Onboarding
          </h1>
          <p style={{ color: '#64748b', fontSize: '18px' }}>
            Automated Clinical & Administrative Staff Registration System
          </p>
        </header>

        {userInfo && (
          <div style={{ backgroundColor: '#f1f5f9', padding: '16px', borderRadius: '8px', marginBottom: '32px' }}>
            <p style={{ margin: '0', color: '#334155' }}>
              Welcome, <strong>{userInfo.name}</strong> ({userInfo.role})
            </p>
          </div>
        )}

        <div style={{ backgroundColor: '#fef3c7', border: '1px solid #f59e0b', padding: '16px', borderRadius: '8px', marginBottom: '32px' }}>
          <h3 style={{ margin: '0 0 8px 0', color: '#92400e' }}>⚠️ System Notice</h3>
          <p style={{ margin: '0', color: '#92400e', fontSize: '14px' }}>
            This onboarding system automatically provisions Azure AD accounts for new healthcare staff. 
            Only authorized HR personnel should have access to this functionality.
          </p>
        </div>

        <div style={{ textAlign: 'center' }}>
          <button
            onClick={handleCreateUser}
            style={{
              backgroundColor: '#2563eb',
              color: 'white',
              padding: '12px 32px',
              fontSize: '18px',
              border: 'none',
              borderRadius: '8px',
              cursor: 'pointer',
              fontWeight: '600',
              transition: 'background-color 0.2s'
            }}
            onMouseOver={(e) => e.target.style.backgroundColor = '#1d4ed8'}
            onMouseOut={(e) => e.target.style.backgroundColor = '#2563eb'}
          >
            Create New Staff Account
          </button>
        </div>

        <div style={{ marginTop: '32px', padding: '16px', backgroundColor: '#f8fafc', borderRadius: '8px', fontSize: '14px', color: '#64748b' }}>
          <h4 style={{ margin: '0 0 12px 0', color: '#374151' }}>System Features:</h4>
          <ul style={{ margin: '0', paddingLeft: '20px' }}>
            <li>Automated Azure AD user provisioning</li>
            <li>Temporary password generation</li>
            <li>Compliance with MediCloudX security policies</li>
            <li>Integration with Microsoft Graph API</li>
          </ul>
        </div>
      </div>
    </div>
  )
}
EOF

      # Create login page
      cat > ./app-build/src/app/login/page.js << 'EOF'
'use client'
import { useState } from 'react'
import { useRouter } from 'next/navigation'

export default function Login() {
  const [credentials, setCredentials] = useState({ username: '', password: '' })
  const [error, setError] = useState('')
  const router = useRouter()

  const handleLogin = (e) => {
    e.preventDefault()
    
    // Simple authentication check (in a real app, this would be more secure)
    if (credentials.username === 'hradmin' && credentials.password === 'MediCloudX2025!') {
      // Set auth cookie (in a real app, this would be a proper JWT)
      document.cookie = 'auth-token=valid; path=/; max-age=3600'
      router.push('/')
    } else {
      setError('Invalid credentials. Contact IT support for access.')
    }
  }

  return (
    <div style={{ 
      minHeight: '100vh', 
      display: 'flex', 
      alignItems: 'center', 
      justifyContent: 'center',
      backgroundColor: '#f1f5f9',
      fontFamily: 'system-ui, sans-serif'
    }}>
      <div style={{
        backgroundColor: 'white',
        padding: '40px',
        borderRadius: '12px',
        boxShadow: '0 10px 25px -3px rgba(0, 0, 0, 0.1)',
        width: '100%',
        maxWidth: '400px'
      }}>
        <div style={{ textAlign: 'center', marginBottom: '32px' }}>
          <h1 style={{ fontSize: '28px', fontWeight: 'bold', color: '#1e293b', marginBottom: '8px' }}>
            🏥 MediCloudX
          </h1>
          <p style={{ color: '#64748b', fontSize: '16px' }}>
            Workforce Onboarding Portal
          </p>
        </div>

        <form onSubmit={handleLogin}>
          <div style={{ marginBottom: '20px' }}>
            <label style={{ display: 'block', marginBottom: '8px', color: '#374151', fontWeight: '500' }}>
              Username
            </label>
            <input
              type="text"
              value={credentials.username}
              onChange={(e) => setCredentials({ ...credentials, username: e.target.value })}
              style={{
                width: '100%',
                padding: '12px',
                border: '1px solid #d1d5db',
                borderRadius: '8px',
                fontSize: '16px'
              }}
              required
            />
          </div>

          <div style={{ marginBottom: '24px' }}>
            <label style={{ display: 'block', marginBottom: '8px', color: '#374151', fontWeight: '500' }}>
              Password
            </label>
            <input
              type="password"
              value={credentials.password}
              onChange={(e) => setCredentials({ ...credentials, password: e.target.value })}
              style={{
                width: '100%',
                padding: '12px',
                border: '1px solid #d1d5db',
                borderRadius: '8px',
                fontSize: '16px'
              }}
              required
            />
          </div>

          {error && (
            <div style={{
              backgroundColor: '#fee2e2',
              border: '1px solid #f87171',
              color: '#dc2626',
              padding: '12px',
              borderRadius: '8px',
              marginBottom: '20px',
              fontSize: '14px'
            }}>
              {error}
            </div>
          )}

          <button
            type="submit"
            style={{
              width: '100%',
              backgroundColor: '#2563eb',
              color: 'white',
              padding: '12px',
              border: 'none',
              borderRadius: '8px',
              fontSize: '16px',
              fontWeight: '600',
              cursor: 'pointer'
            }}
          >
            Sign In
          </button>
        </form>

        <div style={{ marginTop: '24px', padding: '16px', backgroundColor: '#f8fafc', borderRadius: '8px', fontSize: '12px', color: '#6b7280', textAlign: 'center' }}>
          <p style={{ margin: '0' }}>
            Access restricted to authorized HR personnel only.<br />
            Contact IT support if you need assistance.
          </p>
        </div>
      </div>
    </div>
  )
}
EOF

      # Create the vulnerable API endpoint with real Microsoft Graph integration
      cat > ./app-build/src/app/api/create-user/route.js << 'EOF'
import { NextRequest, NextResponse } from 'next/server'

// Real Azure AD integration using Microsoft Graph API
export async function POST(request) {
  try {
    const clientId = process.env.AZURE_CLIENT_ID
    const clientSecret = process.env.AZURE_CLIENT_SECRET
    const tenantId = process.env.AZURE_TENANT_ID

    if (!clientId || !clientSecret || !tenantId) {
      return NextResponse.json(
        { error: 'Azure AD configuration missing' },
        { status: 500 }
      )
    }

    // Get access token from Azure AD
    const tokenResponse = await fetch('https://login.microsoftonline.com/' + tenantId + '/oauth2/v2.0/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        client_id: clientId,
        client_secret: clientSecret,
        scope: 'https://graph.microsoft.com/.default',
        grant_type: 'client_credentials'
      })
    })

    if (!tokenResponse.ok) {
      const error = await tokenResponse.text()
      console.error('Token request failed:', error)
      return NextResponse.json(
        { error: 'Authentication failed' },
        { status: 401 }
      )
    }

    const tokenData = await tokenResponse.json()
    const accessToken = tokenData.access_token

    // Generate random user data
    const userId = Math.random().toString(36).substr(2, 5)
    const tempPassword = generateTempPassword()
    
    // Create user in Azure AD using Microsoft Graph API
    const userPayload = {
      accountEnabled: true,
      displayName: 'CTF User ' + userId,
      mailNickname: 'ctf-user-' + userId,
      userPrincipalName: 'ctf-user-' + userId + '@ekocloudsec.com',
      passwordProfile: {
        forceChangePasswordNextSignIn: true,
        password: tempPassword
      }
    }

    const createUserResponse = await fetch('https://graph.microsoft.com/v1.0/users', {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer ' + accessToken,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(userPayload)
    })

    if (!createUserResponse.ok) {
      const error = await createUserResponse.text()
      console.error('User creation failed:', error)
      return NextResponse.json(
        { error: 'Failed to create user in Azure AD', details: error },
        { status: 400 }
      )
    }

    const createdUser = await createUserResponse.json()

    // Return success response with real user data
    const responseData = {
      id: createdUser.id,
      userPrincipalName: createdUser.userPrincipalName,
      displayName: createdUser.displayName,
      mailNickname: createdUser.mailNickname,
      accountEnabled: createdUser.accountEnabled,
      createdDateTime: createdUser.createdDateTime,
      tempPassword: tempPassword,
      forceChangePasswordNextSignIn: true
    }

    return NextResponse.json(responseData, { 
      status: 201,
      headers: {
        'Cache-Control': 'no-store',
        'Content-Type': 'application/json; charset=utf-8'
      }
    })
    
  } catch (error) {
    console.error('Error creating user:', error)
    return NextResponse.json(
      { error: 'Internal server error', message: error.message },
      { status: 500 }
    )
  }
}

function generateTempPassword() {
  // Generate a secure password that meets Azure AD requirements
  const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  const lower = 'abcdefghijklmnopqrstuvwxyz'
  const numbers = '0123456789'
  const symbols = '!@#$%^&*'
  
  let password = ''
  // Ensure at least one of each type
  password += upper.charAt(Math.floor(Math.random() * upper.length))
  password += lower.charAt(Math.floor(Math.random() * lower.length))
  password += numbers.charAt(Math.floor(Math.random() * numbers.length))
  password += symbols.charAt(Math.floor(Math.random() * symbols.length))
  
  // Fill the rest randomly
  const allChars = upper + lower + numbers + symbols
  for (let i = 4; i < 16; i++) {
    password += allChars.charAt(Math.floor(Math.random() * allChars.length))
  }
  
  // Shuffle the password
  return password.split('').sort(() => Math.random() - 0.5).join('')
}
EOF

      # Create support landing page
      cat > ./app-build/src/app/support/page.js << 'EOF'
'use client'

export default function SupportHub() {
  return (
    <div style={{ 
      minHeight: '100vh', 
      display: 'flex', 
      flexDirection: 'column', 
      alignItems: 'center', 
      justifyContent: 'center',
      backgroundColor: '#f8f9fa',
      fontFamily: 'system-ui, sans-serif'
    }}>
      <div style={{
        backgroundColor: 'white',
        padding: '3rem',
        borderRadius: '12px',
        boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)',
        textAlign: 'center',
        maxWidth: '500px'
      }}>
        <div style={{ marginBottom: '2rem' }}>
          <h1 style={{ 
            color: '#2563eb', 
            fontSize: '2.5rem', 
            marginBottom: '0.5rem',
            fontWeight: 'bold'
          }}>
            🔧 MediCloudX Support Hub
          </h1>
          <p style={{ 
            color: '#6b7280', 
            fontSize: '1.1rem',
            lineHeight: '1.6'
          }}>
            Secure access portal for Support Department staff
          </p>
        </div>

        <div style={{
          backgroundColor: '#fef3c7',
          border: '1px solid #f59e0b',
          borderRadius: '8px',
          padding: '1rem',
          marginBottom: '2rem'
        }}>
          <p style={{ 
            color: '#92400e', 
            fontSize: '0.9rem',
            margin: '0',
            fontWeight: '500'
          }}>
            ⚠️ Access restricted to Support Department personnel only
          </p>
        </div>

        <button 
          onClick={() => window.location.href = '/support/login'}
          style={{
            backgroundColor: '#2563eb',
            color: 'white',
            padding: '12px 24px',
            fontSize: '1.1rem',
            border: 'none',
            borderRadius: '8px',
            cursor: 'pointer',
            fontWeight: '600',
            transition: 'background-color 0.3s'
          }}
          onMouseOver={(e) => e.target.style.backgroundColor = '#1d4ed8'}
          onMouseOut={(e) => e.target.style.backgroundColor = '#2563eb'}
        >
          🔑 Sign in with Microsoft Account
        </button>

        <div style={{ marginTop: '2rem', paddingTop: '1rem', borderTop: '1px solid #e5e7eb' }}>
          <p style={{ 
            color: '#9ca3af', 
            fontSize: '0.8rem',
            margin: '0'
          }}>
            © 2025 MediCloudX Healthcare Solutions
          </p>
        </div>
      </div>
    </div>
  )
}
EOF

      # Create update-departament API endpoint
      mkdir -p ./app-build/src/app/api/update-departament
      cat > ./app-build/src/app/api/update-departament/route.js << 'EOF'
import { NextResponse } from 'next/server';

export async function POST(request) {
  try {
    console.log('🔄 UPDATE-DEPARTAMENT API: Request received');
    
    let body;
    try {
      body = await request.json();
      console.log('📋 Request body:', body);
    } catch (jsonError) {
      console.error('❌ JSON parsing error:', jsonError.message);
      return NextResponse.json({ 
        error: 'Invalid JSON in request body',
        details: jsonError.message 
      }, { status: 400 });
    }
    
    const { id, departament } = body;
    
    // Validate required fields
    if (!id || !departament) {
      console.log('❌ Missing required fields');
      return NextResponse.json({ 
        error: 'Missing required fields: id and departament' 
      }, { status: 400 });
    }

    // Get Azure AD credentials from environment
    const clientId = process.env.AZURE_CLIENT_ID
    const clientSecret = process.env.AZURE_CLIENT_SECRET
    const tenantId = process.env.AZURE_TENANT_ID

    if (!clientId || !clientSecret || !tenantId) {
      console.log('❌ Azure AD configuration missing');
      return NextResponse.json(
        { error: 'Azure AD configuration missing' },
        { status: 500 }
      )
    }

    // Get access token from Azure AD
    const tokenResponse = await fetch('https://login.microsoftonline.com/' + tenantId + '/oauth2/v2.0/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        client_id: clientId,
        client_secret: clientSecret,
        scope: 'https://graph.microsoft.com/.default',
        grant_type: 'client_credentials'
      })
    })

    if (!tokenResponse.ok) {
      const error = await tokenResponse.text()
      console.error('Token request failed:', error)
      return NextResponse.json(
        { error: 'Authentication failed', details: error },
        { status: 401 }
      )
    }

    let tokenData;
    try {
      tokenData = await tokenResponse.json()
      console.log('✅ Token obtained successfully');
    } catch (tokenJsonError) {
      console.error('❌ Token response JSON parsing error:', tokenJsonError.message);
      return NextResponse.json(
        { error: 'Invalid token response from Azure AD', details: tokenJsonError.message },
        { status: 500 }
      )
    }
    
    const accessToken = tokenData.access_token

    // Update user department in Azure AD via Microsoft Graph API
    console.log(`🔄 Updating user $${id} department to: $${departament}`);
    
    const graphResponse = await fetch(`https://graph.microsoft.com/v1.0/users/$${id}`, {
      method: 'PATCH',
      headers: {
        'Authorization': 'Bearer ' + accessToken,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        department: departament,
        companyName: "MediCloudX Healthcare",
        // Additional user properties that can be updated
        jobTitle: departament === 'admins' ? 'System Administrator' : 
                 departament === 'doctors' ? 'Medical Doctor' :
                 departament === 'nurses' ? 'Registered Nurse' :
                 departament === 'staff' ? 'Healthcare Staff' : 'Employee'
      })
    });

    if (!graphResponse.ok) {
      const errorData = await graphResponse.text();
      console.log('❌ Microsoft Graph API error:', errorData);
      return NextResponse.json({ 
        error: 'Failed to update user department',
        details: errorData 
      }, { status: graphResponse.status });
    }

    // Microsoft Graph PATCH often returns 204 No Content (empty response) on success
    let updatedUser = null;
    const contentType = graphResponse.headers.get('content-type');
    
    if (contentType && contentType.includes('application/json')) {
      try {
        const responseText = await graphResponse.text();
        if (responseText && responseText.trim()) {
          updatedUser = JSON.parse(responseText);
          console.log('✅ User department updated successfully with response:', updatedUser.id);
        } else {
          console.log('✅ User department updated successfully (empty response - normal for PATCH)');
        }
      } catch (graphJsonError) {
        console.log('✅ User department updated successfully (non-JSON response - normal for PATCH)');
        // This is actually normal for PATCH operations that return 204 No Content
      }
    } else {
      console.log('✅ User department updated successfully (no JSON content - normal for PATCH)');
    }

    return NextResponse.json({
      success: true,
      message: 'User department updated successfully',
      updated: {
        id: id,
        departament: departament,
        status: 'Updated successfully'
      },
      user: updatedUser ? {
        id: updatedUser.id,
        displayName: updatedUser.displayName,
        userPrincipalName: updatedUser.userPrincipalName,
        department: updatedUser.department,
        jobTitle: updatedUser.jobTitle,
        companyName: updatedUser.companyName
      } : {
        id: id,
        note: 'User updated successfully. Microsoft Graph returned empty response (normal for PATCH operations).'
      }
    });

  } catch (error) {
    console.error('💥 Error updating user department:', error);
    return NextResponse.json({ 
      error: 'Internal server error',
      message: error.message 
    }, { status: 500 });
  }
}
EOF

      # Create support login route (OAuth redirect)
      cat > ./app-build/src/app/support/login/route.js << 'EOF'
import { NextResponse } from 'next/server';

export async function GET(request) {
  try {
    console.log('🔄 SUPPORT LOGIN: Initiating OAuth flow');
    
    const clientId = process.env.AZURE_CLIENT_ID;
    const tenantId = process.env.AZURE_TENANT_ID;
    
    if (!clientId || !tenantId) {
      console.error('❌ Missing OAuth configuration');
      return NextResponse.json(
        { error: 'OAuth configuration missing' },
        { status: 500 }
      );
    }

    // Construct OAuth URL
    const baseUrl = request.headers.get('host');
    const protocol = request.headers.get('x-forwarded-proto') || 'https';
    const redirectUri = `$${protocol}://$${baseUrl}/support/callback`;
    
    const authUrl = new URL(`https://login.microsoftonline.com/$${tenantId}/oauth2/v2.0/authorize`);
    authUrl.searchParams.set('client_id', clientId);
    authUrl.searchParams.set('response_type', 'code');
    authUrl.searchParams.set('redirect_uri', redirectUri);
    authUrl.searchParams.set('scope', 'User.Read');
    authUrl.searchParams.set('response_mode', 'query');
    authUrl.searchParams.set('state', 'support-login');

    console.log('✅ Redirecting to Microsoft OAuth:', authUrl.toString());
    
    return NextResponse.redirect(authUrl.toString());
    
  } catch (error) {
    console.error('💥 Error in OAuth redirect:', error);
    return NextResponse.json({ 
      error: 'OAuth redirect failed',
      message: error.message 
    }, { status: 500 });
  }
}
EOF

      # Create support callback route (OAuth response handler)
      cat > ./app-build/src/app/support/callback/route.js << 'EOF'
import { NextResponse } from 'next/server';

export async function GET(request) {
  try {
    console.log('🔄 SUPPORT CALLBACK: Processing OAuth response');
    
    const { searchParams } = new URL(request.url);
    const code = searchParams.get('code');
    const state = searchParams.get('state');
    const error = searchParams.get('error');
    
    if (error) {
      console.error('❌ OAuth error:', error);
      return NextResponse.redirect('/support?error=oauth_failed');
    }
    
    if (!code || state !== 'support-login') {
      console.error('❌ Invalid OAuth callback');
      return NextResponse.redirect('/support?error=invalid_callback');
    }

    // Exchange code for access token
    const clientId = process.env.AZURE_CLIENT_ID;
    const clientSecret = process.env.AZURE_CLIENT_SECRET;
    const tenantId = process.env.AZURE_TENANT_ID;
    
    const baseUrl = request.headers.get('host');
    const protocol = request.headers.get('x-forwarded-proto') || 'https';
    const redirectUri = `$${protocol}://$${baseUrl}/support/callback`;

    const tokenResponse = await fetch(`https://login.microsoftonline.com/$${tenantId}/oauth2/v2.0/token`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        client_id: clientId,
        client_secret: clientSecret,
        code: code,
        redirect_uri: redirectUri,
        grant_type: 'authorization_code'
      })
    });

    if (!tokenResponse.ok) {
      const errorData = await tokenResponse.text();
      console.error('❌ Token exchange failed:', errorData);
      return NextResponse.redirect('/support?error=token_failed');
    }

    const tokenData = await tokenResponse.json();
    const accessToken = tokenData.access_token;
    
    console.log('✅ OAuth access token obtained successfully');
    
    // Get basic user profile from Microsoft Graph (just for user ID)
    const graphResponse = await fetch('https://graph.microsoft.com/v1.0/me?$select=id,userPrincipalName,displayName', {
      headers: {
        'Authorization': 'Bearer ' + accessToken,
      }
    });

    if (!graphResponse.ok) {
      console.error('❌ Failed to get user profile');
      return NextResponse.redirect('/support?error=profile_failed');
    }

    const basicProfile = await graphResponse.json();
    console.log('✅ Basic user profile obtained:', basicProfile.userPrincipalName);
    
    // Store user info in session/memory for validation API (simplified approach)
    console.log('✅ OAuth authentication successful - redirecting to dashboard');
    
    // Redirect to dashboard with user info (no validation yet)
    const dashboardUrl = new URL('/support/dashboard', `$${protocol}://$${baseUrl}`);
    dashboardUrl.searchParams.set('user', basicProfile.displayName || basicProfile.userPrincipalName);
    dashboardUrl.searchParams.set('userId', basicProfile.id);
    
    return NextResponse.redirect(dashboardUrl.toString());

  } catch (error) {
    console.error('💥 Error in OAuth callback:', error);
    return NextResponse.redirect('/support?error=callback_failed');
  }
}
EOF

      # Create support dashboard (simplified with validation button)
      cat > ./app-build/src/app/support/dashboard/page.js << 'EOF'
'use client'

import { useSearchParams } from 'next/navigation';
import { Suspense, useState } from 'react';

function DashboardContent() {
  const searchParams = useSearchParams();
  const user = searchParams.get('user');
  const userId = searchParams.get('userId');
  
  const [loading, setLoading] = useState(false);
  const [validationResult, setValidationResult] = useState(null);

  const validateSupportAccess = async () => {
    if (!userId) {
      alert('Missing user ID. Please login again.');
      return;
    }

    setLoading(true);
    setValidationResult(null);

    try {
      const response = await fetch('/api/validate/support', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ userId: userId })
      });

      const result = await response.json();
      setValidationResult(result);
      
    } catch (error) {
      console.error('Validation error:', error);
      setValidationResult({
        success: false,
        message: 'Failed to validate access',
        error: error.message
      });
    }

    setLoading(false);
  };

  return (
    <div style={{ 
      minHeight: '100vh', 
      display: 'flex', 
      flexDirection: 'column',
      alignItems: 'center', 
      justifyContent: 'center',
      backgroundColor: '#f8f9fa',
      fontFamily: 'system-ui, sans-serif',
      padding: '2rem'
    }}>
      <div style={{
        backgroundColor: 'white',
        padding: '3rem',
        borderRadius: '12px',
        boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)',
        textAlign: 'center',
        maxWidth: '600px',
        width: '100%'
      }}>
        <h1 style={{ 
          color: '#2563eb', 
          fontSize: '2.5rem', 
          marginBottom: '1rem',
          fontWeight: 'bold'
        }}>
          🔧 Support Hub Dashboard
        </h1>
        
        <p style={{ 
          color: '#374151', 
          fontSize: '1.2rem',
          marginBottom: '2rem'
        }}>
          Welcome <strong>{user || 'User'}</strong>! 
        </p>

        <div style={{
          backgroundColor: '#f0f9ff',
          border: '1px solid #0ea5e9',
          borderRadius: '8px',
          padding: '1.5rem',
          marginBottom: '2rem'
        }}>
          <p style={{ 
            color: '#0c4a6e', 
            fontSize: '1rem',
            margin: '0',
            lineHeight: '1.6'
          }}>
            You have successfully authenticated with Microsoft OAuth. 
            <br />
            Click the button below to verify your Support Department access.
          </p>
        </div>

        {!validationResult && (
          <button 
            onClick={validateSupportAccess}
            disabled={loading}
            style={{
              backgroundColor: loading ? '#9ca3af' : '#059669',
              color: 'white',
              padding: '16px 32px',
              fontSize: '1.1rem',
              border: 'none',
              borderRadius: '8px',
              cursor: loading ? 'not-allowed' : 'pointer',
              fontWeight: '600',
              marginBottom: '2rem',
              minWidth: '200px'
            }}
          >
            {loading ? '🔄 Validating...' : '🔐 Access Restricted Content'}
          </button>
        )}

        {validationResult && (
          <div style={{
            backgroundColor: validationResult.success ? '#dcfce7' : '#fef2f2',
            border: '2px solid ' + (validationResult.success ? '#16a34a' : '#dc2626'),
            borderRadius: '8px',
            padding: '2rem',
            marginBottom: '2rem'
          }}>
            {validationResult.success ? (
              <>
                <h2 style={{ 
                  color: '#15803d', 
                  fontSize: '1.5rem',
                  marginBottom: '1rem',
                  fontWeight: 'bold'
                }}>
                  🎉 Access Granted!
                </h2>
                <div style={{
                  backgroundColor: '#1f2937',
                  color: '#f9fafb',
                  padding: '1rem',
                  borderRadius: '6px',
                  fontFamily: 'monospace',
                  fontSize: '1.1rem',
                  fontWeight: 'bold',
                  letterSpacing: '1px',
                  marginBottom: '1rem'
                }}>
                  🚩 {validationResult.flag}
                </div>
                <div style={{
                  backgroundColor: '#f3f4f6',
                  borderRadius: '8px',
                  padding: '1rem'
                }}>
                  <h3 style={{ color: '#374151', marginBottom: '0.5rem' }}>🏆 Challenge Completed!</h3>
                  <p style={{ 
                    color: '#6b7280',
                    lineHeight: '1.6',
                    margin: '0',
                    textAlign: 'center'
                  }}>
                    Congratulations! You have successfully completed this security challenge.
                  </p>
                </div>
              </>
            ) : (
              <>
                <h2 style={{ 
                  color: '#dc2626', 
                  fontSize: '1.5rem',
                  marginBottom: '1rem',
                  fontWeight: 'bold'
                }}>
                  ❌ Access Denied
                </h2>
                <p style={{ 
                  color: '#7f1d1d',
                  marginBottom: '1rem'
                }}>
                  {validationResult.message}
                </p>
                {validationResult.user && (
                  <div style={{
                    backgroundColor: '#f3f4f6',
                    borderRadius: '6px',
                    padding: '1rem',
                    textAlign: 'left'
                  }}>
                    <strong>Your Profile:</strong>
                    <br />
                    Department: {validationResult.user.department}
                    <br />
                    Required: Support
                  </div>
                )}
              </>
            )}
          </div>
        )}

        <div style={{ display: 'flex', gap: '1rem', justifyContent: 'center' }}>
          <button 
            onClick={() => window.location.href = '/support'}
            style={{
              backgroundColor: '#6b7280',
              color: 'white',
              padding: '10px 20px',
              fontSize: '0.9rem',
              border: 'none',
              borderRadius: '6px',
              cursor: 'pointer',
              fontWeight: '600'
            }}
          >
            🔧 Back to Support Hub
          </button>
          
          <button 
            onClick={() => window.location.href = '/'}
            style={{
              backgroundColor: '#2563eb',
              color: 'white',
              padding: '10px 20px',
              fontSize: '0.9rem',
              border: 'none',
              borderRadius: '6px',
              cursor: 'pointer',
              fontWeight: '600'
            }}
          >
            🏠 HR Onboarding
          </button>
        </div>
      </div>
    </div>
  );
}

export default function SupportDashboard() {
  return (
    <Suspense fallback={
      <div style={{ 
        minHeight: '100vh', 
        display: 'flex', 
        alignItems: 'center', 
        justifyContent: 'center' 
      }}>
        <p>Loading...</p>
      </div>
    }>
      <DashboardContent />
    </Suspense>
  );
}
EOF

      # Create support validation API endpoint
      cat > ./app-build/src/app/api/validate/support/route.js << 'EOF'
import { NextResponse } from 'next/server';

export async function POST(request) {
  try {
    console.log('🔄 SUPPORT VALIDATION: Request received');
    
    let body;
    try {
      body = await request.json();
    } catch (jsonError) {
      console.error('❌ Invalid JSON in request body:', jsonError.message);
      return NextResponse.json(
        { error: 'Invalid JSON format', details: jsonError.message },
        { status: 400 }
      );
    }

    const { userId } = body;
    
    if (!userId) {
      console.error('❌ Missing userId in request');
      return NextResponse.json(
        { error: 'userId is required' },
        { status: 400 }
      );
    }

    console.log(`🔍 Validating support access for user: $${userId}`);

    // Get Azure AD credentials from environment
    const clientId = process.env.AZURE_CLIENT_ID;
    const clientSecret = process.env.AZURE_CLIENT_SECRET;
    const tenantId = process.env.AZURE_TENANT_ID;

    if (!clientId || !clientSecret || !tenantId) {
      console.error('❌ Missing Azure AD configuration');
      return NextResponse.json(
        { error: 'Azure AD configuration missing' },
        { status: 500 }
      );
    }

    // Get application token for Microsoft Graph API
    console.log('🔄 Obtaining application token...');
    
    const tokenResponse = await fetch(`https://login.microsoftonline.com/$${tenantId}/oauth2/v2.0/token`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        client_id: clientId,
        client_secret: clientSecret,
        scope: 'https://graph.microsoft.com/.default',
        grant_type: 'client_credentials'
      })
    });

    if (!tokenResponse.ok) {
      const errorData = await tokenResponse.text();
      console.error('❌ Application token request failed:', errorData);
      return NextResponse.json(
        { error: 'Failed to obtain application token', details: errorData },
        { status: 500 }
      );
    }

    const tokenData = await tokenResponse.json();
    const accessToken = tokenData.access_token;
    
    console.log('✅ Application token obtained successfully');

    // Query user details from Microsoft Graph API
    const selectFields = 'id,displayName,userPrincipalName,department,jobTitle';
    const userDetailsUrl = 'https://graph.microsoft.com/v1.0/users/' + userId + '?$select=' + selectFields;
    console.log('🔍 Querying user details URL:', userDetailsUrl);
    
    const userResponse = await fetch(userDetailsUrl, {
      headers: {
        'Authorization': 'Bearer ' + accessToken,
      }
    });

    if (!userResponse.ok) {
      const errorData = await userResponse.text();
      console.error('❌ Failed to get user details:', errorData);
      return NextResponse.json(
        { error: 'Failed to get user details', details: errorData },
        { status: userResponse.status }
      );
    }

    const userProfile = await userResponse.json();
    console.log('✅ User profile obtained:', {
      id: userProfile.id,
      userPrincipalName: userProfile.userPrincipalName,
      department: userProfile.department || 'none'
    });

    // Validate if user has Support department
    const department = userProfile.department || '';
    
    if (department.toLowerCase() === 'support') {
      console.log('✅ User has Support department - access granted');
      
      return NextResponse.json({
        success: true,
        message: 'Support access granted',
        user: {
          id: userProfile.id,
          displayName: userProfile.displayName,
          userPrincipalName: userProfile.userPrincipalName,
          department: userProfile.department,
          jobTitle: userProfile.jobTitle
        },
        flag: 'CLD[b7d9f3e2-4a8c-4f1e-9b6d-2e5a8c7f3b9d]',
        access: 'granted'
      });
    } else {
      console.log(`❌ User department '$${department}' is not 'support' - access denied`);
      
      return NextResponse.json({
        success: false,
        message: 'Access denied: Support Department personnel only',
        user: {
          id: userProfile.id,
          displayName: userProfile.displayName,
          userPrincipalName: userProfile.userPrincipalName,
          department: department || 'none',
          jobTitle: userProfile.jobTitle
        },
        access: 'denied',
        reason: `Department '$${department}' does not have access to Support Hub`
      }, { status: 403 });
    }

  } catch (error) {
    console.error('💥 Error in support validation:', error);
    return NextResponse.json({ 
      error: 'Internal server error',
      message: error.message 
    }, { status: 500 });
  }
}
EOF

      # Create version API endpoint
      mkdir -p ./app-build/src/app/api/version
      cat > ./app-build/src/app/api/version/route.js << 'EOF'
import { NextResponse } from 'next/server'

export async function GET() {
  try {
    // Get versions from package.json and process.version
    const packageJson = require('../../../../package.json')
    
    const versionInfo = {
      nodejs: process.version,
      nextjs: packageJson.dependencies.next,
      application: {
        name: packageJson.name,
        version: packageJson.version
      },
      timestamp: new Date().toISOString()
    }

    return NextResponse.json(versionInfo, {
      status: 200,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Cache-Control': 'no-cache'
      }
    })
    
  } catch (error) {
    return NextResponse.json(
      { 
        error: 'Unable to retrieve version information',
        message: error.message 
      },
      { status: 500 }
    )
  }
}
EOF

      # Create layout
      cat > ./app-build/src/app/layout.js << 'EOF'
import './globals.css'

export const metadata = {
  title: 'MediCloudX Workforce Onboarding',
  description: 'Automated Clinical & Administrative Staff Registration System',
}

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
EOF

      cat > ./app-build/src/app/globals.css << 'EOF'
* {
  box-sizing: border-box;
  padding: 0;
  margin: 0;
}

html,
body {
  max-width: 100vw;
  overflow-x: hidden;
}

body {
  color: rgb(var(--foreground-rgb));
  background: linear-gradient(
      to bottom,
      transparent,
      rgb(var(--background-end-rgb))
    )
    rgb(var(--background-start-rgb));
}

a {
  color: inherit;
  text-decoration: none;
}

a:hover {
  text-decoration: underline;
}

@media (prefers-color-scheme: dark) {
  html {
    color-scheme: dark;
  }
}
EOF

      # Create docs API documentation endpoint
      cat > ./app-build/src/app/docs/route.js << 'EOF'
import { NextResponse } from 'next/server';

export async function GET() {
  try {
    const apiDocs = {
      "openapi": "3.0.0",
      "info": {
        "title": "MediCloudX Workforce Onboarding API",
        "version": "1.0.0",
        "description": "Internal API for healthcare workforce management"
      },
      "servers": [
        {
          "url": "/",
          "description": "Current server"
        }
      ],
      "paths": {
        "/api/version": {
          "get": {
            "summary": "Get API version information",
            "description": "Returns current API and system version details",
            "responses": {
              "200": {
                "description": "Version information",
                "content": {
                  "application/json": {
                    "schema": {
                      "type": "object",
                      "properties": {
                        "version": { "type": "string" },
                        "nodejs": { "type": "string" },
                        "environment": { "type": "string" }
                      }
                    }
                  }
                }
              }
            }
          }
        },
        "/api/create-user": {
          "post": {
            "summary": "Create new user account",
            "description": "Creates a new user in the workforce management system",
            "requestBody": {
              "required": true,
              "content": {
                "application/json": {
                  "schema": {
                    "type": "object",
                    "properties": {}
                  }
                }
              }
            },
            "responses": {
              "200": {
                "description": "User created successfully"
              },
              "401": {
                "description": "Authentication required"
              }
            }
          }
        },
        "/api/update-departament": {
          "post": {
            "summary": "Update user department assignment",
            "description": "Updates the department assignment for an existing user",
            "requestBody": {
              "required": true,
              "content": {
                "application/json": {
                  "schema": {
                    "type": "object",
                    "required": ["id", "departament"],
                    "properties": {
                      "id": {
                        "type": "string",
                        "description": "User ID to update"
                      },
                      "departament": {
                        "type": "string",
                        "description": "New department assignment"
                      }
                    }
                  }
                }
              }
            },
            "responses": {
              "200": {
                "description": "Department updated successfully"
              },
              "401": {
                "description": "Authentication required"
              },
              "404": {
                "description": "User not found"
              }
            }
          }
        }
      },
      "components": {
        "securitySchemes": {
          "bearerAuth": {
            "type": "http",
            "scheme": "bearer"
          }
        }
      },
      "security": [
        {
          "bearerAuth": []
        }
      ]
    };

    return NextResponse.json(apiDocs, {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      }
    });

  } catch (error) {
    console.error('Error serving API documentation:', error);
    return NextResponse.json({ 
      error: 'Failed to load API documentation' 
    }, { status: 500 });
  }
}
EOF

      # Build the container with docker buildx
      cd ./app-build
      
      # Login to ACR
      az acr login --name ${azurerm_container_registry.medicloudx_acr.name}
      
      # Build and tag image for linux/amd64 platform (Azure App Service)
      docker buildx build --platform linux/amd64 -t ${azurerm_container_registry.medicloudx_acr.login_server}/medicloudx-onboarding:latest .
      docker build --platform linux/amd64 -t ${azurerm_container_registry.medicloudx_acr.login_server}/medicloudx-onboarding:latest .
      
      # Push image
      docker push ${azurerm_container_registry.medicloudx_acr.login_server}/medicloudx-onboarding:latest
      
      # Cleanup
      rm -rf ./app-build
    EOT
  }
}
