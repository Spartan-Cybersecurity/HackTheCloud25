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
