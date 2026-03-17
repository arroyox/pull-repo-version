#!/bin/bash
# filepath: list_github_project.sh
set -euo pipefail

GITHUB_TOKEN="YOUR_GITHUB_TOKEN"

# Helper: make a GitHub API GET request with optional auth
github_api() {
    local url="$1"
    if [[ -n "$GITHUB_TOKEN" ]]; then
        curl -s -H "Authorization: token $GITHUB_TOKEN" "$url"
    else
        curl -s "$url"
    fi
}

echo "Script to list commit URLs from ALL repos, branches, and tags of a GitHub org/user"
read -rp "Enter the GitHub organization or username: " OWNER
OWNER="${OWNER##*/}"  # strip URL prefix if user pastes full URL
OWNER="${OWNER%/}"

OUTPUT_FILE="output_${OWNER}_all_commits.txt"
> "$OUTPUT_FILE"

TOTAL_REPOS=0
TOTAL_BRANCHES=0
TOTAL_TAGS=0
TOTAL_UNIQUE=0

# ── Step 1: Discover all repositories ──
echo ""
echo "=== Discovering repositories for '$OWNER' ==="

ALL_REPOS=()
PAGE=1
while :; do
    # Try as org first, fall back to user
    RESPONSE=$(github_api "https://api.github.com/orgs/$OWNER/repos?per_page=100&page=$PAGE" 2>/dev/null)

    if echo "$RESPONSE" | grep -q '"message":\s*"Not Found"'; then
        if [[ $PAGE -eq 1 ]]; then
            echo "Not an org, trying as user..."
            RESPONSE=$(github_api "https://api.github.com/users/$OWNER/repos?per_page=100&page=$PAGE")
            # Check again
            if echo "$RESPONSE" | grep -q '"message":'; then
                echo "GitHub API error: $(echo "$RESPONSE" | jq -r '.message')"
                exit 1
            fi
            # Switch to user endpoint for subsequent pages
            ENDPOINT_TYPE="users"
        else
            break
        fi
    elif echo "$RESPONSE" | grep -q '"message":'; then
        echo "GitHub API error: $(echo "$RESPONSE" | jq -r '.message')"
        exit 1
    else
        if [[ $PAGE -eq 1 ]]; then
            ENDPOINT_TYPE="orgs"
        fi
    fi

    COUNT=$(echo "$RESPONSE" | jq 'length')
    if [[ $COUNT -eq 0 ]]; then
        break
    fi

    mapfile -t REPO_NAMES < <(echo "$RESPONSE" | jq -r '.[].name')
    ALL_REPOS+=("${REPO_NAMES[@]}")

    echo "  Found $COUNT repos on page $PAGE..."

    if [[ $COUNT -lt 100 ]]; then
        break
    fi
    PAGE=$((PAGE + 1))

    # Re-fetch with correct endpoint for page 2+ (handles the org->user fallback)
    if [[ $PAGE -gt 1 && "${ENDPOINT_TYPE:-orgs}" == "users" ]]; then
        RESPONSE=$(github_api "https://api.github.com/users/$OWNER/repos?per_page=100&page=$PAGE")
    fi
done

TOTAL_REPOS=${#ALL_REPOS[@]}
echo "Total repositories found: $TOTAL_REPOS"

if [[ $TOTAL_REPOS -eq 0 ]]; then
    echo "No repositories found for '$OWNER'. Exiting."
    exit 0
fi

# ── Step 2: For each repo, fetch branches and tags ──
for REPO in "${ALL_REPOS[@]}"; do
    REPO_URL="https://github.com/$OWNER/$REPO"
    TEMP_FILE="temp_${REPO}_commits.txt"
    > "$TEMP_FILE"

    declare -A SEEN_COMMITS=()
    BRANCH_COUNT=0
    TAG_COUNT=0

    echo ""
    echo "────────────────────────────────────────"
    echo "Repository: $OWNER/$REPO"
    echo "────────────────────────────────────────"

    # ── Fetch all branches ──
    PAGE=1
    while :; do
        RESPONSE=$(github_api "https://api.github.com/repos/$OWNER/$REPO/branches?per_page=100&page=$PAGE")

        if echo "$RESPONSE" | grep -q '"message":'; then
            echo "  [branches] API error: $(echo "$RESPONSE" | jq -r '.message')"
            break
        fi

        COUNT=$(echo "$RESPONSE" | jq 'length')
        if [[ $COUNT -eq 0 ]]; then
            break
        fi

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
        PAGE=$((PAGE + 1))
    done

    # ── Fetch all tags ──
    PAGE=1
    while :; do
        RESPONSE=$(github_api "https://api.github.com/repos/$OWNER/$REPO/tags?per_page=100&page=$PAGE")

        if echo "$RESPONSE" | grep -q '"message":'; then
            echo "  [tags] API error: $(echo "$RESPONSE" | jq -r '.message')"
            break
        fi

        COUNT=$(echo "$RESPONSE" | jq 'length')
        if [[ $COUNT -eq 0 ]]; then
            break
        fi

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
        PAGE=$((PAGE + 1))
    done

    REPO_UNIQUE=$(wc -l < "$TEMP_FILE")
    cat "$TEMP_FILE" >> "$OUTPUT_FILE"
    rm -f "$TEMP_FILE"

    unset SEEN_COMMITS

    TOTAL_BRANCHES=$((TOTAL_BRANCHES + BRANCH_COUNT))
    TOTAL_TAGS=$((TOTAL_TAGS + TAG_COUNT))
    TOTAL_UNIQUE=$((TOTAL_UNIQUE + REPO_UNIQUE))

    echo "  Branches: $BRANCH_COUNT | Tags: $TAG_COUNT | Unique commits: $REPO_UNIQUE"
done

# ── Final Summary ──
echo ""
echo "========================================"
echo "  FINAL SUMMARY for '$OWNER'"
echo "========================================"
echo "  Repositories:      $TOTAL_REPOS"
echo "  Total branches:    $TOTAL_BRANCHES"
echo "  Total tags:        $TOTAL_TAGS"
echo "  Total entries:     $((TOTAL_BRANCHES + TOTAL_TAGS))"
echo "  Unique commits:    $TOTAL_UNIQUE"
echo "  Duplicates removed: $((TOTAL_BRANCHES + TOTAL_TAGS - TOTAL_UNIQUE))"
echo "  Output saved to:   $OUTPUT_FILE"
echo "========================================"
