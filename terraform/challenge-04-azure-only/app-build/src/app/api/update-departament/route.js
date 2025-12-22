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
    console.log(`🔄 Updating user ${id} department to: ${departament}`);
    
    const graphResponse = await fetch(`https://graph.microsoft.com/v1.0/users/${id}`, {
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
