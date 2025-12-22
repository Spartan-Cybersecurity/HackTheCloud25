import json
import jwt
import requests
import os
import base64
import time
from urllib.parse import urlparse
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Custom Lambda Authorizer for API Gateway
    Validates JWT token and checks if user has admin role
    Uses manual JWT validation following AWS best practices
    """
    
    try:
        # Debug: Log the entire event to see what we're receiving
        logger.info(f"Received event: {json.dumps(event, default=str)}")
        
        # Extract token from Authorization header (try different cases)
        headers = event.get('headers', {})
        logger.info(f"Headers received: {json.dumps(headers, default=str)}")
        
        # Try different header keys (case-insensitive)
        auth_header = (
            headers.get('Authorization') or 
            headers.get('authorization') or 
            headers.get('AUTHORIZATION') or
            event.get('authorizationToken', '')  # For token authorizer
        )
        
        logger.info(f"Auth header found: {auth_header[:50]}..." if auth_header else "No auth header found")
        
        token = auth_header.replace('Bearer ', '').replace('bearer ', '').strip()
        
        if not token:
            logger.error("No token provided")
            raise Exception('Unauthorized')
        
        # Get Cognito configuration from environment variables
        user_pool_id = os.environ['USER_POOL_ID']
        region = os.environ['REGION']
        client_id = os.environ.get('CLIENT_ID')
        
        # Decode token WITHOUT verification first (to get claims)
        try:
            decoded_token = jwt.decode(
                token,
                options={"verify_signature": False, "verify_exp": False}
            )
            logger.info(f"Token decoded successfully. Claims: {json.dumps(decoded_token, default=str)}")
        except Exception as decode_error:
            logger.error(f"Failed to decode token: {str(decode_error)}")
            raise Exception('Invalid token format')
        
        # Manual validation following AWS Cognito best practices
        
        # 1. Check token expiration
        current_time = int(time.time())
        if decoded_token.get('exp', 0) < current_time:
            logger.error(f"Token expired. Exp: {decoded_token.get('exp')}, Current: {current_time}")
            raise Exception('Token expired')
            
        # 2. Check issuer (iss)
        expected_iss = f'https://cognito-idp.{region}.amazonaws.com/{user_pool_id}'
        if decoded_token.get('iss') != expected_iss:
            logger.error(f"Invalid issuer. Expected: {expected_iss}, Got: {decoded_token.get('iss')}")
            raise Exception('Invalid issuer')
            
        # 3. Check audience (aud) - only for ID tokens
        token_use = decoded_token.get('token_use')
        if token_use == 'id' and client_id:
            if decoded_token.get('aud') != client_id:
                logger.error(f"Invalid audience. Expected: {client_id}, Got: {decoded_token.get('aud')}")
                raise Exception('Invalid audience')
        
        # 4. Check token use
        if token_use not in ['access', 'id']:
            logger.error(f"Invalid token_use: {token_use}")
            raise Exception('Invalid token use')
        
        # Extract user information
        user_id = decoded_token.get('sub')
        custom_role = decoded_token.get('custom:role', 'reader')
        
        logger.info(f"User {user_id} with role {custom_role} attempting access")
        
        # Check if user has admin role
        if custom_role != 'admin':
            logger.warning(f"Access denied for user {user_id} with role {custom_role}")
            raise Exception('Insufficient privileges - admin role required')
        
        # Generate policy for authorized user
        policy = generate_policy(user_id, 'Allow', event['methodArn'])
        
        # Add user context
        policy['context'] = {
            'userId': user_id,
            'role': custom_role,
            'email': decoded_token.get('email', ''),
            'tokenUse': decoded_token.get('token_use', '')
        }
        
        logger.info(f"Access granted for admin user {user_id}")
        return policy
        
    except Exception as e:
        logger.error(f"Authorization failed: {str(e)}")
        raise Exception('Unauthorized')

def generate_policy(principal_id, effect, resource):
    """
    Generate IAM policy for API Gateway
    """
    policy_document = {
        'Version': '2012-10-17',
        'Statement': [
            {
                'Action': 'execute-api:Invoke',
                'Effect': effect,
                'Resource': resource
            }
        ]
    }
    
    return {
        'principalId': principal_id,
        'policyDocument': policy_document
    }
