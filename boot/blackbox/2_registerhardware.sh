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


cleanup(){
    # remove the helper files.
    rm -f /boot/blackbox/2_registerhardware.sh
    rm -f /boot/blackbox/hardware.json
    rm -f /boot/blackbox/hardware.hash
}

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
    telegram "sendhash Error : Status = $status_code"
    echo "sendhash Error : Status = $status_code">>/boot/log.txt
    #echo "Site status changed to $status_code"
    #echo "ERRORRRR do not activate."
  else
    echo "status = $status_code"
    telegram "sendhash ok : device registered ( $IPV4_ADDRESS )"
    echo "sendhash ok : device registered ( $IPV4_ADDRESS )">>/boot/log.txt
    # write the hash for later reference.
    mkdir -p /var/www
    echo  $HARDWAREHASH>/var/www/blackbox.id

  fi
}

# Check an IP address to see if it is a valid one
valid_ip() {
    # Local, named variables
    local ip=${1}
    local stat=1

    # If the IP matches the format xxx.xxx.xxx.xxx,
    if [[ "${ip}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        # Save the old Internal Field Separator in a variable
        OIFS=$IFS
        # and set the new one to a dot (period)
        IFS='.'
        # Put the IP into an array
        ip=(${ip})
        # Restore the IFS to what it was
        IFS=${OIFS}
        ## Evaluate each octet by checking if it's less than or equal to 255 (the max for each octet)
        [[ "${ip[0]}" -le 255 && "${ip[1]}" -le 255 \
        && "${ip[2]}" -le 255 && "${ip[3]}" -le 255 ]]
        # Save the exit code
        stat=$?
    fi
    # Return the exit code
    return ${stat}
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



piholeftlconf(){
  echo "PRIVACYLEVEL=0" >/etc/pihole/pihole-FTL.conf
  echo "BLOCKINGMODE=IP-NODATA-AAAA" >>/etc/pihole/pihole-FTL.conf

}

setupvarsconf(){
    mkdir -p /etc/pihole
    echo "PIHOLE_INTERFACE=eth0" >/etc/pihole/setupVars.conf
    #echo "IPV4_ADDRESS=10.0.1.207/24" >>/etc/pihole/setupVars.conf
    echo "IPV4_ADDRESS=$IPV4_ADDRESS" >>/etc/pihole/setupVars.conf
    echo "IPV6_ADDRESS=" >>/etc/pihole/setupVars.conf
    echo "PIHOLE_DNS_1=8.8.8.8" >>/etc/pihole/setupVars.conf
    echo "PIHOLE_DNS_2=8.8.4.4" >>/etc/pihole/setupVars.conf
    echo "QUERY_LOGGING=false" >>/etc/pihole/setupVars.conf
    echo "INSTALL_WEB_SERVER=true" >>/etc/pihole/setupVars.conf
    echo "INSTALL_WEB_INTERFACE=true" >>/etc/pihole/setupVars.conf
    echo "LIGHTTPD_ENABLED=true" >>/etc/pihole/setupVars.conf
    echo "BLOCKING_ENABLED=true" >>/etc/pihole/setupVars.conf
    echo "DNSMASQ_LISTENING=single" >>/etc/pihole/setupVars.conf
    echo "DNS_FQDN_REQUIRED=true" >>/etc/pihole/setupVars.conf
    echo "DNS_BOGUS_PRIV=true" >>/etc/pihole/setupVars.conf
    #echo "DNSSEC=true" >>/etc/pihole/setupVars.conf
    echo "TEMPERATUREUNIT=C" >>/etc/pihole/setupVars.conf
    #echo "CONDITIONAL_FORWARDING=true" >>/etc/pihole/setupVars.conf
    #echo "CONDITIONAL_FORWARDING_IP=10.0.1.1" >>/etc/pihole/setupVars.conf
    #echo "CONDITIONAL_FORWARDING_DOMAIN=localdomain" >>/etc/pihole/setupVars.conf
    #echo "CONDITIONAL_FORWARDING_REVERSE=1.0.10.in-addr.arpa" >>/etc/pihole/setupVars.conf
    echo "WEBPASSWORD=84ea6bece4df810e8a3d53ba0e6c5ff9cdc5c25ddd2d8b6ad5c5e009015c3e54" >>/etc/pihole/setupVars.conf

}

piholeinstall(){
    echo "install started : pihole">>/boot/log.txt
    curl -L https://install.pi-hole.net | bash /dev/stdin --unattended
    telegram "install finished : pihole"
    echo "install finished : pihole">>/boot/log.txt
}

aptinstall(){
  echo "install started : git">>/boot/log.txt
  apt install -y git
  telegram "apt install finished : git"
  echo "install finished : git">>/boot/log.txt

  echo "install started : sqlite3">>/boot/log.txt
  apt install -y sqlite3
  telegram "apt install finished : sqlite3"
  echo "install finished : php etc">>/boot/log.txt

  echo "install started : others">>/boot/log.txt
  apt install -y dnsutils lsof netcat idn2 dns-root-data
  telegram "apt install finished : others"
  echo "install finished : php etc">>/boot/log.txt



  echo "install started : php etc">>/boot/log.txt
  apt install -y php7.3-fpm php7.3-apcu php7.3-curl php7.3-cgi php7.3-gd php7.3-mbstring php7.3-xml php7.3-zip php7.3-sqlite3
  telegram "apt install finished : php etc"
  echo "install finished : php etc">>/boot/log.txt
}


createpostboot(){
  # /var/lib/dietpi/postboot.d/
  telegram "create postboot"
  echo "create postboot">>/boot/log.txt
  wget "https://blackbox.surfwijzer.nl/postboot.sh" -O /var/lib/dietpi/postboot.d/postboot.sh
  chmod +x /var/lib/dietpi/postboot.d/postboot.sh
}

start(){
  find_IPv4_information
  sendhash
  setupvarsconf
  piholeftlconf
  createpostboot
  aptinstall
  #piholeinstall
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




