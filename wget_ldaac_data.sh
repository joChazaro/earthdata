#!/bin/bash

# Clear the log file at the beginning of the script
log_file="./download_log.txt"
> "$log_file"

# Prompt the user for input
read -p "Enter base URL: " base_url
read -p "Enter S3 bucket name: " bucket_name
read -p "Enter single day (Y/N): " is_single_day

if [ "$is_single_day" == "Y" ] || [ "$is_single_day" == "y" ]; then
    read -p "Enter day: " start_day
    end_day=$start_day
else
    read -p "Enter start day: " start_day
    read -p "Enter end day: " end_day
fi

read -p "Enter authorization token: " authorization_token

# Initialize counters
expected_files=0
successful_uploads=0

# Loop through the range of Julian days
for ((day=start_day; day<=end_day; day++)); do
    url="${base_url}${day}"

    echo "Downloading from: $url"

    # Download the JSON file using curl
    curl_output=$(curl -s "$url.json")

    # Extract download links from the JSON file using jq
    download_links=($(echo "$curl_output" | jq -r '.content[].downloadsLink'))

    # Update the expected files counter
    expected_files=$((expected_files + ${#download_links[@]}))

    # Loop through the array of download links and use wget for each
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

    # Clear the temporary directory
    rm -r ./tmpFiles/*
done

# Print the results
echo "Expected number of files: $expected_files"
echo "Number of successfully uploaded files: $successful_uploads"

