#!/bin/bash

# Display script usage manual
display_manual() {
    echo "Usage: $0 -u BASE_URL -b BUCKET_NAME -s START_DAY [-e END_DAY] -t AUTH_TOKEN"
    echo ""
    echo "Options:"
    echo "  -u BASE_URL             Set the base URL for downloading files"
    echo "  -b BUCKET_NAME          Set the S3 bucket name for uploading files"
    echo "  -s START_DAY            Set the start day for the range of days"
    echo "  -e END_DAY              Set the end day for the range of days (optional, defaults to start day)"
    echo "  -t AUTH_TOKEN           Set the authorization token for authentication"
    echo ""
    echo "Example:"
    echo "  $0 -u https://example.com/data/ -b mybucket -s 20230101 -e 20230105 -t mytoken"
    exit 1
}

# Check if there are no command-line arguments
if [ "$#" -eq 0 ]; then
    display_manual
fi

# Parse command-line options
while getopts ":u:b:s:e:t:" opt; do
    case $opt in
        u) base_url=$OPTARG ;;
        b) bucket_name=$OPTARG ;;
        s) start_day=$OPTARG ;;
        e) end_day=$OPTARG ;;
        t) authorization_token=$OPTARG ;;
        \?) echo "Invalid option: -$OPTARG" >&2
            display_manual
            ;;
        :) echo "Option -$OPTARG requires an argument." >&2
            display_manual
            ;;
    esac
done

# Check if required options are provided
if [ -z "$base_url" ] || [ -z "$bucket_name" ] || [ -z "$start_day" ] || [ -z "$authorization_token" ]; then
    display_manual
fi

# Clear the log file at the beginning of the script
log_file="./download_log.txt"
> "$log_file"

# Function to prompt user for input if argument is not provided
prompt_user() {
    local prompt_text=$1
    local variable_name=$2
    read -p "$prompt_text" "$variable_name"
}

# Check for missing values for provided options
[ -z "$base_url" ] && prompt_user "Enter base URL: " base_url
[ -z "$bucket_name" ] && prompt_user "Enter S3 bucket name: " bucket_name
[ -z "$start_day" ] && prompt_user "Enter start day: " start_day

is_single_day=""
# Prompt user for input only if the -e option is not provided
if [ -z "$end_day" ]; then
    prompt_user "Enter end day (leave empty for single day): " is_single_day
    if [ "${is_single_day,,}" == "y" ]; then
        end_day=$start_day
    elif [ -z "$is_single_day" ]; then
        prompt_user "Enter end day: " end_day
    fi
fi

[ -z "$authorization_token" ] && prompt_user "Enter authorization token: " authorization_token

# Loop through the range of Julian days
for ((day=start_day; day<=end_day; day++)); do
    url="${base_url}${day}"

    echo "Downloading from: $url"

    # Download the JSON file using curl
    curl_output=$(curl -s "$url.json")

    # Extract download links from the JSON file using jq
    download_links=($(echo "$curl_output" | jq -r '.content[].downloadsLink'))

    # Update the expected files counter
    expected_files=${#download_links[@]}

    echo "Expected number of files for day $day: $expected_files"

    # Loop through the array of download links and use wget for each
    successful_uploads=0  # Counter for successful uploads for the current day

    for link in "${download_links[@]}"; do
        echo "Downloading file: $link"
        wget --header "Authorization: Bearer $authorization_token" -P ./tmpFiles "$link" >> "$log_file" 2>&1

        if [ $? -eq 0 ]; then
            echo "Download successful for $link" >> "$log_file"
            successful_uploads=$((successful_uploads + 1))
        else
            echo "Error downloading $link. See $log_file for details." >&2
        fi
    done

    aws s3 cp ./tmpFiles s3://$bucket_name/$day --recursive

    # Print the success rate for the current day
    echo "Successfully uploaded files for day $day: $successful_uploads out of $expected_files"

    # Clear the temporary directory
    rm -r ./tmpFiles/*
done

