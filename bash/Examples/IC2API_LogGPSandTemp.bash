#!/bin/bash
## Example of API call script
## GPS and temperature logging to csv

export $(cat .env)

# please change these variables
templogfile=./templog.csv
org_id=""
device_id=""

## Token file
access_token_file="${HOME}/.access_token"
access_token=$(cat ${access_token_file})

tmpfile="/tmp/ic2.tmpfile.$$"

if [ -z "$server_prefix" ]
then
        server_prefix="https://api.ic.peplink.com"
fi


echo "Logging temp"

curl $curl_opt -so $tmpfile "${server_prefix}/rest/o/${org_id}/d/${device_id}?access_token=${access_token}"
if grep -q Unauthorized $tmpfile ; then
      echo "The saved access token is invalid.  Rerun this script to obtain a new one"
      rm -f ${access_token_file}
      exit 7
fi

devicetemp=$(jq -r '.data.periph_status.thermal_sensor[].temperature' $tmpfile)
loctime=$(jq -r '.data.location_timestamp' $tmpfile)
ts=$(date +"%s")
sn=$(jq -r '.data.sn' $tmpfile)
cpuload="$(jq -r '.data.periph_status.cpu_load.percentage' $tmpfile)%"
devicestatus=$(jq -r '.data.status' $tmpfile)
latitude=$(jq -r '.data.latitude' $tmpfile)
longitude=$(jq -r '.data.longitude' $tmpfile)

if [ -f "$templogfile" ]; then
        echo "Temp logged"
else
        csvhead="timestamp;serialnumber;localtime;devicetemp;cpuload;devicestatus;latitude;longitude"
        echo ${csvhead} > $templogfile
        echo "File created and Temp logged"
fi

csvdata="${ts};${sn};${loctime};${devicetemp};${cpuload};${devicestatus};${latitude};${longitude}"

echo ${csvdata} >> $templogfile

rm -f $tmpfile
