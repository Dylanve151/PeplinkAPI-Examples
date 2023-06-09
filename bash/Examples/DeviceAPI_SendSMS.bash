#!/bin/bash
## Example of device API call script
## Send sms

export $(cat .env)

# please change these variables
smsnumber="0123456789"
smsmessage="test"
connid="3"

## Token file
access_token_file="${HOME}/.access_token"
access_token=$(cat ${access_token_file})

tmpfile="/tmp/ic2.tmpfile.$$"
touch $tmpfile

curl_opt=" -k "

token_params="accessToken=${access_token}"
sendsms_params="&connId=${connid}&address=${smsnumber}&content=${smsmessage}"

curl $curl_opt -so $tmpfile --data "${token_params}${sendsms_params}" "${server_prefix}/api/cmd.sms.sendMessage"

if grep -q Unauthorized $tmpfile ; then
      echo "The saved access token is invalid."
      rm -f ${access_token_file}
      exit 7
fi

stat=$(jq -r ".stat" $tmpfile)
if [ "${stat}" == "ok" ]
then
  echo "OK: SMS has been send"
else
  echo "FAIL: SMS has NOT been send"
  cat $tmpfile
fi

rm -f $tmpfile
