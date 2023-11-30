#!/bin/bash 

base_url="https://ladsweb.modaps.eosdis.nasa.gov/archive/allData/5019/XAERDT_L2_ABI_G16/2019/"
bucket_name="eso-west2-curated/AOS/PoR/geo/XAERDT_L2_ABI_G16/2019"
# Set your range of Julian days (replace 215 and 304 with your desired range)
start_day=291
end_day=304

authorization_token="$1"

# Loop through the range of Julian days
for ((day=$start_day; day<=$end_day; day++)); do
    url="${base_url}${day}"

    echo "Downloading from: $url"
    wget -e robots=off -r -np -nH --cut-dirs=5 --reject=html,tmp --header "Authorization: Bearer $authorization_token" -P ./tmpFiles "$url"

    aws s3 cp ./tmpFiles s3://$bucket_name/ --recursive

    rm -r ./tmpFiles/*
done
