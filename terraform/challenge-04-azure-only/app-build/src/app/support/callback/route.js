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
    const redirectUri = `${protocol}://${baseUrl}/support/callback`;

    const tokenResponse = await fetch(`https://login.microsoftonline.com/${tenantId}/oauth2/v2.0/token`, {
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
    const dashboardUrl = new URL('/support/dashboard', `${protocol}://${baseUrl}`);
    dashboardUrl.searchParams.set('user', basicProfile.displayName || basicProfile.userPrincipalName);
    dashboardUrl.searchParams.set('userId', basicProfile.id);
    
    return NextResponse.redirect(dashboardUrl.toString());

  } catch (error) {
    console.error('💥 Error in OAuth callback:', error);
    return NextResponse.redirect('/support?error=callback_failed');
  }
}
