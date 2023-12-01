#!/bin/bash

# Clear the log file at the beginning of the script
log_file="./download_log.txt"
> "$log_file"

# Function to prompt user for input if argument is not provided
prompt_user() {
    local prompt_text=$1
    local variable_name=$2
    read -p "$prompt_text" "$variable_name"
}

# Parse command-line options
while getopts ":u:b:s:t:" opt; do
  case $opt in
    u) base_url=$OPTARG ;;
    b) bucket_name=$OPTARG ;;
    s) is_single_day=$OPTARG ;;
    t) authorization_token=$OPTARG ;;
    \?) echo "Invalid option: -$OPTARG" >&2
        exit 1
        ;;
    :) echo "Option -$OPTARG requires an argument." >&2
        exit 1
        ;;
  esac
done

# Prompt user for input if not provided through command-line options
[ -z "$base_url" ] && prompt_user "Enter base URL: " base_url
[ -z "$bucket_name" ] && prompt_user "Enter S3 bucket name: " bucket_name
[ -z "$is_single_day" ] && prompt_user "Enter single day (Y/N): " is_single_day

if [ "$is_single_day" == "Y" ] || [ "$is_single_day" == "y" ]; then
    [ -z "$start_day" ] && prompt_user "Enter day: " start_day
    end_day=$start_day
else
    [ -z "$start_day" ] && prompt_user "Enter start day: " start_day
    [ -z "$end_day" ] && prompt_user "Enter end day: " end_day
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

