#!/bin/bash

#
var=$(grep "iface eth0" /etc/network/interfaces|awk '{print $4}')

echo $var
