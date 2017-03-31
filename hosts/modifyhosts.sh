#!/bin/bash
sudo="sudo"
URL_OLD_HOSTS=/Users/osmeteor/Desktop/softtek/docker/hosts/hosts
URL_NEW_HOSTS=http://googlehosts-hostsfiles.stor.sinaapp.com/hosts
$sudo echo 'begine'
if [ `grep "http://www.findspace.name" $URL_OLD_HOSTS | wc -l` -gt 0 ]; then
    BEGIN=$(grep -n "^#+BEGIN" $URL_OLD_HOSTS | awk -F: '{print $1}')
    diff -Naur <(tail -n +$BEGIN $URL_OLD_HOSTS) <(curl -sL $URL_NEW_HOSTS) | patch -p1 $URL_OLD_HOSTS
else 
    $sudo curl -sL $URL_NEW_HOSTS >> $URL_OLD_HOSTS
fi
