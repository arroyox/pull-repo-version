#!/bin/bash

read -p "Enter Go module path (e.g., github.com/jfrog/jfrog-client-go): " MODULE

VERS=$(curl -s "https://proxy.golang.org/${MODULE}/@v/list")
OUT="version_go.txt"
: > "$OUT"

for VER in $VERS; do
    echo -e "https://pkg.go.dev/${MODULE}@${VER}" >> "$OUT"
done

echo "Saved versions and URLs to $OUT"
