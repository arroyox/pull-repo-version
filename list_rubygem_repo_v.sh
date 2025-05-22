#!/bin/bash

read -p "Enter RubyGem name (e.g., rails): " GEM

OUT="rubygemversion.txt"
: > "$OUT"

VERS=$(curl -s "https://rubygems.org/api/v1/versions/${GEM}.json" | jq -r '.[].number')
for VER in $VERS; do
    echo -e "${VER}\thttps://rubygems.org/gems/${GEM}/versions/${VER}" >> "$OUT"
done

echo "Saved versions and URLs to $OUT"
