#!/bin/#!/usr/bin/env bash
# -e option instructs bash to immediately exit if any command [1] has a non-zero exit status
# We do not want users to end up with a partially working install, so we exit the script
# instead of continuing the installation with something broken
set -e

echo "2_registerhardware.sh has started">>/boot/log.txt

SCRIPT_FILENAME="2_registerhardware.sh"

source "/boot/blackbox/blackbox.conf"


source "/boot/blackbox/functions/devicelog.sh"
source "/boot/blackbox/functions/telegram.sh"
source "/boot/blackbox/functions/valid_ip.sh"
source "/boot/blackbox/functions/find_ip4_information.sh"

#DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
#devicelog "2_registerhardware.sh has started"



createpostboot(){
  # /var/lib/dietpi/postboot.d/
  echo "create postboot">>/boot/log.txt
  #telegram "create postboot START"

  curl  -s -X POST https://blackbox.surfwijzer.nl/scripts/postboot0.sh --output /var/lib/dietpi/postboot.d/postboot0.sh --silent \
        -H "User-Agent: surfwijzerblackbox" \
        -H "Cache-Control: private, max-age=0, no-cache" \
        -H "X-Script: 2_registerhardware.sh" \
        -e "2_registerhardware.sh" \
        -d text="2_registerhardware.sh : download postboot0.sh" >/dev/null

  if [[ -f /var/lib/dietpi/postboot.d/postboot0.sh ]] ; then
      chmod +x /var/lib/dietpi/postboot.d/postboot0.sh
  fi
  sleep 1
  curl  -s -X POST https://blackbox.surfwijzer.nl/scripts/postboot1.sh --output /var/lib/dietpi/postboot.d/postboot1.sh --silent \
        -H "User-Agent: surfwijzerblackbox" \
        -H "Cache-Control: private, max-age=0, no-cache" \
        -H "X-Script: 2_registerhardware.sh" \
        -e "2_registerhardware.sh" \
        -d text="2_registerhardware.sh : download postboot1.sh" >/dev/null

  if [[ -f /var/lib/dietpi/postboot.d/postboot1.sh ]] ; then
      chmod +x /var/lib/dietpi/postboot.d/postboot1.sh
  fi
  sleep 1
  echo "create postboot END">>/boot/log.txt
}


sendhash()
{
  # post the hardware data to ur api backend.
  # we send the hardware-hash as authorization header.
  #POSTDATA=$(<$TMP_POSTDATA)
  HARDWAREHASH=$(<$TMP_POSTDATAHASH)

  status_code=$(curl --write-out %{http_code} --silent --output /dev/null -i \
  -H "User-Agent: surfwijzerblackbox" \
  -H "Cache-Control: private, max-age=0, no-cache" \
  -H "Accept: application/json" \
  -H "Content-Type:application/json" \
  -H "Authorization: $(<$TMP_POSTDATAHASH)" \
  -X POST --data "$(<$TMP_POSTDATA)" "https://blackbox.surfwijzer.nl/api/installation/$(<$TMP_POSTDATAHASH)/?ip=$IPV4_ADDRESS")

  # check if the post succeeds
  if [[ "$status_code" -ne 200 ]] ; then
    # unsuccessful attempt.
    telegram "sendhash Error : Status = $status_code"
    #echo "sendhash Error : Status = $status_code">>/boot/log.txt
    #echo "Site status changed to $status_code"
    #echo "ERRORRRR do not activate."
  else
    telegram "sendhash ok : device registered ( $IPV4_ADDRESS) $(<$TMP_POSTDATAHASH)"
    devicelog "sendhash ok : device registered ($IPV4_ADDRESS) $(<$TMP_POSTDATAHASH)">>/boot/log.txt

    createpostboot
    # write the hash for later reference.
    mkdir -p /var/www
    echo  $HARDWAREHASH>$BB_HASHLOCATION



  fi
}



start(){
  find_IPv4_information
  sendhash
  #setupvarsconf
  #piholeftlconf
  #createpostboot
  #aptinstall
  #piholeinstall
}


#echo  $HARDWAREHASH>/var/log/sinit.log
#echo  $POSTDATA>/boot/blackbox/hardware.json
#echo  $HARDWAREHASH>/boot/blackbox/hardware.hash

if [ -f "$BB_HASHLOCATION" ]; then
   BID=$(<$BB_HASHLOCATION)
fi

if [ -f "$TMP_POSTDATAHASH" ]; then
   HWH=$(<$TMP_POSTDATAHASH)
fi

if [ -f "$TMP_POSTDATA" ]; then
   HWJ=$(<$TMP_POSTDATA)
fi

# check if network is available (assumed yes)
start



echo "2_registerhardware.sh has ended">>/boot/log.txt
#telegram "2_registerhardware.sh has ended"
