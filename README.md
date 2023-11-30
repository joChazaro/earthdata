# Earthdata Downloader

This script is designed to recursively download files for a specified range of Julian days from a LAADS (Level 1 and Atmosphere Archive & Distribution System) URL and create folders for each day in the destination path.

## Usage

```bash
./earthdata_downloader.sh [options]
## Options
-u|--url [URL]: Base URL for LAADS data (e.g., https://ladsweb.modaps.eosdis.nasa.gov/archive/allData/5019/XAERDT_L2_ABI_G16/2019/)
-d|--destination [path]: Destination directory to store files
-t|--token [token]: Use app token [token] to authenticate
-s|--start [day]: Start Julian day
-e|--end [day]: End Julian day

## Example 
./earthdata_downloader.sh -u "https://ladsweb.modaps.eosdis.nasa.gov/archive/allData/5019/XAERDT_L2_ABI_G16/2019/" -d "/path/to/destination" -t "your_app_token" -s 213 -e 304
