#!/bin/bash
sudo="sudo"
URL_OLD_HOSTS=/etc/hosts
URL_NEW_HOSTS=https://raw.githubusercontent.com/OSMeteor/systools/master/hosts/list/hostslaod
$sudo curl -sL $URL_NEW_HOSTS >> $URL_OLD_HOSTS
