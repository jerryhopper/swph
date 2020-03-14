

find_static_IPv4_information(){
  STATIC_IPV4_ADDRESS=$(ip addr show eth0|grep "scope global eth0"|awk  '{print $2}')
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

# Get available interfaces that are UP
get_available_interfaces() {
    # There may be more than one so it's all stored in a variable
    availableInterfaces=$(ip --oneline link show up | grep -v "lo" | awk '{print $2}' | cut -d':' -f1 | cut -d'@' -f1)
}


# configure networking via dhcpcd
setDHCPCD() {
    # check if the IP is already in the file
    if grep -q "${IPV4_ADDRESS}" /etc/dhcpcd.conf; then
        printf "  %b Static IP already configured\\n" "${INFO}"
    # If it's not,
    else
        # we can append these lines to dhcpcd.conf to enable a static IP
        echo "interface ${PIHOLE_INTERFACE}
        static ip_address=${IPV4_ADDRESS}
        static routers=${IPv4gw}
        static domain_name_servers=127.0.0.1" | tee -a /etc/dhcpcd.conf >/dev/null
        # Then use the ip command to immediately set the new address
        ip addr replace dev "${PIHOLE_INTERFACE}" "${IPV4_ADDRESS}"
        # Also give a warning that the user may need to reboot their system
        printf "  %b Set IP address to %s \\n  You may need to restart after the install is complete\\n" "${TICK}" "${IPV4_ADDRESS%/*}"
    fi
}

# configure networking ifcfg-xxxx file found at /etc/sysconfig/network-scripts/
# this function requires the full path of an ifcfg file passed as an argument
setIFCFG() {
    # Local, named variables
    local IFCFG_FILE
    local IPADDR
    local CIDR
    IFCFG_FILE=$1
    printf -v IPADDR "%s" "${IPV4_ADDRESS%%/*}"
    # check if the desired IP is already set
    if grep -Eq "${IPADDR}(\\b|\\/)" "${IFCFG_FILE}"; then
        printf "  %b Static IP already configured\\n" "${INFO}"
    # Otherwise,
    else
        # Put the IP in variables without the CIDR notation
        printf -v CIDR "%s" "${IPV4_ADDRESS##*/}"
        # Backup existing interface configuration:
        cp "${IFCFG_FILE}" "${IFCFG_FILE}".pihole.orig
        # Build Interface configuration file using the GLOBAL variables we have
        {
        echo "# Configured via Pi-hole installer"
        echo "DEVICE=$PIHOLE_INTERFACE"
        echo "BOOTPROTO=none"
        echo "ONBOOT=yes"
        echo "IPADDR=$IPADDR"
        echo "PREFIX=$CIDR"
        echo "GATEWAY=$IPv4gw"
        echo "DNS1=$PIHOLE_DNS_1"
        echo "DNS2=$PIHOLE_DNS_2"
        echo "USERCTL=no"
        }> "${IFCFG_FILE}"
        # Use ip to immediately set the new address
        ip addr replace dev "${PIHOLE_INTERFACE}" "${IPV4_ADDRESS}"
        # If NetworkMangler command line interface exists and ready to mangle,
        if is_command nmcli && nmcli general status &> /dev/null; then
            # Tell NetworkManagler to read our new sysconfig file
            nmcli con load "${IFCFG_FILE}" > /dev/null
        fi
        # Show a warning that the user may need to restart
        printf "  %b Set IP address to %s\\n  You may need to restart after the install is complete\\n" "${TICK}" "${IPV4_ADDRESS%%/*}"
    fi
}

setStaticIPv4() {
    # Local, named variables
    local IFCFG_FILE
    local CONNECTION_NAME

    # If a static interface is already configured, we are done.
    if [[ -r "/etc/sysconfig/network/ifcfg-${PIHOLE_INTERFACE}" ]]; then
        if grep -q '^BOOTPROTO=.static.' "/etc/sysconfig/network/ifcfg-${PIHOLE_INTERFACE}"; then
            return 0
        fi
    fi
    # For the Debian family, if dhcpcd.conf exists,
    if [[ -f "/etc/dhcpcd.conf" ]]; then
        # configure networking via dhcpcd
        setDHCPCD
        return 0
    fi
    # If a DHCPCD config file was not found, check for an ifcfg config file based on interface name
    if [[ -f "/etc/sysconfig/network-scripts/ifcfg-${PIHOLE_INTERFACE}" ]];then
        # If it exists,
        IFCFG_FILE=/etc/sysconfig/network-scripts/ifcfg-${PIHOLE_INTERFACE}
        setIFCFG "${IFCFG_FILE}"
        return 0
    fi
    # if an ifcfg config does not exists for the interface name, try the connection name via network manager
    if is_command nmcli && nmcli general status &> /dev/null; then
        CONNECTION_NAME=$(nmcli dev show "${PIHOLE_INTERFACE}" | grep 'GENERAL.CONNECTION' | cut -d: -f2 | sed 's/^System//' | xargs | tr ' ' '_')
        if [[ -f "/etc/sysconfig/network-scripts/ifcfg-${CONNECTION_NAME}" ]];then
            # If it exists,
            IFCFG_FILE=/etc/sysconfig/network-scripts/ifcfg-${CONNECTION_NAME}
            setIFCFG "${IFCFG_FILE}"
            return 0
        fi
    fi
    # If previous conditions failed, show an error and exit
    printf "  %b Warning: Unable to locate configuration file to set static IPv4 address\\n" "${INFO}"
    exit 1
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


