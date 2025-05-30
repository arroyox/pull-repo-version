#!/bin/bash

set -e

if ! command -v curl >/dev/null; then
  echo "Error: curl not found"
  exit 1
fi
if ! command -v jq >/dev/null; then
  echo "Error: jq not found"
  exit 1
fi

GROUP=${1}
ARTIFACT=${2}
if [[ -z "$GROUP" ]]; then
  read -p "Enter Maven groupId: " GROUP
fi
if [[ -z "$ARTIFACT" ]]; then
  read -p "Enter Maven artifactId: " ARTIFACT
fi

OUT="version_mvn.txt"
: > "$OUT"

ROWS=100
PAGE=0

while :; do
    API_URL="https://search.maven.org/solrsearch/select?q=g:%22${GROUP}%22+AND+a:%22${ARTIFACT}%22&core=gav&rows=$ROWS&start=$((PAGE*ROWS))&wt=json"
    # Add User-Agent header!
    RESP=$(curl -s -H "User-Agent: Mozilla/5.0 (compatible; MyScript/1.0)" -w "\n%{http_code}" "$API_URL")
    HTTP_STATUS=$(echo "$RESP" | tail -n1)
    BODY=$(echo "$RESP" | sed '$d')

    if [ "$HTTP_STATUS" -ne 200 ]; then
        echo "Error: HTTP $HTTP_STATUS from server. Stopping at page $PAGE."
        break
    fi

    COUNT=$(echo "$BODY" | jq '.response.docs | length')
    if [ "$COUNT" -eq 0 ]; then break; fi

    echo "$BODY" | jq -r --arg GROUP "$GROUP" --arg ARTIFACT "$ARTIFACT" '
      .response.docs[] | "https://search.maven.org/artifact/\($GROUP)/\($ARTIFACT)/\(.v)/jar"' >> "$OUT"

    echo "Fetched page $((PAGE+1)), $COUNT results"
    if [ "$COUNT" -lt "$ROWS" ]; then break; fi
    PAGE=$((PAGE+1))
    sleep 1
done

echo "Saved URLs to $OUT"
