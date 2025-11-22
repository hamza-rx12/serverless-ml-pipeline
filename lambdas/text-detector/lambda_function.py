import json
import boto3
import os

rekognition = boto3.client('rekognition')

def handler(event, context):
    """
    Text Detection Lambda - Extracts text from images using AWS Rekognition
    Uses detect_text API for OCR capabilities
    """
    try:
        print(f"Text detection event: {json.dumps(event, default=str)}")

        # Extract S3 details from Step Functions input
        bucket = event.get('bucket')
        key = event.get('key')
        image_id = event.get('image_id')

        if not bucket or not key:
            raise ValueError("Missing bucket or key in event")

        print(f"Detecting text in image: s3://{bucket}/{key}")

        # Call Rekognition detect_text API
        response = rekognition.detect_text(
            Image={
                'S3Object': {
                    'Bucket': bucket,
                    'Name': key
                }
            }
        )

        # Process text detections
        text_detections = response.get('TextDetections', [])

        # Separate LINE and WORD level detections
        lines = []
        words = []

        for detection in text_detections:
            text_data = {
                'text': detection.get('DetectedText'),
                'confidence': detection.get('Confidence'),
                'type': detection.get('Type'),
                'id': detection.get('Id')
            }

            if detection.get('Type') == 'LINE':
                lines.append(text_data)
            elif detection.get('Type') == 'WORD':
                words.append(text_data)

        # Extract full text (lines only, in order)
        full_text = ' '.join([line['text'] for line in lines])

        result = {
            'text': {
                'lines': lines,
                'words': words,
                'full_text': full_text,
                'line_count': len(lines),
                'word_count': len(words),
                'total_detections': len(text_detections)
            }
        }

        print(f"Successfully detected {len(lines)} lines and {len(words)} words")

        return result

    except Exception as e:
        print(f"Error detecting text: {str(e)}")
        # Return empty result on error (graceful degradation)
        return {
            'text': {
                'lines': [],
                'words': [],
                'full_text': '',
                'line_count': 0,
                'word_count': 0,
                'total_detections': 0,
                'error': str(e)
            }
        }
