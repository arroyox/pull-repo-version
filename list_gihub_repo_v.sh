#!/bin/bash

# Script to list ALL tags and their commit URLs for a GitHub repo

read -p "Enter the GitHub repository URL (e.g., https://github.com/owner/repo): " REPO_URL

# Remove trailing slash if present
REPO_URL="${REPO_URL%/}"

# Extract owner and repository name
if [[ "$REPO_URL" =~ github\.com/([^/]+)/([^/]+)$ ]]; then
    OWNER="${BASH_REMATCH[1]}"
    REPO="${BASH_REMATCH[2]}"
else
    echo "Invalid GitHub repository URL."
    exit 1
fi

OUTPUT_FILE="githubversion.txt"
> "$OUTPUT_FILE"

PAGE=1
PER_PAGE=100
while :; do
    # Get a page of tags from the GitHub API
    TAGS=$(curl -s "https://api.github.com/repos/$OWNER/$REPO/tags?per_page=$PER_PAGE&page=$PAGE")
    TAGNAMES=($(echo "$TAGS" | grep '"name":' | cut -d '"' -f4))
    SHAS=($(echo "$TAGS" | grep '"sha":' | cut -d '"' -f4 | head -n ${#TAGNAMES[@]}))
    if [ ${#TAGNAMES[@]} -eq 0 ]; then
        break
    fi
    for i in "${!TAGNAMES[@]}"; do
        echo -e "${TAGNAMES[$i]}\t${REPO_URL}/commit/${SHAS[$i]}" >> "$OUTPUT_FILE"
    done
    # If fewer than PER_PAGE tags, we're done
    if [ ${#TAGNAMES[@]} -lt $PER_PAGE ]; then
        break
    fi
    PAGE=$((PAGE+1))
done

echo "Done. All version-tagged commit URLs are saved in $OUTPUT_FILE"
