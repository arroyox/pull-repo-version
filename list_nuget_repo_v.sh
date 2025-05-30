#!/bin/bash

read -p "Enter NuGet package name (e.g., Newtonsoft.Json): " PKG

OUT="version_nuget.txt"
: > "$OUT"

VERS=$(curl -s "https://api.nuget.org/v3-flatcontainer/${PKG,,}/index.json" | jq -r '.versions[]')
for VER in $VERS; do
    echo -e "https://www.nuget.org/packages/${PKG}/${VER}" >> "$OUT"
done

echo "Saved versions and URLs to $OUT"
root@W-5CG4331HH8:~#
