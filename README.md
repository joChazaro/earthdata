# NASA Earthdata DAAC Data Downloader

## Overview

This Bash script is designed to simplify the process of downloading data from NASA's Earthdata Data Archive and Access Centers (DAACs) and uploading it to an Amazon S3 bucket. The script prompts the user for input, including the base URL, S3 bucket name, date range, and authorization token. It then iterates through the specified date range, downloading data files using curl and uploading them to the specified S3 bucket using AWS CLI.

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
   ./get_data_to_s3.sh
   ```
   Then follow the prompts to enter the required information 

