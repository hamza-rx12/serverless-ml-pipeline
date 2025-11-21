import json
import boto3
import os
from boto3.dynamodb.conditions import Key
from decimal import Decimal
from urllib.parse import unquote

dynamodb = boto3.resource('dynamodb')
s3_client = boto3.client('s3')

# Map service prefixes to table names
SERVICE_TABLES = {
    'text-detection': os.environ.get('TEXT_DETECTION_TABLE', 'text-detection-results'),
    'face-detection': os.environ.get('FACE_DETECTION_TABLE', 'face-detection-results'),
    'object-detection': os.environ.get('OBJECT_DETECTION_TABLE', 'object-detection-results')
}

def get_table_for_image(image_id):
    """Determine which table to query based on image_id prefix"""
    # Decode URL-encoded imageId (e.g., text-detection%2F -> text-detection/)
    decoded_image_id = unquote(image_id)

    for service, table_name in SERVICE_TABLES.items():
        if decoded_image_id.startswith(f"{service}/"):
            return dynamodb.Table(table_name), service, decoded_image_id
    # Default to object-detection for backward compatibility
    return dynamodb.Table(SERVICE_TABLES['object-detection']), 'object-detection', decoded_image_id

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
            service = query_parameters.get('service')  # NEW: Optional service filter
            return list_recent_uploads(limit, headers, service)

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
        table, service, decoded_image_id = get_table_for_image(image_id)
        print(f"Querying {service} table for image_id: {decoded_image_id}")

        # Query by image_id (partition key) using DECODED imageId
        # Get the most recent result for this image
        response = table.query(
            KeyConditionExpression=Key('image_id').eq(decoded_image_id),
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


def list_recent_uploads(limit, headers, service_filter=None):
    """List recent uploads across all service tables or filtered by service"""
    try:
        all_items = []

        # Determine which services to query
        services_to_query = SERVICE_TABLES.items()
        if service_filter and service_filter in SERVICE_TABLES:
            # Filter to only the requested service
            services_to_query = [(service_filter, SERVICE_TABLES[service_filter])]
            print(f"Filtering results for service: {service_filter}")

        # Query service table(s)
        for service, table_name in services_to_query:
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

        # Return summary info for each item with thumbnail URLs
        results = []
        for item in items:
            result_item = {
                'image_id': item.get('image_id'),
                'timestamp': item.get('timestamp'),
                'status': item.get('status', 'unknown'),
                'service': item.get('service'),
                'bucket': item.get('bucket'),
                'key': item.get('key'),
                'analysis_summary': item.get('analysis_summary', {})
            }

            # Generate presigned URL for thumbnail if it exists
            if item.get('key'):
                thumbnail_key = f"thumbnails/{item.get('key')}"
                try:
                    # Check if thumbnail exists and generate presigned URL
                    result_item['thumbnail_url'] = s3_client.generate_presigned_url(
                        'get_object',
                        Params={
                            'Bucket': item.get('bucket'),
                            'Key': thumbnail_key
                        },
                        ExpiresIn=3600  # 1 hour
                    )
                except Exception as e:
                    # Thumbnail might not exist yet
                    result_item['thumbnail_url'] = None

            results.append(result_item)

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
