#!/bin/#!/usr/bin/env bash
# -e option instructs bash to immediately exit if any command [1] has a non-zero exit status
# We do not want users to end up with a partially working install, so we exit the script
# instead of continuing the installation with something broken
set -e

echo "2_registerhardware.sh has started">>/boot/log.txt

SCRIPT_FILENAME="2_registerhardware.sh"

source "/etc/blackbox/blackbox.conf"

source "/usr/share/blackbox/func/devicelog.sh"
source "/usr/share/blackbox/func/telegram.sh"
source "/usr/share/blackbox/func/valid_ip.sh"
source "/usr/share/blackbox/func/find_ip4_information.sh"


#DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
#devicelog "2_registerhardware.sh has started"


if [ -f "$BB_HASH" ]; then
  BID=$(<$BB_HASH)
fi



HARDWAREHASH=$(<$BB_HASH)



createpostboot(){
  # /var/lib/dietpi/postboot.d/
  echo "create postboot">>/boot/log.txt
  #telegram "create postboot START"

  curl  -s -X POST https://api.surfwijzer.nl/blackbox/scripts/postboot0.sh --output /var/lib/dietpi/postboot.d/postboot0.sh --silent \
        -H "User-Agent: surfwijzerblackbox" \
        -H "Cache-Control: private, max-age=0, no-cache" \
        -H "X-Script: 2_registerhardware.sh" \
        -H "Authorization: $BID" \
        -e "2_registerhardware.sh" \
        -d text="2_registerhardware.sh : download postboot0.sh" >/dev/null

  if [[ -f /var/lib/dietpi/postboot.d/postboot0.sh ]] ; then
      chmod +x /var/lib/dietpi/postboot.d/postboot0.sh
  fi
  sleep 1
  curl  -s -X POST https://api.surfwijzer.nl/blackbox/scripts/postboot1.sh --output /var/lib/dietpi/postboot.d/postboot1.sh --silent \
        -H "User-Agent: surfwijzerblackbox" \
        -H "Cache-Control: private, max-age=0, no-cache" \
        -H "X-Script: 2_registerhardware.sh" \
        -H "Authorization: $BID" \
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
  -H "X-Script: 2_registerhardware.sh" \
  -H "Content-Type:application/json" \
  -H "Authorization: $BID" \
  -X POST --data "$(<$BB_JSON)" "https://api.surfwijzer.nl/blackbox/api/installation/$BID/$IPV4_ADDRESS")

  # check if the post succeeds
  if [[ "$status_code" -eq 200 ]] ; then
    # unsuccessful attempt.
    telegram "sendhash Ok (already registered!) : Status = $status_code"
    devicelog "sendhash Ok (already registered!) : Status = $status_code ($IPV4_ADDRESS)"
    echo "sendhash Ok (already registered!)  : Status = $status_code ($IPV4_ADDRESS)" >>/boot/log.txt
    #echo "sendhash Error : Status = $status_code">>/boot/log.txt
    #echo "Site status changed to $status_code"
    #echo "ERRORRRR do not activate."

  elif [[ "$status_code" -eq 201  ]] ;then
    telegram "sendhash ok : device registered ( $IPV4_ADDRESS) $BID"
    devicelog "sendhash ok : device registered ($IPV4_ADDRESS) $BID"
    echo "sendhash ok : device registered ($IPV4_ADDRESS) $BID" >>/boot/log.txt
    createpostboot
    echo "5" > $BB_STATE
    # write the hash for later reference.
    mkdir -p /var/www
    #echo  $HARDWAREHASH>$BB_HASHLOCATION

  else

    telegram "sendhash ERROR  : Status = $status_code ($IPV4_ADDRESS)"
    devicelog "sendhash ERROR  : Status = $status_code ($IPV4_ADDRESS)"
    echo "sendhash ERROR  : Status = $status_code ($IPV4_ADDRESS)"  >>/boot/log.txt
  fi
}



start(){
  echo "3" > $BB_STATE
  find_IPv4_information
  echo "4" > $BB_STATE
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

if [ -f "$BB_HASH" ]; then
   BID=$(<$BB_HASH)
fi

if [ -f "$TMP_POSTDATAHASH" ]; then
   HWH=$(<$TMP_POSTDATAHASH)
fi

if [ -f "$BB_JSON" ]; then
   HWJ=$(<$BB_JSON)
fi

# check if network is available (assumed yes)
start



echo "2_registerhardware.sh has ended">>/boot/log.txt
#telegram "2_registerhardware.sh has ended"
