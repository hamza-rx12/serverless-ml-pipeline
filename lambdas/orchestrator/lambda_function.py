import json
import os
from urllib.parse import unquote_plus

# Supported image formats
SUPPORTED_FORMATS = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp']

def handler(event, context):
    """
    Orchestrator Lambda - Validates S3 event and image format
    Triggered by Step Functions with S3 event details
    """
    try:
        print(f"Received event: {json.dumps(event)}")

        # Extract S3 details from event
        # Event can come from EventBridge or direct invocation
        if 'detail' in event:
            # EventBridge format
            bucket = event['detail']['bucket']['name']
            key = unquote_plus(event['detail']['object']['key'])
        else:
            # Direct format (for testing)
            bucket = event.get('bucket')
            key = event.get('key')

        if not bucket or not key:
            raise ValueError("Missing bucket or key in event")

        print(f"Processing image: s3://{bucket}/{key}")

        # Validate file extension
        file_extension = os.path.splitext(key.lower())[1]
        if file_extension not in SUPPORTED_FORMATS:
            return {
                'statusCode': 400,
                'valid': False,
                'error': f"Unsupported file format: {file_extension}",
                'message': f"Supported formats: {', '.join(SUPPORTED_FORMATS)}"
            }

        # Return validated image info for next step
        return {
            'statusCode': 200,
            'valid': True,
            'bucket': bucket,
            'key': key,
            'image_id': key,
            'file_extension': file_extension
        }

    except Exception as e:
        print(f"Error in orchestrator: {str(e)}")
        return {
            'statusCode': 500,
            'valid': False,
            'error': str(e),
            'message': 'Failed to validate image'
        }
