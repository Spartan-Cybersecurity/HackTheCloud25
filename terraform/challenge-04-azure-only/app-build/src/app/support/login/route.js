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
    const redirectUri = `${protocol}://${baseUrl}/support/callback`;
    
    const authUrl = new URL(`https://login.microsoftonline.com/${tenantId}/oauth2/v2.0/authorize`);
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
