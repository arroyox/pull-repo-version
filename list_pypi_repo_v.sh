#!/bin/bash

read -p "Enter PyPI package name (e.g., requests): " PKG

OUT="pyversion.txt"
: > "$OUT"

VERS=$(curl -s "https://pypi.org/pypi/${PKG}/json" | jq -r '.releases | keys[]')
for VER in $VERS; do
    echo -e "${VER}\thttps://pypi.org/project/${PKG}/${VER}/" >> "$OUT"
done

echo "Saved versions and URLs to $OUT"
