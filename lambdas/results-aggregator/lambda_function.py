import json
import boto3
import os
from datetime import datetime
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')

# Map service prefixes to table names
SERVICE_TABLES = {
    'text-detection': os.environ.get('TEXT_DETECTION_TABLE', 'text-detection-results'),
    'face-detection': os.environ.get('FACE_DETECTION_TABLE', 'face-detection-results'),
    'object-detection': os.environ.get('OBJECT_DETECTION_TABLE', 'object-detection-results')
}

def get_table_for_image(image_id):
    """Determine which table to write to based on image_id prefix"""
    for service, table_name in SERVICE_TABLES.items():
        if image_id.startswith(f"{service}/"):
            return dynamodb.Table(table_name), service
    # Default to object-detection for backward compatibility
    return dynamodb.Table(SERVICE_TABLES['object-detection']), 'object-detection'

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

        # For service-specific workflows, results are in different keys
        text_results = event.get('text_results', {})
        face_results = event.get('face_results', {})
        object_results = event.get('object_results', {})

        # For backward compatibility with parallel workflow
        detection_results_array = event.get('detection_results', [])

        bucket = orchestrator_result.get('bucket')
        key = orchestrator_result.get('key')
        image_id = orchestrator_result.get('image_id')

        # Determine which service and table to use
        table, service = get_table_for_image(image_id)
        print(f"Writing results to {service} table for image_id: {image_id}")

        # Extract individual detection results
        # Check if using service-specific workflow or parallel workflow
        if text_results or face_results or object_results:
            # Service-specific workflow
            objects_result = object_results.get('objects', {}) if object_results else {}
            faces_result = face_results.get('faces', {}) if face_results else {}
            text_result = text_results.get('text', {}) if text_results else {}
            moderation_result = {}
        else:
            # Parallel workflow (backward compatibility)
            objects_result = {}
            faces_result = {}
            text_result = {}
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

        # Build service-specific summary
        analysis_summary = {
            'service': service
        }

        if objects_result:
            analysis_summary['objects_detected'] = objects_result.get('count', 0)
        if faces_result:
            analysis_summary['faces_detected'] = faces_result.get('count', 0)
        if text_result:
            analysis_summary['text_detected'] = text_result.get('line_count', 0)
        if moderation_result:
            analysis_summary['moderation_flags'] = moderation_result.get('flags_count', 0)
            analysis_summary['is_safe'] = moderation_result.get('is_safe', True)

        # Prepare DynamoDB item with service-specific results
        item = {
            'image_id': image_id,
            'timestamp': timestamp,
            'bucket': bucket,
            'key': key,
            'service': service,
            'analysis_summary': analysis_summary,
            'detection_results': {},
            'status': 'completed'
        }

        # Add only relevant results for this service
        if objects_result:
            item['detection_results']['objects'] = objects_result.get('objects', [])
        if faces_result:
            item['detection_results']['faces'] = faces_result.get('faces', [])
        if text_result:
            item['detection_results']['text'] = text_result
        if moderation_result:
            item['detection_results']['moderation'] = moderation_result.get('moderation_labels', [])

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
