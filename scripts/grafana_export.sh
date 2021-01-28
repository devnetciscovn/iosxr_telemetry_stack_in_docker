#!/bin/bash

KEY='eyJrIjoiWjJwenNtcTgyZTE1SElIZHo0Y3F6Mk0ybkJDbzRWcDUiLCJuIjoiZXhwb3J0X2Rhc2giLCJpZCI6MX0='
HOST=http://10.51.117.221:3000

#mkdir -p dashboards && for dash in $(curl -k -H "Authorization: Bearer $KEY" "$HOST/api/search?query=&" | jq -r '.[] | select(.type == "dash-db") | .uid'); do 
#	curl -k -H "Authorization: Bearer $KEY" "$HOST/api/dashboards/uid/$dash" > dashboards/"$dash".json 
#done



set -o errexit
set -o pipefail


[ -n "$KEY" ] || ( echo "No API key found. Get one from $HOST/org/apikeys and run 'KEY=<API key> $0'"; exit 1)

set -o nounset

echo "Exporting Grafana dashboards from $HOST"
rm -rf dashboards
mkdir -p dashboards
for dash in $(curl -s -H "Authorization: Bearer $KEY" "$HOST/api/search?query=&" | jq -r '.[] | select(.type == "dash-db") | .uid'); do
	curl -s -H "Authorization: Bearer $KEY" "$HOST/api/dashboards/uid/$dash" | jq -r '.' > dashboards/${dash}.json
	slug=$(cat dashboards/${dash}.json | jq -r '.meta.slug')
	mv dashboards/${dash}.json dashboards/${slug}.json
done

