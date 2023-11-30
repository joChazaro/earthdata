#!/bin/bash

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

log_file="./download_log.txt"

# Loop through the range of Julian days
for ((day=start_day; day<=end_day; day++)); do
    url="${base_url}${day}"

    echo "Downloading from: $url"

    # Redirect standard output and standard error to the log file
    wget -e robots=off -r -np -nH --cut-dirs=5 --reject=html,tmp --header "Authorization: Bearer $authorization_token" -P ./tmpFiles "$url" >> "$log_file" 2>&1

    if [ $? -eq 0 ]; then
        echo "Download successful for $url" >> "$log_file"
    else
        echo "Error downloading $url. See $log_file for details." >&2
    fi

    aws s3 cp ./tmpFiles s3://$bucket_name/ --recursive

    rm -r ./tmpFiles/*
done

