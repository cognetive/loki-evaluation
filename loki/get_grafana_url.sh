#!/bin/bash
oc project loki
url="http://"$(oc get route grafana -o=jsonpath="{.status.ingress[0].host}")
echo "Use the following URL to access Grafana"
echo "-=-=-=-=-=-=-=-=-=-=-"
echo $url
