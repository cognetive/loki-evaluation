#!/bin/bash

if ! command -v td-agent &> /dev/null
then
  sudo curl -L https://toolbelt.treasuredata.com/sh/install-redhat-td-agent4.sh | sh
  sudo /usr/sbin/td-agent-gem install fluent-plugin-grafana-loki
fi

if [ ! -f /mnt/uncompress/CLEANED.0000.json ]; then
  mkdir -p /mnt/uncompress
  cp /mnt/location/CLEANED.0000.json.gz /mnt/uncompress/CLEANED.0000.json.gz
  gzip -f -d /mnt/uncompress/CLEANED.0000.json.gz
  ls -lah /mnt/uncompress/CLEANED.0000.json
fi

sudo td-agent -c fluentd.conf
