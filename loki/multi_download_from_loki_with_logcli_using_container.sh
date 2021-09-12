#!/bin/bash
POD_YAML=pod_template_download_from_loki.yaml
DAY="2019-12-01"
FILE_NAME_PRE_JSON="CLEANED_1f34622021"

first_hour=00
last_hour=00
delay=60
loki_endpoint="loki-endpoint"

show_usage() {
  echo "
usage: multi_download_file [options]
  options:
    -le   --loki_endpoint                  Loki query frontend endpoint
    -fh   --first_hour=[enum]              first Logfile hour (default: $first_hour)
    -lh   --last_hour=[enum]               Last Logfile hour (default: $last_hour)
    -d   --delay=[enum]                    Delay in seconds between starts of downloaders (default: $delay)
    -h,   --help                           Show usage
"
  exit 0
}

for i in "$@"; do
  case $i in
  -le=* | --loki_endpoint=*)
    loki_endpoint="${i#*=}"
    shift
    ;;
  -fh=* | --first_hour=*)
    first_hour="${i#*=}"
    shift
    ;;
  -lh=* | --last_hour=*)
    last_hour="${i#*=}"
    shift
    ;;
  -d=* | --delay=*)
    delay="${i#*=}"
    shift
    ;;
  -h | --help | *) show_usage ;;
  esac
done

show_configuration() {

  echo "
Note: get more deployment options with -h

Configuration:
-=-=-=-=-=-=-
first_hour --> $first_hour
last_hour --> $last_hour
delay --> $delay
loki_endpoint --> $loki_endpoint
"
}

deploy() {
  oc adm policy add-scc-to-user privileged -z downloadfromloki-service-account
  oc adm policy add-cluster-role-to-user cluster-reader -z downloadfromloki-service-account
  echo "==> Deleting old pods"
  oc delete pod --ignore-not-found=true --wait=true -l appType=downloadfromloki
  for HOUR in $(eval echo "{$first_hour..$last_hour}"); do
    echo "==> Processing ${DAY}T${HOUR}"
    POD_NAME="downloadfromloki."$DAY"."$HOUR
    FILE_NAME_JSON="/tmp/${FILE_NAME_PRE_JSON}.${DAY}.${HOUR}00.json"
    echo "==> Starting new pod"
    oc process -f $POD_YAML \
      -p loki_endpoint="$loki_endpoint" \
      -p file_name_json="$FILE_NAME_JSON" \
      -p pod_name="$POD_NAME" |
      oc apply -f -
    if [ "$hold_until_completion" = "false" ]; then
      echo "Wait until this download finished"
      while true; do
        sleep 10
        LINE=$(oc logs $POD_NAME 2>/dev/null | grep "DONE --> ")
        if [ -n "$LINE" ]; then
          echo $LINE
          echo $(date)" ==> DOWNLOAD COMPLETE FOR FILE $FILE_NAME_JSON"
          break
        fi
        sleep 10
        echo "."
      done
    else
      echo "waiting $delay seconds before next container is created"
      sleep $delay
    fi
  done
}

wait_for_complete() {
  while true; do
    echo $(date) "Status report:"
    echo "---------------------"
    completed=0
    for HOUR in $(eval echo "{$first_hour..$last_hour}"); do
      DOWNLOADER_POD="downloadfromloki."$DAY"."$HOUR
      COMPLETE=$(oc logs $DOWNLOADER_POD 2>/dev/null | grep "DONE --> ")
      echo $COMPLETE
      if [ -n "$COMPLETE" ]; then
        completed=$((completed + 1))
      fi
    done
    to_complete=$((last_hour - first_hour + 1))
    if [ $to_complete = $completed ]; then
      break
    fi
    sleep 30
  done
}

main() {
  show_configuration
  download_start_time=$(date)
  echo $(date) "===>>>> DOWNLOAD START !!!! "
  deploy
  wait_for_complete
  download_end_time=$(date)
  start_sec=$(date -d "$download_start_time" +%s)
  end_sec=$(date -d "$download_end_time" +%s)
  echo $(date) "===>>>> DOWNLOAD COMPLETE in $((end_sec - start_sec)) seconds !!!! -- started at $download_start_time ended at $download_end_time"
}

main
