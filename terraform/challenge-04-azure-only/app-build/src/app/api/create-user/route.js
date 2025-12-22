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
