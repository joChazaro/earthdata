#!/bin/bash

# Set your credentials or customize this script as needed
USERNAME="your_username"
PASSWORD="your_password"

# Execute retrieve_tokens.sh to obtain the access token
./retrieve_tokens.sh "$USERNAME" "$PASSWORD"

# If retrieve_tokens.sh is successful, read additional inputs for get_data_to_s3.sh
if [ $? -eq 0 ]; then
    read -p "Enter base URL: " BASE_URL
    read -p "Enter S3 bucket name: " BUCKET_NAME
    read -p "Enter start day: " START_DAY
    read -p "Enter end day (leave empty for single day): " IS_SINGLE_DAY

    if [ -z "$IS_SINGLE_DAY" ]; then
        read -p "Enter end day: " END_DAY
    else
        END_DAY="$START_DAY"
    fi

    # Obtain the access token from retrieve_tokens.sh
    ACCESS_TOKEN=$(./retrieve_tokens.sh -q)

    # Call get_data_to_s3.sh with the obtained inputs
    ./get_data_to_s3.sh -u "$BASE_URL" -b "$BUCKET_NAME" -s "$START_DAY" -e "$END_DAY" -t "$ACCESS_TOKEN"
else
    echo "Error: Failed to retrieve access tokens. Please check your credentials."
fi

echo "Execution complete."

