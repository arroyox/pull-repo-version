#!/bin/bash

read -p "Enter Debian package name (e.g., curl): " PKG

OUT="debianversion.txt"
: > "$OUT"

VERS=$(curl -s "https://sources.debian.org/api/src/${PKG}/" | jq -r '.versions[].version')
for VER in $VERS; do
    echo -e "${VER}\thttps://sources.debian.org/src/${PKG}/${VER}/" >> "$OUT"
done

echo "Saved versions and URLs to $OUT"
