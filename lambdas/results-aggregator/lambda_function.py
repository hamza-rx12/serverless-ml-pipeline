import json
import boto3
import os
from datetime import datetime
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('DYNAMODB_TABLE', 'image-analysis-results')
table = dynamodb.Table(table_name)

def convert_floats_to_decimal(obj):
    """Convert float values to Decimal for DynamoDB"""
    if isinstance(obj, list):
        return [convert_floats_to_decimal(item) for item in obj]
    elif isinstance(obj, dict):
        return {key: convert_floats_to_decimal(value) for key, value in obj.items()}
    elif isinstance(obj, float):
        return Decimal(str(obj))
    return obj

def handler(event, context):
    """
    Results Aggregator Lambda - Combines all detection results and stores in DynamoDB
    """
    try:
        print(f"Aggregating results: {json.dumps(event, default=str)}")

        # Extract data from Step Functions output
        orchestrator_result = event.get('orchestrator_result', {})
        detection_results_array = event.get('detection_results', [])

        bucket = orchestrator_result.get('bucket')
        key = orchestrator_result.get('key')
        image_id = orchestrator_result.get('image_id')

        # Extract individual detection results from parallel array
        # Parallel state returns an array with 3 elements (objects, faces, moderation)
        objects_result = {}
        faces_result = {}
        moderation_result = {}

        for result in detection_results_array:
            if 'objects' in result:
                objects_result = result['objects']
            if 'faces' in result:
                faces_result = result['faces']
            if 'moderation' in result:
                moderation_result = result['moderation']

        # Aggregate analysis
        timestamp = datetime.utcnow().isoformat()

        analysis_summary = {
            'objects_detected': objects_result.get('count', 0),
            'faces_detected': faces_result.get('count', 0),
            'moderation_flags': moderation_result.get('flags_count', 0),
            'is_safe': moderation_result.get('is_safe', True)
        }

        # Prepare DynamoDB item
        item = {
            'image_id': image_id,
            'timestamp': timestamp,
            'bucket': bucket,
            'key': key,
            'analysis_summary': analysis_summary,
            'detection_results': {
                'objects': objects_result.get('objects', []),
                'faces': faces_result.get('faces', []),
                'moderation': moderation_result.get('moderation_labels', [])
            },
            'status': 'completed'
        }

        # Convert floats to Decimal for DynamoDB
        item = convert_floats_to_decimal(item)

        # Write to DynamoDB
        table.put_item(Item=item)

        print(f"Successfully stored results for {image_id}")

        return {
            'statusCode': 200,
            'message': 'Results aggregated and stored successfully',
            'image_id': image_id,
            'timestamp': timestamp,
            'summary': analysis_summary
        }

    except Exception as e:
        print(f"Error aggregating results: {str(e)}")
        return {
            'statusCode': 500,
            'error': str(e),
            'message': 'Failed to aggregate results'
        }
