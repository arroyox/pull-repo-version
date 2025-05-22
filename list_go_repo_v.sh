#!/bin/bash

read -p "Enter Go module path (e.g., github.com/jfrog/jfrog-client-go): " MODULE

VERS=$(curl -s "https://proxy.golang.org/${MODULE}/@v/list")
OUT="goversion.txt"
: > "$OUT"

for VER in $VERS; do
    echo -e "${VER}\thttps://pkg.go.dev/${MODULE}@${VER}" >> "$OUT"
done

echo "Saved versions and URLs to $OUT"
