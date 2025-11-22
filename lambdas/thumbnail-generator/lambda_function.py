import json
import boto3
import os
from io import BytesIO
from PIL import Image
from urllib.parse import unquote_plus

s3_client = boto3.client('s3')

THUMBNAIL_SIZE = (200, 200)
THUMBNAIL_PREFIX = 'thumbnails/'

def lambda_handler(event, context):
    """
    Generate thumbnail for uploaded image
    Triggered by EventBridge on S3 upload
    """
    try:
        # Get the S3 bucket and key from EventBridge event
        detail = event['detail']
        bucket = detail['bucket']['name']
        key = detail['object']['key']

        print(f"Processing thumbnail for: s3://{bucket}/{key}")

        # Skip if this is already a thumbnail
        if key.startswith(THUMBNAIL_PREFIX):
            print("Skipping thumbnail of thumbnail")
            return {
                'statusCode': 200,
                'body': json.dumps('Skipped thumbnail generation')
            }

        # Download the original image
        response = s3_client.get_object(Bucket=bucket, Key=key)
        image_content = response['Body'].read()

        # Open image with PIL
        image = Image.open(BytesIO(image_content))

        # Convert RGBA to RGB if necessary (for JPEG compatibility)
        if image.mode in ('RGBA', 'LA', 'P'):
            background = Image.new('RGB', image.size, (255, 255, 255))
            if image.mode == 'P':
                image = image.convert('RGBA')
            background.paste(image, mask=image.split()[-1] if image.mode == 'RGBA' else None)
            image = background

        # Create thumbnail (maintains aspect ratio)
        image.thumbnail(THUMBNAIL_SIZE, Image.Resampling.LANCZOS)

        # Save thumbnail to BytesIO
        thumbnail_io = BytesIO()
        image.save(thumbnail_io, format='JPEG', quality=85, optimize=True)
        thumbnail_io.seek(0)

        # Generate thumbnail key (same path structure but in thumbnails/ prefix)
        thumbnail_key = f"{THUMBNAIL_PREFIX}{key}"

        # Upload thumbnail to S3
        s3_client.put_object(
            Bucket=bucket,
            Key=thumbnail_key,
            Body=thumbnail_io.getvalue(),
            ContentType='image/jpeg',
            CacheControl='max-age=31536000'  # Cache for 1 year
        )

        print(f"Thumbnail created: s3://{bucket}/{thumbnail_key}")

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Thumbnail generated successfully',
                'thumbnail_key': thumbnail_key
            })
        }

    except Exception as e:
        print(f"Error generating thumbnail: {str(e)}")
        # Don't fail the pipeline, just log the error
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }
