import json
import boto3

rekognition = boto3.client('rekognition')

def handler(event, context):
    """
    Content Moderator Lambda - Uses Rekognition to detect inappropriate content
    """
    try:
        print(f"Content moderation started for: {json.dumps(event)}")

        bucket = event['bucket']
        key = event['key']

        # Call Rekognition detect_moderation_labels
        response = rekognition.detect_moderation_labels(
            Image={
                'S3Object': {
                    'Bucket': bucket,
                    'Name': key
                }
            },
            MinConfidence=60
        )

        # Extract and format moderation labels
        moderation_labels = []
        for label in response.get('ModerationLabels', []):
            moderation_labels.append({
                'name': label['Name'],
                'parent_name': label.get('ParentName', ''),
                'confidence': round(label['Confidence'], 2)
            })

        # Determine if content is safe
        is_safe = len(moderation_labels) == 0

        print(f"Content moderation complete. Safe: {is_safe}, Flags: {len(moderation_labels)}")

        return {
            'statusCode': 200,
            'detection_type': 'moderation',
            'is_safe': is_safe,
            'moderation_labels': moderation_labels,
            'flags_count': len(moderation_labels)
        }

    except Exception as e:
        print(f"Error in content moderation: {str(e)}")
        return {
            'statusCode': 500,
            'detection_type': 'moderation',
            'error': str(e),
            'is_safe': None,
            'moderation_labels': [],
            'flags_count': 0
        }
