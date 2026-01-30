#!/bin/bash
# Upload a skill directory to skillbase.work
# Usage: upload-skill.sh --skill-dir <dir> --name <name> --description <desc>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_URL="${DSTL_API_URL:-https://skillbase.work}"
CRED_FILE="$HOME/.skillbase/credentials"

# Parse arguments
SKILL_DIR=""
NAME=""
DESCRIPTION=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --skill-dir)
            SKILL_DIR="$2"
            shift 2
            ;;
        --name)
            NAME="$2"
            shift 2
            ;;
        --description)
            DESCRIPTION="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Validate arguments
if [ -z "$SKILL_DIR" ] || [ -z "$NAME" ] || [ -z "$DESCRIPTION" ]; then
    echo "Usage: upload-skill.sh --skill-dir <dir> --name <name> --description <desc>"
    exit 1
fi

if [ ! -d "$SKILL_DIR" ]; then
    echo "Error: Skill directory not found: $SKILL_DIR"
    exit 1
fi

SKILL_MD="$SKILL_DIR/SKILL.md"
if [ ! -f "$SKILL_MD" ]; then
    echo "Error: SKILL.md not found in $SKILL_DIR"
    exit 1
fi

# Step 1: Check authentication
echo "Checking authentication..."
AUTH_RESULT=$("$SCRIPT_DIR/check-auth.sh")
AUTHENTICATED=$(echo "$AUTH_RESULT" | grep -o '"authenticated": *[^,}]*' | cut -d':' -f2 | tr -d ' ')

if [ "$AUTHENTICATED" != "true" ]; then
    echo "Not authenticated. Starting authentication flow..."
    echo ""
    "$SCRIPT_DIR/auth.sh"

    # Re-check after auth
    AUTH_RESULT=$("$SCRIPT_DIR/check-auth.sh")
    AUTHENTICATED=$(echo "$AUTH_RESULT" | grep -o '"authenticated": *[^,}]*' | cut -d':' -f2 | tr -d ' ')

    if [ "$AUTHENTICATED" != "true" ]; then
        echo "Error: Authentication failed"
        exit 1
    fi
fi

echo "Authenticated."

# Step 2: Read credentials
ACCESS_TOKEN=$(grep -E "^access_token=" "$CRED_FILE" 2>/dev/null | cut -d'=' -f2-)

# Step 3: Build payload using Python (handles all escaping properly)
echo "Preparing upload..."

SCRIPTS_DIR="$SKILL_DIR/scripts"

# Export variables for Python
export SKILL_DIR NAME DESCRIPTION SKILL_MD SCRIPTS_DIR

PAYLOAD=$(python3 << 'PYEOF'
import json
import os
import sys

skill_dir = os.environ.get('SKILL_DIR')
name = os.environ.get('NAME')
description = os.environ.get('DESCRIPTION')
skill_md = os.environ.get('SKILL_MD')
scripts_dir = os.environ.get('SCRIPTS_DIR')

# Read SKILL.md
with open(skill_md, 'r') as f:
    content = f.read()

# Detect skill type from frontmatter
skill_type = "capability"
if "type: tool" in content:
    skill_type = "tool"
elif "type: sop" in content:
    skill_type = "sop"

# Read scripts
scripts = {}
if os.path.isdir(scripts_dir):
    for filename in os.listdir(scripts_dir):
        filepath = os.path.join(scripts_dir, filename)
        if os.path.isfile(filepath):
            with open(filepath, 'r') as f:
                scripts[filename] = f.read()

payload = {
    "name": name,
    "description": description,
    "visibility": "private",
    "skills": [
        {
            "name": name,
            "type": skill_type,
            "is_primary": True,
            "content": content,
            "scripts": scripts
        }
    ]
}

print(json.dumps(payload))
PYEOF
)

# Step 4: Upload
echo "Uploading to skillbase.work..."

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

if [ -z "$SLUG" ] || [ -z "$SKILLSET_ID" ]; then
    echo "Error: Unexpected response"
    echo "$RESPONSE"
    exit 1
fi

echo ""
echo "Uploaded successfully!"
echo ""
echo "Configure access: $API_URL/skillset/$SKILLSET_ID"
echo ""
echo "Your skillset is private by default. Visit the link above to:"
echo "  - Add specific people by email, or"
echo "  - Make it publicly accessible"
echo ""
echo "Once shared, others can install with:"
echo "  curl -sSL $API_URL/s/$SLUG/install.sh | bash"
