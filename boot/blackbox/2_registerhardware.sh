#!/bin/#!/usr/bin/env bash
# -e option instructs bash to immediately exit if any command [1] has a non-zero exit status
# We do not want users to end up with a partially working install, so we exit the script
# instead of continuing the installation with something broken
set -e

echo "2_registerhardware.sh has started">>/boot/log.txt
start(){
  sendhash
}
telegram()
{
   local VARIABLE=${1}
   curl -s -X POST https://blackbox.surfwijzer.nl/telegram.php -h="User-Agent: BlackBox" -d text="2_registerhardware.sh: $VARIABLE" >/dev/null
}
#telegram "Check"

sendhash()
{
  # post the hardware data to ur api backend.
  # we send the hardware-hash as authorization header.
  POSTDATA=$(</boot/blackbox/hardware.json)
  HARDWAREHASH=$(</boot/blackbox/hardware.hash)

  status_code=$(curl --write-out %{http_code} --silent --output /dev/null -i \
  -H "User-Agent: surfwijzerblackbox" \
  -H "Cache-Control: private, max-age=0, no-cache" \
  -H "Accept: application/json" \
  -H "Content-Type:application/json" \
  -H "Authorization: $HARDWAREHASH" \
  -X POST --data "$POSTDATA" "https://blackbox.surfwijzer.nl/api/installation?hash=$HARDWAREHASH")

  # check if the post succeeds
  if [[ "$status_code" -ne 200 ]] ; then
    # unsuccessful attempt.
    echo "Site status changed to $status_code"
    echo "ERRORRRR do not activate."
  else
    echo "status = $status_code"
    # write the hash for later reference.
    echo  $HARDWAREHASH>/var/www/blackbox.id
    # remove the helper files.
    rm -f /boot/blackbox/2_registerhardware.sh
    rm -f /boot/blackbox/hardware.json
    rm -f /boot/blackbox/hardware.hash
  fi



}


#echo  $HARDWAREHASH>/var/log/sinit.log
#echo  $POSTDATA>/boot/blackbox/hardware.json
#echo  $HARDWAREHASH>/boot/blackbox/hardware.hash

# check if network is available (assumed yes)

start
