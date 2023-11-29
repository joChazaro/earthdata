#!/bin/bash

# Function to display usage information
function usage {
  echo "Usage:"
  echo "  $0 [options]"
  echo ""
  echo "Description:"
  echo "  This script will recursively download files for a specified range of Julian days"
  echo "  from a LAADS URL and upload them to an S3 bucket with folders for each day"
  echo ""
  echo "Options:"
  echo "    -u|--url [URL]            Base URL for LAADS data (e.g., https://ladsweb.modaps.eosdis.nasa.gov/archive/allData/5019/XAERDT_L2_ABI_G16)"
  echo "    -b|--bucket [bucket]      S3 bucket name"
  echo "    -t|--token [token]        Use app token [token] to authenticate"
  echo "    -s|--start [day]          Start Julian day"
  echo "    -e|--end [day]            End Julian day"
  ""
  echo "Dependencies:"
  echo "  Requires 'jq' and 'awscli' which should be installed"
}

# Function to recursively download files for a range of Julian days and upload to S3
function download_and_upload_to_s3 {
  local base_url=$1
  local s3_bucket=$2
  local token=$3
  local start_julian_day=$4
  local end_julian_day=$5

  for ((julian_day=start_julian_day; julian_day<=end_julian_day; julian_day++))
  do
    julian_day_str=$(printf "%03d" $julian_day)
    url="${base_url}/$(date -d "2019-01-01 +$((julian_day-1)) days" +"%Y/%j")"
    
    echo "Querying ${url}.json for Julian day ${julian_day_str}"

    for file in $(curl -L -s -g -H "Authorization: Bearer ${token}" -C - ${url}.json | jq '.content | .[] | select(.size!=0) | .name' | tr -d '"')
    do
      local local_file="${file}"

      # Check if the local file exists before attempting to upload
      if [ -f ${local_file} ] 
      then
        echo "Downloading $file to ${local_file}"
        curl -L -s -g -H "Authorization: Bearer ${token}" -C - ${url}/${file} -o ${local_file}

        # Use only the three digits of the Julian day for the S3 folder name
        s3_folder_name="${julian_day_str}"

        echo "Uploading $local_file to s3://${s3_bucket}/${s3_folder_name}/${file}"
        aws s3 cp ${local_file} "s3://${s3_bucket}/${s3_folder_name}/${file}"
      else
        echo "Skipping $file because the local file does not exist."
      fi
    done
  done
}

# Parsing command-line arguments
POSITIONAL=()
while [[ $# -gt 0 ]]
do
  key="$1"

  case $key in
    -u|--url)
    base_url="$2"
    shift # past argument
    shift # past value
    ;;
    -b|--bucket)
    s3_bucket="$2"
    shift # past argument
    shift # past value
    ;;
    -t|--token)
    token="$2"
    shift # past argument
    shift # past value
    ;;
    -s|--start)
    start_julian_day="$2"
    shift # past argument
    shift # past value
    ;;
    -e|--end)
    end_julian_day="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
  esac
done

# Checking if required parameters are provided
if [ -z ${base_url+x} ]
then 
  echo "Base URL is not specified"
  usage
  exit 1
fi

if [ -z ${s3_bucket+x} ]
then 
  echo "S3 bucket name is not specified"
  usage
  exit 1
fi

if [ -z ${token+x} ]
then 
  echo "Token is not specified"
  usage
  exit 1
fi

if [ -z ${start_julian_day+x} ]
then 
  echo "Start Julian day is not specified"
  usage
  exit 1
fi

if [ -z ${end_julian_day+x} ]
then 
  echo "End Julian day is not specified"
  usage
  exit 1
fi

# Invoking the download and upload to S3 function for the specified Julian day range
download_and_upload_to_s3 "$base_url" "$s3_bucket" "$token" "$start_julian_day" "$end_julian_day"

