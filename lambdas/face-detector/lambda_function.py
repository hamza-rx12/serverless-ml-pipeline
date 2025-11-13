import json
import boto3

rekognition = boto3.client('rekognition')

def handler(event, context):
    """
    Face Detector Lambda - Uses Rekognition to detect faces and attributes
    """
    try:
        print(f"Face detection started for: {json.dumps(event)}")

        bucket = event['bucket']
        key = event['key']

        # Call Rekognition detect_faces
        response = rekognition.detect_faces(
            Image={
                'S3Object': {
                    'Bucket': bucket,
                    'Name': key
                }
            },
            Attributes=['ALL']  # Get all face attributes
        )

        # Extract and format face details
        faces = []
        for face_detail in response.get('FaceDetails', []):
            face_info = {
                'confidence': round(face_detail['Confidence'], 2),
                'age_range': {
                    'low': face_detail.get('AgeRange', {}).get('Low'),
                    'high': face_detail.get('AgeRange', {}).get('High')
                },
                'gender': {
                    'value': face_detail.get('Gender', {}).get('Value'),
                    'confidence': round(face_detail.get('Gender', {}).get('Confidence', 0), 2)
                },
                'emotions': []
            }

            # Extract emotions
            for emotion in face_detail.get('Emotions', []):
                face_info['emotions'].append({
                    'type': emotion['Type'],
                    'confidence': round(emotion['Confidence'], 2)
                })

            # Sort emotions by confidence
            face_info['emotions'].sort(key=lambda x: x['confidence'], reverse=True)

            faces.append(face_info)

        print(f"Detected {len(faces)} faces")

        return {
            'statusCode': 200,
            'detection_type': 'faces',
            'faces': faces,
            'count': len(faces)
        }

    except Exception as e:
        print(f"Error in face detection: {str(e)}")
        return {
            'statusCode': 500,
            'detection_type': 'faces',
            'error': str(e),
            'faces': [],
            'count': 0
        }
