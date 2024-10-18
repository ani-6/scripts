import os
import boto3
import configparser

def load_config(config_file):
    config = configparser.ConfigParser()
    config.read(config_file)
    return config

def get_last_modified_files(directory, n=2):
    files = [os.path.join(directory, f) for f in os.listdir(directory) if os.path.isfile(os.path.join(directory, f))]
    files.sort(key=os.path.getmtime, reverse=True)  # Sort by modified time
    return files[:n]  # Get the last n files

def upload_to_s3(files, bucket_name, s3_client):
    for file in files:
        file_name = os.path.basename(file)
        try:
            # Upload to a specific folder in the bucket
            s3_client.meta.client.upload_file(file, bucket_name, f'backups/{file_name}')
            print(f'Successfully uploaded {file_name} to {bucket_name}')
        except Exception as e:
            print(f'Failed to upload {file_name}: {e}')

def main():
    # Get the directory of the current script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Load configuration
    config_file = os.path.join(script_dir, 'config.config')
    config = load_config(config_file)
    
    aws_access_key_id = config['aws']['aws_access_key_id']
    aws_secret_access_key = config['aws']['aws_secret_access_key']
    region_name = config['aws']['region_name']
    bucket_name = config['aws']['bucket_name']
    
    data_directory = config['settings']['data_dir_path']
    bkp_dir = config['settings']['bkp_directory']

    # Initialize S3 client
    s3_client = boto3.resource(
        's3',
        region_name=region_name,
        aws_secret_access_key=aws_secret_access_key,
        aws_access_key_id=aws_access_key_id,
        endpoint_url=config.get('aws', 'endpoint_url')
    )

    # Construct the directory path
    dir_path = os.path.join(data_directory, 'bookstack', bkp_dir)
    
    # Check if the directory exists
    if not os.path.exists(dir_path):
        print(f'Error: The directory does not exist: {dir_path}')
        return  # Exit if the directory does not exist

    last_modified_files = get_last_modified_files(dir_path)

    # Check if any files were found
    if not last_modified_files:
        print('No files found to upload.')
        return  # Exit if no files are found

    # Upload files to S3
    upload_to_s3(last_modified_files, bucket_name, s3_client)

if __name__ == '__main__':
    main()
