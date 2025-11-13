import json
import boto3

rekognition = boto3.client('rekognition')

def handler(event, context):
    """
    Object Detector Lambda - Uses Rekognition to detect objects/labels in image
    """
    try:
        print(f"Object detection started for: {json.dumps(event)}")

        bucket = event['bucket']
        key = event['key']

        # Call Rekognition detect_labels
        response = rekognition.detect_labels(
            Image={
                'S3Object': {
                    'Bucket': bucket,
                    'Name': key
                }
            },
            MaxLabels=10,
            MinConfidence=70
        )

        # Extract and format labels
        labels = []
        for label in response.get('Labels', []):
            labels.append({
                'name': label['Name'],
                'confidence': round(label['Confidence'], 2),
                'categories': [cat['Name'] for cat in label.get('Categories', [])]
            })

        print(f"Detected {len(labels)} objects")

        return {
            'statusCode': 200,
            'detection_type': 'objects',
            'objects': labels,
            'count': len(labels)
        }

    except Exception as e:
        print(f"Error in object detection: {str(e)}")
        return {
            'statusCode': 500,
            'detection_type': 'objects',
            'error': str(e),
            'objects': [],
            'count': 0
        }
