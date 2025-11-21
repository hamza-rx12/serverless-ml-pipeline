import json
import boto3
import os
from boto3.dynamodb.conditions import Key
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')

# Map service prefixes to table names
SERVICE_TABLES = {
    'text-detection': os.environ.get('TEXT_DETECTION_TABLE', 'text-detection-results'),
    'face-detection': os.environ.get('FACE_DETECTION_TABLE', 'face-detection-results'),
    'object-detection': os.environ.get('OBJECT_DETECTION_TABLE', 'object-detection-results')
}

def get_table_for_image(image_id):
    """Determine which table to query based on image_id prefix"""
    for service, table_name in SERVICE_TABLES.items():
        if image_id.startswith(f"{service}/"):
            return dynamodb.Table(table_name), service
    # Default to object-detection for backward compatibility
    return dynamodb.Table(SERVICE_TABLES['object-detection']), 'object-detection'

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
        # Determine which table to query based on image_id prefix
        table, service = get_table_for_image(image_id)
        print(f"Querying {service} table for image_id: {image_id}")

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
                    'service': service,
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
    """List recent uploads across all service tables"""
    try:
        all_items = []

        # Query all service tables
        for service, table_name in SERVICE_TABLES.items():
            try:
                table = dynamodb.Table(table_name)
                response = table.scan(Limit=limit)
                items = response.get('Items', [])
                # Add service info to each item
                for item in items:
                    item['service'] = service
                all_items.extend(items)
            except Exception as e:
                print(f"Error scanning {service} table: {str(e)}")
                # Continue with other tables even if one fails
                continue

        items = all_items

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
