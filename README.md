# NASA Earthdata DAAC Data Downloader

## Overview

This script designed to simplify the process of downloading data from NASA's Earthdata Level-1 and Atmosphere Archive & Distribution System Distributed Active Archive Center [LAADS DAAC](https://ladsweb.modaps.eosdis.nasa.gov/about/) within a specified range of days to an Amazon S3 bucket. It accommodates both single and multi-day operations, allowing users to define a range with start and end days. The script prompts users for essential input, such as the `base URL`, `S3 bucket name`, `start day`, and an EarthData `authentication token` for access. Leveraging the AWS CLI, it uploads the downloaded files to the specified S3 bucket. Detailed logging provides progress updates and captures any errors during the download process. Temporary files and directories are cleaned after each processing iteration. For ease of use, the script offers a `-h` flag for access to usage information and options. Users are encouraged to review log files for troubleshooting. 

## Prerequisites

- Bash
- curl
- jq
- wget
- AWS CLI configured with the necessary credentials and permissions

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/joChazaro/earthdata.git
   ```

2. Navigate to the project directory:
   ```bash 
   cd earthdata
   ```
3. Ensure the necessary dependencies are installed. 

## Usage

### Assumptions

- The script assumes that the necessary command-line tools (`curl`, `jq`, `wget`, AWS CLI) are installed and configured on the system.
- An Amazon S3 bucket is available and configured with the necessary permissions.
- Users have valid authorization tokens for accessing the specified DAAC.

### Running the Script

1. Make the script executable:

   ```bash
   chmod +x get_data_to_s3.sh
   ```
2. Execute the script:
   ```bash 
   ./get_data_to_s3.sh -u BASE_URL -b BUCKET_NAME -s START_DAY [-e END_DAY] -t AUTH_TOKEN
   ```
   #### Options:  
   `-u` BASE_URL: The base URL for downloading files.  
   `-b` BUCKET_NAME: The name of the S3 bucket for uploading files. Provide the S3 bucket name without a trailing "/" at the end.  
   `-s` START_DAY: The starting day of the range.  
   `-e` END_DAY: (Optional) The ending day of the range. If not provided, it defaults to the start day.  
   `-t` AUTH_TOKEN: The authorization token for authentication.  
   `-h` : Display script usage and options.  
   
   Or follow the prompts to enter the required information after executing `get_data_to_s3.sh`

### Help Flag (`-h`):
Use the -h flag to display script usage and options.
```bash 
   ./get_data_to_s3.sh -h
```
### Monitoring Progress

The script provides real-time information about downloaded and uploaded files.
A log file named download_log.txt contains detailed information about the processes.

### Reviewing Results

Check the output to ensure successful downloads and uploads.
In case of issues, refer to the log file for detailed information.

### Cleaning Up

The script creates a temporary directory named tmpFiles during execution, which is cleared after each day's processing.


