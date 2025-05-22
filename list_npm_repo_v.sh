#!/bin/bash

read -p "Enter npm package name (e.g., lodash): " PKG

OUT="npmversion.txt"
: > "$OUT"

VERS=$(curl -s "https://registry.npmjs.org/${PKG}" | jq -r '.versions | keys[]')
for VER in $VERS; do
    echo -e "${VER}\thttps://www.npmjs.com/package/${PKG}/v/${VER}" >> "$OUT"
done

echo "Saved versions and URLs to $OUT"
