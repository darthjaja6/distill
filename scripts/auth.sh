#!/bin/bash
# DSTL Device Authorization Flow
# Opens browser for authentication, polls for completion, saves credentials

set -e

API_URL="${SKILLBASE_API_URL:-https://skillbase.work}"
CRED_FILE="$HOME/.skillbase/credentials"
POLL_INTERVAL=2
MAX_ATTEMPTS=150  # 5 minutes at 2s intervals

echo "Initiating DSTL authentication..."

# Step 1: Request device code
DEVICE_RESPONSE=$(curl -sL -X POST "$API_URL/api/auth/device" \
    -H "Content-Type: application/json")

DEVICE_CODE=$(echo "$DEVICE_RESPONSE" | grep -o '"device_code":"[^"]*"' | cut -d'"' -f4)
VERIFICATION_URL=$(echo "$DEVICE_RESPONSE" | grep -o '"verification_url":"[^"]*"' | cut -d'"' -f4)

if [ -z "$DEVICE_CODE" ] || [ -z "$VERIFICATION_URL" ]; then
    echo "Error: Failed to initiate device authorization"
    echo "$DEVICE_RESPONSE"
    exit 1
fi

echo ""
echo "Please open this URL to authenticate:"
echo ""
echo "  $VERIFICATION_URL"
echo ""

# Try to open browser automatically
if command -v open &> /dev/null; then
    open "$VERIFICATION_URL"
    echo "(Browser opened automatically)"
elif command -v xdg-open &> /dev/null; then
    xdg-open "$VERIFICATION_URL"
    echo "(Browser opened automatically)"
fi

echo ""
echo "Waiting for authorization..."

# Step 2: Poll for authorization
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    POLL_RESPONSE=$(curl -sL "$API_URL/api/auth/device/poll?code=$DEVICE_CODE")

    STATUS=$(echo "$POLL_RESPONSE" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)

    if [ "$STATUS" = "authorized" ]; then
        ACCESS_TOKEN=$(echo "$POLL_RESPONSE" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
        REFRESH_TOKEN=$(echo "$POLL_RESPONSE" | grep -o '"refresh_token":"[^"]*"' | cut -d'"' -f4)
        EXPIRES_AT=$(echo "$POLL_RESPONSE" | grep -o '"expires_at":"[^"]*"' | cut -d'"' -f4)
        EMAIL=$(echo "$POLL_RESPONSE" | grep -o '"email":"[^"]*"' | cut -d'"' -f4)

        # Create credentials directory
        mkdir -p "$(dirname "$CRED_FILE")"

        # Save credentials
        cat > "$CRED_FILE" << EOF
access_token=$ACCESS_TOKEN
refresh_token=$REFRESH_TOKEN
expires_at=$EXPIRES_AT
email=$EMAIL
EOF
        chmod 600 "$CRED_FILE"

        echo ""
        echo "Success! Authenticated as $EMAIL"
        echo "Credentials saved to $CRED_FILE"
        exit 0
    elif [ "$STATUS" = "expired" ]; then
        echo ""
        echo "Error: Authorization code expired. Please try again."
        exit 1
    fi

    # Still pending, wait and retry
    sleep $POLL_INTERVAL
    ATTEMPT=$((ATTEMPT + 1))

    # Show progress every 10 attempts
    if [ $((ATTEMPT % 5)) -eq 0 ]; then
        echo "  Still waiting... ($ATTEMPT attempts)"
    fi
done

echo ""
echo "Error: Authorization timed out. Please try again."
exit 1
