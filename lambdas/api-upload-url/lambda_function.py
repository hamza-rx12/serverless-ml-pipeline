import json
import boto3
import os
from datetime import datetime
import uuid

s3_client = boto3.client('s3')

BUCKET_NAME = os.environ.get('S3_BUCKET_NAME')
UPLOAD_EXPIRATION = 300  # 5 minutes

def lambda_handler(event, context):
    """
    Generate presigned URL for direct S3 upload
    """
    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        file_name = body.get('fileName')
        file_type = body.get('fileType')

        if not file_name or not file_type:
            return {
                'statusCode': 400,
                'headers': {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type',
                    'Access-Control-Allow-Methods': 'POST,OPTIONS'
                },
                'body': json.dumps({
                    'error': 'fileName and fileType are required'
                })
            }

        # Validate file type
        valid_types = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/bmp', 'image/webp']
        if file_type not in valid_types:
            return {
                'statusCode': 400,
                'headers': {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type',
                    'Access-Control-Allow-Methods': 'POST,OPTIONS'
                },
                'body': json.dumps({
                    'error': 'Invalid file type. Must be JPEG, PNG, GIF, BMP, or WEBP'
                })
            }

        # Generate unique file name to avoid conflicts
        file_extension = file_name.split('.')[-1] if '.' in file_name else 'jpg'
        unique_id = str(uuid.uuid4())[:8]
        timestamp = datetime.now().strftime('%Y%m%d-%H%M%S')
        s3_key = f"{timestamp}-{unique_id}-{file_name}"

        # Generate presigned URL
        presigned_url = s3_client.generate_presigned_url(
            'put_object',
            Params={
                'Bucket': BUCKET_NAME,
                'Key': s3_key,
                'ContentType': file_type
            },
            ExpiresIn=UPLOAD_EXPIRATION
        )

        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'POST,OPTIONS'
            },
            'body': json.dumps({
                'uploadUrl': presigned_url,
                'imageId': s3_key,
                'expiresIn': UPLOAD_EXPIRATION
            })
        }

    except Exception as e:
        print(f"Error generating presigned URL: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'POST,OPTIONS'
            },
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e)
            })
        }
