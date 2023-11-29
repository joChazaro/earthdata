#!/bin/bash

# Function to display usage information
function usage {
  echo "Usage:"
  echo "  $0 [options]"
  echo ""
  echo "Description:"
  echo "  This script will recursively download files for a specified range of Julian days"
  echo "  from a LAADS URL and create folders for each day in the destination path"
  echo ""
  echo "Options:"
  echo "    -u|--url [URL]            Base URL for LAADS data (e.g., https://ladsweb.modaps.eosdis.nasa.gov/archive/allData/5019/XAERDT_L2_ABI_G16/2019/)"
  echo "    -d|--destination [path]   Destination directory to store files"
  echo "    -t|--token [token]        Use app token [token] to authenticate"
  echo "    -s|--start [day]          Start Julian day"
  echo "    -e|--end [day]            End Julian day"
  ""
  echo "Dependencies:"
  echo "  Requires 'jq' which should be installed"
}

# Function to recursively download files for a range of Julian days and create folders
function download_and_create_folders {
  local base_url=$1
  local destination=$2
  local token=$3
  local start_julian_day=$4
  local end_julian_day=$5

  for ((julian_day=start_julian_day; julian_day<=end_julian_day; julian_day++))
  do
    julian_day_str=$(printf "%03d" $julian_day)
    url="${base_url}${julian_day}.json"

    # Create a folder for each day
    day_folder="${destination}/${julian_day_str}"
    mkdir -p "${day_folder}"

    # Download files to the day folder
    echo "Querying ${url} for Julian day ${julian_day_str}"
    for file in $(curl -L -s -g -H "Authorization: Bearer ${token}" -C - ${url} | jq '.content | .[] | select(.size!=0) | .name' | tr -d '"')
    do
      local local_file="${day_folder}/${file}"

      if [ ! -f ${local_file} ] 
      then
        echo "Downloading $file to ${local_file}"
        curl -L -s -g -H "Authorization: Bearer ${token}" -C - "${base_url}${julian_day}/${file}" -o ${local_file}
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
    -d|--destination)
    destination="$2"
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

if [ -z ${destination+x} ]
then 
  echo "Destination path is not specified"
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

# Invoking the download and create folders function for the specified Julian day range
download_and_create_folders "$base_url" "$destination" "$token" "$start_julian_day" "$end_julian_day"

