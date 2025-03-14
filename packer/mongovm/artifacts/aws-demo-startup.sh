#!/bin/bash

# EBS should be visible as /dev/xvd?
# /dev/xvda should be root disk

drive=$(ls /dev/xvd? | tail -n 1)
if [ "$drive" = "/dev/xvda" ]; then
    exit 1
fi

partition="${drive}1"

if ! [ -f $partition ]; then
    mkfs.ext4 $drive
fi

if ! [ -d /ebs ]; then
    mkdir /ebs
fi

mount $partition /ebs

if ! [ -d /ebs/aws-demo-db ]; then
    mkdir /ebs/aws-demo-db
    mongod --dbpath /ebs/aws-demo-db --fork --logpath /dev/null
    mongo aws-demo --eval "db.createUser({user:'aws-demo',pwd:'aws-demo',roles:['dbOwner']}); db.docs.insert({init:'init'})"
    mongod --dbpath /ebs/aws-demo-db --shutdown
    sleep 1
fi

chown -R mongodb /ebs/aws-demo-db