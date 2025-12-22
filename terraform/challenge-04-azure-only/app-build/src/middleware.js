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
