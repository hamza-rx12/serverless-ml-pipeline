import json
import boto3
import os
from boto3.dynamodb.conditions import Key
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('DYNAMODB_TABLE_NAME')
table = dynamodb.Table(table_name)

class DecimalEncoder(json.JSONEncoder):
    """Helper class to convert Decimal objects to float for JSON serialization"""
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

def lambda_handler(event, context):
    """
    Get analysis results from DynamoDB
    Supports:
    - GET /results/{imageId} - Get specific image results
    - GET /results?limit=N - List recent uploads
    """
    try:
        http_method = event.get('httpMethod')
        path_parameters = event.get('pathParameters') or {}
        query_parameters = event.get('queryStringParameters') or {}

        # CORS headers
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Methods': 'GET,OPTIONS'
        }

        # Handle OPTIONS request for CORS
        if http_method == 'OPTIONS':
            return {
                'statusCode': 200,
                'headers': headers,
                'body': ''
            }

        # Get specific image results
        if path_parameters.get('imageId'):
            image_id = path_parameters['imageId']
            return get_image_results(image_id, headers)

        # List recent uploads
        else:
            limit = int(query_parameters.get('limit', 20))
            return list_recent_uploads(limit, headers)

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e)
            }, cls=DecimalEncoder)
        }


def get_image_results(image_id, headers):
    """Get results for a specific image"""
    try:
        # Query by image_id (partition key)
        # Get the most recent result for this image
        response = table.query(
            KeyConditionExpression=Key('image_id').eq(image_id),
            ScanIndexForward=False,  # Sort by timestamp descending
            Limit=1
        )

        if not response['Items']:
            # Image not found yet - it might be processing
            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps({
                    'image_id': image_id,
                    'status': 'processing',
                    'message': 'Analysis in progress'
                }, cls=DecimalEncoder)
            }

        item = response['Items'][0]

        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps(item, cls=DecimalEncoder)
        }

    except Exception as e:
        print(f"Error getting image results: {str(e)}")
        raise


def list_recent_uploads(limit, headers):
    """List recent uploads (scan table)"""
    try:
        # Scan the table to get recent items
        # Note: In production, you might want to use a GSI with timestamp as partition key
        response = table.scan(
            Limit=limit
        )

        items = response.get('Items', [])

        # Sort by timestamp (most recent first)
        items.sort(key=lambda x: x.get('timestamp', ''), reverse=True)

        # Return summary info for each item
        results = []
        for item in items:
            results.append({
                'image_id': item.get('image_id'),
                'timestamp': item.get('timestamp'),
                'status': item.get('status', 'unknown'),
                'bucket': item.get('bucket'),
                'key': item.get('key'),
                'analysis_summary': item.get('analysis_summary', {})
            })

        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({
                'items': results,
                'count': len(results)
            }, cls=DecimalEncoder)
        }

    except Exception as e:
        print(f"Error listing uploads: {str(e)}")
        raise
