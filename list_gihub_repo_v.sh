#!/bin/bash
# filepath: list_github_repo_v3.sh
set -euo pipefail

GITHUB_TOKEN="your_GIT_HUB_TOKEN"

echo "Script to list commit URLs from ALL branches and ALL tags of a GitHub repo"
read -rp "Enter the GitHub repository URL: " REPO_URL

REPO_URL="${REPO_URL%/}"

if [[ "$REPO_URL" =~ github\.com/([^/]+)/([^/]+)$ ]]; then
    OWNER="${BASH_REMATCH[1]}"
    REPO="${BASH_REMATCH[2]}"
    REPO="${REPO%.git}"
else
    echo "Invalid GitHub repository URL."
    exit 1
fi

TEMP_FILE="temp_commits.txt"
OUTPUT_FILE="version_branches_and_tags_commits.txt"
> "$TEMP_FILE"

# Use associative array to track unique commits
declare -A SEEN_COMMITS

echo "=== Fetching all branches ==="

# Fetch all branches
PAGE=1
BRANCH_COUNT=0
while :; do
    API_URL="https://api.github.com/repos/$OWNER/$REPO/branches?per_page=100&page=$PAGE"

    if [[ -n "$GITHUB_TOKEN" ]]; then
        RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$API_URL")
    else
        RESPONSE=$(curl -s "$API_URL")
    fi

    # Check for API errors
    if echo "$RESPONSE" | grep -q '"message":'; then
        echo "GitHub API error: $(echo "$RESPONSE" | jq -r '.message')"
        exit 1
    fi

    COUNT=$(echo "$RESPONSE" | jq 'length')
    if [[ $COUNT -eq 0 ]]; then
        break
    fi

    echo "Processing branch page $PAGE ($COUNT branches)..."

    # Read into array to avoid subshell issues
    mapfile -t SHAS < <(echo "$RESPONSE" | jq -r '.[].commit.sha')
    for SHA in "${SHAS[@]}"; do
        if [[ -z "${SEEN_COMMITS[$SHA]:-}" ]]; then
            echo "${REPO_URL}/commit/${SHA}" >> "$TEMP_FILE"
            SEEN_COMMITS[$SHA]=1
        fi
    done

    BRANCH_COUNT=$((BRANCH_COUNT + COUNT))

    if [[ $COUNT -lt 100 ]]; then
        break
    fi
    PAGE=$((PAGE+1))
done

echo "Total branches processed: $BRANCH_COUNT"

echo "=== Fetching all tags ==="

# Fetch all tags
PAGE=1
TAG_COUNT=0
while :; do
    API_URL="https://api.github.com/repos/$OWNER/$REPO/tags?per_page=100&page=$PAGE"

    if [[ -n "$GITHUB_TOKEN" ]]; then
        RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$API_URL")
    else
        RESPONSE=$(curl -s "$API_URL")
    fi

    # Check for API errors
    if echo "$RESPONSE" | grep -q '"message":'; then
        echo "GitHub API error: $(echo "$RESPONSE" | jq -r '.message')"
        exit 1
    fi

    COUNT=$(echo "$RESPONSE" | jq 'length')
    if [[ $COUNT -eq 0 ]]; then
        break
    fi

    echo "Processing tag page $PAGE ($COUNT tags)..."

    # Read into array to avoid subshell issues
    mapfile -t SHAS < <(echo "$RESPONSE" | jq -r '.[].commit.sha')
    for SHA in "${SHAS[@]}"; do
        if [[ -z "${SEEN_COMMITS[$SHA]:-}" ]]; then
            echo "${REPO_URL}/commit/${SHA}" >> "$TEMP_FILE"
            SEEN_COMMITS[$SHA]=1
        fi
    done

    TAG_COUNT=$((TAG_COUNT + COUNT))

    if [[ $COUNT -lt 100 ]]; then
        break
    fi
    PAGE=$((PAGE+1))
done

echo "Total tags processed: $TAG_COUNT"

# Move temp file to final output
mv "$TEMP_FILE" "$OUTPUT_FILE"

UNIQUE_COUNT=$(wc -l < "$OUTPUT_FILE")

echo ""
echo "Done! Summary:"
echo "  - Branches: $BRANCH_COUNT"
echo "  - Tags: $TAG_COUNT"
echo "  - Total entries: $((BRANCH_COUNT + TAG_COUNT))"
echo "  - Unique commits: $UNIQUE_COUNT"
echo "  - Duplicates removed: $((BRANCH_COUNT + TAG_COUNT - UNIQUE_COUNT))"
echo "  - Output saved to: $OUTPUT_FILE"
