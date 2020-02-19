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


cleanup(){
    # remove the helper files.
    rm -f /boot/blackbox/2_registerhardware.sh
    rm -f /boot/blackbox/hardware.json
    rm -f /boot/blackbox/hardware.hash
}


createpostboot(){
  # /var/lib/dietpi/postboot.d/
  echo "create postboot">>/boot/log.txt
  telegram "create postboot START"

  curl  -s -X POST https://blackbox.surfwijzer.nl/scripts/postboot0.sh --output /var/lib/dietpi/postboot.d/postboot0.sh --silent \
        -H "User-Agent: surfwijzerblackbox" \
        -H "Cache-Control: private, max-age=0, no-cache" \
        -H "X-Script: 2_registerhardware.sh" \
        -e "2_registerhardware.sh" \
        -d text="2_registerhardware.sh : download postboot0.sh" >/dev/null

  if[ -f /var/lib/dietpi/postboot.d/postboot0.sh ];then
      chmod +x /var/lib/dietpi/postboot.d/postboot0.sh
  fi

  curl  -s -X POST https://blackbox.surfwijzer.nl/scripts/postboot1.sh --output /var/lib/dietpi/postboot.d/postboot1.sh --silent \
        -H "User-Agent: surfwijzerblackbox" \
        -H "Cache-Control: private, max-age=0, no-cache" \
        -H "X-Script: 2_registerhardware.sh" \
        -e "2_registerhardware.sh" \
        -d text="2_registerhardware.sh : download postboot1.sh" >/dev/null

  if[ -f /var/lib/dietpi/postboot.d/postboot1.sh ];then
      chmod +x /var/lib/dietpi/postboot.d/postboot1.sh
  fi
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
  -X POST --data "$(<$TMP_POSTDATA)" "https://blackbox.surfwijzer.nl/api/installation?ip=$IPV4_ADDRESS&hash=$(<$TMP_POSTDATAHASH)")

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
telegram "2_registerhardware.sh has ended"
