#!/bin/bash
# Upload skillset to DSTL
# Usage: upload.sh <payload_file> [--visibility public|private|shared] [--emails email1,email2]

set -e

API_URL="${DSTL_API_URL:-https://skillbase.work}"
CRED_FILE="$HOME/.skillbase/credentials"

# Parse arguments
PAYLOAD_FILE=""
VISIBILITY="private"
EMAILS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --visibility)
            VISIBILITY="$2"
            shift 2
            ;;
        --emails)
            EMAILS="$2"
            shift 2
            ;;
        *)
            if [ -z "$PAYLOAD_FILE" ]; then
                PAYLOAD_FILE="$1"
            fi
            shift
            ;;
    esac
done

if [ -z "$PAYLOAD_FILE" ]; then
    echo "Usage: upload.sh <payload_file> [--visibility public|private|selected] [--emails email1,email2]"
    echo ""
    echo "Payload file should be JSON with format:"
    echo '{"name": "...", "description": "...", "skills": [...]}'
    exit 1
fi

if [ ! -f "$PAYLOAD_FILE" ]; then
    echo "Error: Payload file not found: $PAYLOAD_FILE"
    exit 1
fi

# Check credentials
if [ ! -f "$CRED_FILE" ]; then
    echo "Error: Not authenticated. Run auth.sh first."
    exit 1
fi

ACCESS_TOKEN=$(grep -E "^access_token=" "$CRED_FILE" 2>/dev/null | cut -d'=' -f2-)

if [ -z "$ACCESS_TOKEN" ]; then
    echo "Error: Invalid credentials. Run auth.sh to re-authenticate."
    exit 1
fi

# Read and modify payload to add visibility settings
PAYLOAD=$(cat "$PAYLOAD_FILE")

# Add visibility to payload using jq if available, otherwise use simple approach
if command -v jq &> /dev/null; then
    if [ -n "$EMAILS" ]; then
        EMAILS_JSON=$(echo "$EMAILS" | jq -R 'split(",")')
        PAYLOAD=$(echo "$PAYLOAD" | jq --arg vis "$VISIBILITY" --argjson emails "$EMAILS_JSON" '. + {visibility: $vis, allowed_emails: $emails}')
    else
        PAYLOAD=$(echo "$PAYLOAD" | jq --arg vis "$VISIBILITY" '. + {visibility: $vis}')
    fi
else
    # Simple string manipulation fallback
    PAYLOAD="${PAYLOAD%\}}, \"visibility\": \"$VISIBILITY\"}"
    if [ -n "$EMAILS" ]; then
        PAYLOAD="${PAYLOAD%\}}, \"allowed_emails\": [$(echo "$EMAILS" | sed 's/,/","/g' | sed 's/^/"/' | sed 's/$/"/')]]}"
    fi
fi

echo "Uploading skillset to skillbase.work..."

# Upload
RESPONSE=$(curl -sL -X POST "$API_URL/api/skillsets/upload" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -d "$PAYLOAD")

# Check response
ERROR=$(echo "$RESPONSE" | grep -o '"error":"[^"]*"' | cut -d'"' -f4)

if [ -n "$ERROR" ]; then
    echo "Error: $ERROR"
    exit 1
fi

# Extract results
SLUG=$(echo "$RESPONSE" | grep -o '"slug":"[^"]*"' | cut -d'"' -f4)
SKILLSET_ID=$(echo "$RESPONSE" | grep -o '"skillset_id":"[^"]*"' | cut -d'"' -f4)

if [ -z "$SLUG" ]; then
    echo "Error: Unexpected response"
    echo "$RESPONSE"
    exit 1
fi

INSTALL_URL="$API_URL/s/$SLUG"

echo ""
echo "Success! Skillset uploaded."
echo ""
echo "Share URL: $INSTALL_URL"
echo ""
echo "Install with:"
echo "  curl -sSL $INSTALL_URL/install.sh | bash"
echo ""

# Output JSON for programmatic use
echo "{\"success\": true, \"slug\": \"$SLUG\", \"install_url\": \"$INSTALL_URL\", \"id\": \"$SKILLSET_ID\"}"
