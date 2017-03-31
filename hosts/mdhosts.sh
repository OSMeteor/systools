#!/bin/bash
sudo="sudo"
URL_OLD_HOSTS=/etc/hosts
URL_NEW_HOSTS=https://raw.githubusercontent.com/OSMeteor/systools/master/hosts/list/hostslaod
read -r -p " This shell will overwrite /etc/hosts. press any key to continue " input
BEGIN=$(grep -n "^#+BEGIN" $URL_OLD_HOSTS | awk -F: '{print $1}')
diff -Naur <(tail -n +$BEGIN $URL_OLD_HOSTS) <(curl -sL $URL_NEW_HOSTS) | patch -p1 $URL_OLD_HOSTS
$sudo curl -sL $URL_NEW_HOSTS >> $URL_OLD_HOSTS
echo "write success to $URL_OLD_HOSTS..."
