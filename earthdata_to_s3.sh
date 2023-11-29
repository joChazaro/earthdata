#!/bin/bash

# Function to display usage information
function usage {
  echo "Usage:"
  echo "  $0 [options]"
  echo ""
  echo "Description:"
  echo "  This script will recursively download files for a specified range of Julian days"
  echo "  from a LAADS URL and upload them to the specified S3 path"
  echo ""
  echo "Options:"
  echo "    -u|--url [URL]            Base URL for LAADS data (e.g., https://ladsweb.modaps.eosdis.nasa.gov/archive/allData/5019/XAERDT_L2_ABI_G16)"
  echo "    -p|--s3-path [path]       S3 path (e.g., subfolder1/subfolder2)"
  echo "    -t|--token [token]        Use app token [token] to authenticate"
  echo "    -s|--start [day]          Start Julian day"
  echo "    -e|--end [day]            End Julian day"
  ""
  echo "Dependencies:"
  echo "  Requires 'jq' and 'aws' which should be installed and configured"
}

# Function to recursively download files for a range of Julian days and upload to S3
function download_and_upload_to_s3 {
  local base_url=$1
  local s3_path=$2
  local token=$3
  local start_julian_day=$4
  local end_julian_day=$5

  for ((julian_day=start_julian_day; julian_day<=end_julian_day; julian_day++))
  do
    julian_day_str=$(printf "%03d" $julian_day)
    url="${base_url}/$(date -d "2019-01-01 +$((julian_day-1)) days" +"%Y/%j")"
    
    echo "Querying ${url}.json for Julian day ${julian_day_str}"

    for file in $(curl -L -b session -s -g -H "Authorization: Bearer ${token}" -C - ${url}.json | jq '.content | .[] | select(.size!=0) | .name' | tr -d '"')
    do
      local local_file="${file}"
      local s3_uri="s3://${s3_path}/${file}"

      if [ ! -f ${local_file} ] 
      then
        echo "Downloading $file to ${local_file}"
        curl -L -b session -s -g -H "Authorization: Bearer ${token}" -C - ${url}/${file} -o ${local_file}

        echo "Uploading $local_file to $s3_uri"
        aws s3 cp ${local_file} ${s3_uri}
      else
        echo "Skipping $file ..."
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
    -p|--s3-path)
    s3_path="$2"
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

if [ -z ${s3_path+x} ]
then 
  echo "S3 path is not specified"
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

# Invoking the download and upload function for the specified Julian day range
download_and_upload_to_s3 "$base_url" "$s3_path" "$token" "$start_julian_day" "$end_julian_day"

