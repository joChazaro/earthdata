#!/bin/bash

read -p "Enter username: " username
read -s -p "Enter password: " password

# Concatenate username and password with a colon
credentials="${username}:${password}"

# Base64 encode the concatenated string
encoded_credentials=$(echo -n "$credentials" | base64)

# Make the first curl request and store the JSON response in a variable
response=$(curl --request GET --url https://urs.earthdata.nasa.gov/api/users/tokens -u "$credentials")

# Print debug information
echo "Debug Info:"
echo "Base64 Encoded Credentials: $encoded_credentials"  # Temporary debug statement
echo "Initial CURL Response: $response"  # Temporary debug statement
echo "--------------------------------------"

# Check if the response is empty or contains an error
if [ -z "$response" ]; then
    echo "Error: Failed to retrieve access tokens. Attempting to generate a new token."

    # Create a new token with the provided username and password
    base64encodedusrandpass=$(echo -n "$credentials" | base64)
    new_token_response=$(curl -H "Authorization: Basic $base64encodedusrandpass" --request POST https://ladsweb.modaps.eosdis.nasa.gov/oauth/key)

    # Print debug information
    echo "New Token CURL Response: $new_token_response"  # Temporary debug statement
    echo "--------------------------------------"

    # Check if the new token generation was successful
    if [ -z "$new_token_response" ]; then
        echo "Error: Failed to generate a new token. Check your credentials or the token generation endpoint."
    else
        echo "New token generated successfully."
        # Retry the original GET request to verify the new access token
        response=$(curl --request GET --url https://urs.earthdata.nasa.gov/api/users/tokens -u "$credentials")
        
        # Print debug information
        echo "Retry CURL Response: $response"  # Temporary debug statement
        echo "--------------------------------------"
    fi
fi

# Continue processing if the response is not empty
if [ -n "$response" ]; then
    # Extract access_token values, token_type, and expiration_date using jq
    access_tokens=$(echo "$response" | jq -r '.[].access_token')
    token_types=$(echo "$response" | jq -r '.[].token_type')
    expiration_dates=$(echo "$response" | jq -r '.[].expiration_date')

    # Print debug information
    echo "Access Tokens: $access_tokens"  # Temporary debug statement
    echo "Token Types: $token_types"  # Temporary debug statement
    echo "Expiration Dates: $expiration_dates"  # Temporary debug statement
    echo "--------------------------------------"

    # Check if any access tokens were found
    if [ -z "$access_tokens" ]; then
        echo "No access tokens found."
    else
        # Iterate over the access tokens and check conditions
        for i in $(seq 0 $((${#access_tokens[@]} - 1))); do
            access_token="${access_tokens[$i]}"
            token_type="${token_types[$i]}"
            expiration_date="${expiration_dates[$i]}"

            # Check conditions for each access token
            if [ "$token_type" = "Bearer" ]; then
                echo "Access Token $i:"
                echo "  Token Type: $token_type"
                echo "  Expiration Date: $expiration_date"
                echo "  Access Token: $access_token"
                echo ""
            else
                echo "Access Token $i rejected: Invalid token_type"
            fi
        done
    fi
fi

