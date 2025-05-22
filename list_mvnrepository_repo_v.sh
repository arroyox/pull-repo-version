#!/bin/bash

read -p "Enter Maven groupId: " GROUP
read -p "Enter Maven artifactId: " ARTIFACT

OUT="mavencentralversion.txt"
: > "$OUT"

# DO NOT replace . with + here!
ROWS=100
PAGE=0

while :; do
    API_URL="https://search.maven.org/solrsearch/select?q=g:%22${GROUP}%22+AND+a:%22${ARTIFACT}%22&core=gav&rows=$ROWS&start=$((PAGE*ROWS))&wt=json"
    RESP=$(curl -s "$API_URL")
    COUNT=$(echo "$RESP" | jq '.response.docs | length')
    if [ "$COUNT" -eq 0 ]; then break; fi

    echo "$RESP" | jq -r --arg GROUP "$GROUP" --arg ARTIFACT "$ARTIFACT" '
      .response.docs[] | "\(.v)\thttps://search.maven.org/artifact/\($GROUP)/\($ARTIFACT)/\(.v)/jar"' >> "$OUT"

    if [ "$COUNT" -lt "$ROWS" ]; then break; fi
    PAGE=$((PAGE+1))
done

echo "Saved versions and URLs to $OUT"
