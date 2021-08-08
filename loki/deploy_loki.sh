#!/bin/bash
cd lokideploy
## ./deploy_loki_to_openshift.sh -r=3 -dm=true -sp=none -s3ep=s3://user:password@minio.loki.svc.cluster.local:9000/bucket
./deploy_loki_to_openshift.sh -r=3 -dm=false -sp=none -s3ep=https://key:password@cluster-end-point/bucket-name
cd ..


