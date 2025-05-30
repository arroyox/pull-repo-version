#!/bin/bash

read -p "Enter Debian package name (e.g., debian-cd): " PKG

OUT="version_debian.txt"
: > "$OUT"

# Try both /src/ and /main/ endpoints
for BASE in src main; do
    URL="https://sources.debian.org/${BASE}/${PKG}/"
    # Check if the page exists
    if curl -sf "$URL" > /dev/null; then
        VERSIONS=$(curl -s "$URL" | grep -oP "/${BASE}/${PKG}/\K[^/]+(?=/)" | sort -Vr)
        for VER in $VERSIONS; do
            echo "https://ftp.sources.debian.org/${BASE}/${PKG}/${VER}/" >> "$OUT"
        done
    fi
done

if [ -s "$OUT" ]; then
    echo "Saved version URLs to $OUT"
else
    echo "No versions found for package '$PKG' in /src/ or /main/."
fi
