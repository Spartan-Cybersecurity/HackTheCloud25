import json
import boto3
import logging
import os
from botocore.exceptions import ClientError

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize DynamoDB client
dynamodb = boto3.client('dynamodb')

def lambda_handler(event, context):
    """
    Lambda function to read patient data from DynamoDB
    Only accessible to users with admin role (validated by authorizer)
    """
    
    try:
        # Get table name from environment variable
        table_name = os.environ['DYNAMODB_TABLE_NAME']
        
        # Extract user context from authorizer
        user_context = event.get('requestContext', {}).get('authorizer', {})
        user_id = user_context.get('userId', 'unknown')
        user_role = user_context.get('role', 'unknown')
        
        logger.info(f"Admin user {user_id} accessing patient data")
        
        # Get query parameters
        query_params = event.get('queryStringParameters') or {}
        department = query_params.get('department')
        limit = int(query_params.get('limit', 100))
        
        # Scan DynamoDB table
        scan_params = {
            'TableName': table_name,
            'Limit': limit
        }
        
        # If department filter is provided, use GSI
        if department:
            scan_params = {
                'TableName': table_name,
                'IndexName': 'DepartmentIndex',
                'Limit': limit,
                'FilterExpression': '#dept = :dept',
                'ExpressionAttributeNames': {
                    '#dept': 'department'
                },
                'ExpressionAttributeValues': {
                    ':dept': {'S': department}
                }
            }
            response = dynamodb.query(**scan_params)
        else:
            response = dynamodb.scan(**scan_params)
        
        # Process and format the response
        items = []
        for item in response.get('Items', []):
            formatted_item = {}
            for key, value in item.items():
                if 'S' in value:
                    formatted_item[key] = value['S']
                elif 'N' in value:
                    formatted_item[key] = value['N']
                else:
                    formatted_item[key] = str(value)
            items.append(formatted_item)
        
        # Sort items by created_at
        items.sort(key=lambda x: x.get('created_at', ''), reverse=True)
        
        logger.info(f"Retrieved {len(items)} patient records for user {user_id}")
        
        # Return response
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization'
            },
            'body': json.dumps({
                'success': True,
                'data': items,
                'count': len(items),
                'message': f'Retrieved patient records for MediCloudX Health System',
                'requestedBy': user_id,
                'timestamp': context.aws_request_id
            })
        }
        
    except ClientError as e:
        logger.error(f"DynamoDB error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'success': False,
                'error': 'Database access error',
                'message': 'Failed to retrieve patient data'
            })
        }
        
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'success': False,
                'error': 'Internal server error',
                'message': 'An unexpected error occurred'
            })
        }
