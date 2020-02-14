#!/bin/#!/usr/bin/env bash
# -e option instructs bash to immediately exit if any command [1] has a non-zero exit status
# We do not want users to end up with a partially working install, so we exit the script
# instead of continuing the installation with something broken
set -e

echo "2_registerhardware.sh has started">>/boot/log.txt

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
  -X POST --data "$POSTDATA" "https://blackbox.surfwijzer.nl/api/installation?ip=$IPV4_ADDRESS&hash=$HARDWAREHASH")

  # check if the post succeeds
  if [[ "$status_code" -ne 200 ]] ; then
    # unsuccessful attempt.
    echo "Site status changed to $status_code"
    echo "ERRORRRR do not activate."
  else
    echo "status = $status_code"
    # write the hash for later reference.
    mkdir -p /var/www
    echo  $HARDWAREHASH>/var/www/blackbox.id
    # remove the helper files.
    rm -f /boot/blackbox/2_registerhardware.sh
    rm -f /boot/blackbox/hardware.json
    rm -f /boot/blackbox/hardware.hash
  fi
}

find_IPv4_information() {
    # Detects IPv4 address used for communication to WAN addresses.
    # Accepts no arguments, returns no values.

    # Named, local variables
    local route
    local IPv4bare

    # Find IP used to route to outside world by checking the the route to Google's public DNS server
    route=$(ip route get 8.8.8.8)

    # Get just the interface IPv4 address
    # shellcheck disable=SC2059,SC2086
    # disabled as we intentionally want to split on whitespace and have printf populate
    # the variable with just the first field.
    printf -v IPv4bare "$(printf ${route#*src })"
    # Get the default gateway IPv4 address (the way to reach the Internet)
    # shellcheck disable=SC2059,SC2086
    printf -v IPv4gw "$(printf ${route#*via })"

    if ! valid_ip "${IPv4bare}" ; then
        IPv4bare="127.0.0.1"
    fi

    # Append the CIDR notation to the IP address, if valid_ip fails this should return 127.0.0.1/8
    IPV4_ADDRESS=$(ip -oneline -family inet address show | grep "${IPv4bare}/" |  awk '{print $4}' | awk 'END {print}')
}



start(){
  find_IPv4_information
  sendhash
}



#echo  $HARDWAREHASH>/var/log/sinit.log
#echo  $POSTDATA>/boot/blackbox/hardware.json
#echo  $HARDWAREHASH>/boot/blackbox/hardware.hash

FILE=/var/www/blackbox.id
if [ -f "$FILE" ]; then
   BID=$(</var/www/blackbox.id)

fi
FILE=/boot/blackbox/hardware.hash
if [ -f "$FILE" ]; then
   HWH=$(</boot/blackbox/hardware.hash)

fi
FILE=/boot/blackbox/hardware.json
if [ -f "$FILE" ]; then
   HWJ=$(</boot/blackbox/hardware.json)

fi
# check if network is available (assumed yes)

start

echo "2_registerhardware.sh has ended">>/boot/log.txt
