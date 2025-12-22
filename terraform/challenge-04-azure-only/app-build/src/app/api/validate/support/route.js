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

    console.log(`🔍 Validating support access for user: ${userId}`);

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
    
    const tokenResponse = await fetch(`https://login.microsoftonline.com/${tenantId}/oauth2/v2.0/token`, {
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
      console.log(`❌ User department '${department}' is not 'support' - access denied`);
      
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
        reason: `Department '${department}' does not have access to Support Hub`
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
