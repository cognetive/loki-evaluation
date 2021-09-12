#!/bin/bash
DEPLOY_YAML=pod_template_upload_file_to_loki.yaml
### COS END-POINT
SOURCE_S3_BUCKET="source-bucket-name"
SOURCE_S3_ENDPOINT="source-s3-endpoint"
SOURCE_S3_CREDENTIALS="source-s3-credentials"
SOURCE_S3_FOLDER=""
DAY="2019-12-01"
FILE_NAME_PRE_JSON="CLEANED_1f34622021"

last_hour=00
loki_endpoint="loki-endpoint"

show_usage() {
  echo "
usage: multi_upload_file [options]
  options:
    -le   --loki_endpoint                  Loki distributors endpoint
    -lh   --last_hour=[enum]               Last Logfile hour (default: 00)
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
  -lh=* | --last_hour=*)
    last_hour="${i#*=}"
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
last_hour --> $last_hour
loki_endpoint --> $loki_endpoint
"
}

deploy() {
  oc adm policy add-scc-to-user privileged -z uploadtoloki-service-account
  oc adm policy add-cluster-role-to-user cluster-reader -z uploadtoloki-service-account
  for HOUR in $(eval echo "{00..$last_hour}"); do
    FILE_NAME_JSON=$FILE_NAME_PRE_JSON"."$DAY"."$HOUR"00.json"
    POD_NAME="uploadtoloki."$DAY"."$HOUR
    echo "starting container upload for $FILE_NAME_JSON"
    oc delete pod --ignore-not-found=true --wait=true $POD_NAME
    oc process -f $DEPLOY_YAML \
      -p loki_endpoint="$loki_endpoint" \
      -p file_name_json="$FILE_NAME_JSON" \
      -p source_s3_bucket="$SOURCE_S3_BUCKET" \
      -p source_s3_endpoint="$SOURCE_S3_ENDPOINT" \
      -p source_s3_credentials="$SOURCE_S3_CREDENTIALS" \
      -p source_s3_folder="$SOURCE_S3_FOLDER" \
      -p pod_name="$POD_NAME" |
      oc apply -f -
    if [ "$hold_until_completion" = "false" ]; then
      echo "Wait until this upload finish"
      while true; do
        sleep 10
        UPLOADER_POD=$(oc get pod -l app=$POD_NAME -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)
        LINE=$(oc logs $UPLOADER_POD 2>/dev/null | grep "DONE --> ")
        if [ -n "$LINE" ]; then
          echo $LINE
          echo $(date)" ==> UPLOAD COMPLETE FOR FILE $FILE_NAME_JSON"
          break
        fi
        sleep 10
        echo "."
      done
    else
      echo "waiting 180 seconds before next container is created"
      sleep 180
    fi
  done
}

wait_for_complete() {
  while true; do
    echo $(date) "Status report:"
    echo "---------------------"
    completed=0
    for HOUR in $(eval echo "{00..$last_hour}"); do
      POD_NAME="uploadtoloki."$DAY"."$HOUR
      UPLOADER_POD=$(oc get pod -l app=$POD_NAME -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)
      COMPLETE=$(oc logs $UPLOADER_POD 2>/dev/null | grep "DONE --> ")
      echo $COMPLETE
      if [ -n "$COMPLETE" ]; then
        completed=$((completed + 1))
      fi
    done
    to_complete=$((last_hour + 1))
    if [ $to_complete = $completed ]; then
      break
    fi
    sleep 30
  done
}

main() {
  show_configuration
  upload_start_time=$(date)
  echo $(date) "===>>>> UPLOAD START !!!! "
  deploy
  wait_for_complete
  upload_end_time=$(date)
  echo $(date) "===>>>> UPLOAD COMPLETE !!!! -- started at $upload_start_time ended at $upload_end_time"
}

main
