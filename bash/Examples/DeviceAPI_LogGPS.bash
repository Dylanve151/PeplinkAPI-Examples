#!/bin/bash
## Example of device API call script
## GPS logging to csv

export $(cat .env)

# please change these variables
templogfile="${HOME}/gpslog.csv"

## Token file
access_token_file="${HOME}/.access_token"
access_token=$(cat ${access_token_file})

tmpfile="/tmp/ic2.tmpfile.$$"

touch $tmpfile

curl_opt=" -k "

echo "Logging GPS..."

token_params="accessToken=${access_token}"

curl $curl_opt -so $tmpfile --data "${token_params}" -X GET "${server_prefix}/api/info.location"
reqstat=$(jq -r '.stat' $tmpfile)
if grep -q Unauthorized $tmpfile ; then
	echo "The saved access token is invalid."
	rm -f ${access_token_file}
	exit 7
fi

if [ "${reqstat}" == "fail" ] ; then
	jq -r '.' $tmpfile
	exit 7
fi

gpsstat=$(jq -r '.response.gps' $tmpfile)
if [ "${gpsstat}" == "true" ] ; then
	loctime=$(jq -r '.response.location.timestamp' $tmpfile)
	ts=$(date +"%s")
	latitude=$(jq -r '.response.location.latitude' $tmpfile)
	longitude=$(jq -r '.response.location.longitude' $tmpfile)

	if [ -f "$templogfile" ]; then
			echo "GPS logged"
	else
			csvhead="timestamp;localtime;latitude;longitude"
			echo ${csvhead} > $templogfile
			echo "File created and Temp logged"
	fi

	csvdata="${ts};${loctime};${latitude};${longitude}"

	echo ${csvdata} >> $templogfile
else
	echo "No GPS"
	jq -r '.' $tmpfile
fi
rm -f $tmpfile
