import json

def handler(event, context):
    # The event contains S3 bucket and object information
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        event_name = record['eventName']
        
        print(f"Event: {event_name}")
        print(f"Bucket: {bucket}")
        print(f"Object Key: {key}")
        
        # Your processing logic here
        
    return {
        'statusCode': 200,
        'body': json.dumps('Processing complete')
    }