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
