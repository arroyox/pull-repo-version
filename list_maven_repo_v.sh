#!/bin/bash

# Requires: curl, jq

read -p "Enter Maven groupId (e.g., androidx.appcompat): " GROUP
read -p "Enter Maven artifactId (e.g., appcompat): " ARTIFACT

OUT="mavenversion.txt"
: > "$OUT"

# For Maven Central API, replace '.' with '+'
GROUP_API=$(echo "$GROUP" | sed 's/\./\+/g')
# For mvnrepository.com, replace '.' with '/'
GROUP_SLASH=$(echo "$GROUP" | sed 's/\./\//g')

ROWS=100
PAGE=0

while :; do
    RESP=$(curl -s "https://search.maven.org/solrsearch/select?q=g:%22${GROUP_API}%22+AND+a:%22${ARTIFACT}%22&core=gav&rows=$ROWS&start=$((PAGE*ROWS))&wt=json")
    COUNT=$(echo "$RESP" | jq '.response.docs | length')
    if [ "$COUNT" -eq 0 ]; then break; fi

    echo "$RESP" | jq -r --arg GROUP "$GROUP" --arg ARTIFACT "$ARTIFACT" --arg GROUP_SLASH "$GROUP_SLASH" '
      .response.docs[] | "\(.v)\thttps://search.maven.org/artifact/\($GROUP)/\($ARTIFACT)/\(.v)/jar\thttps://mvnrepository.com/artifact/\($GROUP_SLASH)/\($ARTIFACT)/\(.v)"' >> "$OUT"

    if [ "$COUNT" -lt "$ROWS" ]; then break; fi
    PAGE=$((PAGE+1))
done

echo "Saved versions and URLs to $OUT"
