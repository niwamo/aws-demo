#!/bin/bash

# EBS should be visible as /dev/xvd?
# /dev/xvda should be root disk

drive=$(ls /dev/xvd? | tail -n 1)
if [ "$drive" = "/dev/xvda" ]; then
    sleep 60
    drive=$(ls /dev/xvd? | tail -n 1)
    if [ "$drive" = "/dev/xvda" ]; then
        exit 1
    fi
fi

if [ "$(file -sL $drive | grep ext4)" = "" ]; then
    mkfs.ext4 $drive
fi

if ! [ -d /ebs ]; then
    mkdir /ebs
fi

set -e
mount $drive /ebs

if ! [ -d /ebs/aws-demo-db ]; then
    mkdir /ebs/aws-demo-db
    mongod --dbpath /ebs/aws-demo-db --fork --logpath /dev/null
    mongo pastebin --eval "db.createUser({user:'aws-demo',pwd:'aws-demo',roles:['dbOwner']}); db['active-bins'].insert({ timestamp: 1743704875, title: 'firstBin', content: 'firstBinContents' })"
    mongod --dbpath /ebs/aws-demo-db --shutdown
    sleep 1
fi

chown -R mongodb /ebs/aws-demo-db