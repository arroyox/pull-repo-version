#!/bin/bash

# Prompt the user for the PyPI project URL
read -p "Enter PyPI project URL (e.g., https://pypi.org/project/setuptools/): " URL

# Extract the package name from the URL
PKG=$(echo "$URL" | sed -E 's|.*/project/([^/]+)/?.*|\1|')

if [[ -z "$PKG" ]]; then
    echo "Could not extract package name from URL."
    exit 1
fi

OUT="version_pypi.txt"
: > "$OUT"

# Pull all versions and format as: https://pypi.org/project/<package>/<version>/
VERS=$(curl -s "https://pypi.org/pypi/${PKG}/json" | jq -r '.releases | keys[]' | sort -V)
for VER in $VERS; do
    echo "https://pypi.org/project/${PKG}/${VER}/" >> "$OUT"
done

echo "Saved version URLs to $OUT"
