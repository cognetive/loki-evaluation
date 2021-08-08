#!/bin/bash

if ! command -v promtail &> /dev/null; then
  curl -s https://api.github.com/repos/grafana/loki/releases/latest | grep browser_download_url |  cut -d '"' -f 4 | grep promtail-linux-amd64.zip | wget -i -
  unzip promtail-linux-amd64.zip
  sudo mv promtail-linux-amd64 /usr/local/bin/promtail
fi

if [ ! -f /mnt/uncompress/CLEANED.0000.json ]; then
  mkdir -p /mnt/uncompress
  cp /mnt/location/train/CLEANED.0000.json.gz /mnt/uncompress/CLEANED.0000.json.gz
  gzip -f -d /mnt/uncompress/CLEANED.0000.json.gz
  ls -lah /mnt/uncompress/CLEANED.0000.json
fi

promtail -config.file=promtail-config.yaml

