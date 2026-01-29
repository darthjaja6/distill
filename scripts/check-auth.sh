#!/bin/bash
# Check DSTL authentication status
# Returns JSON: {"authenticated": bool, "email": string|null, "expired": bool}

set -e

CRED_FILE="$HOME/.dstl/credentials"
API_URL="${DSTL_API_URL:-https://dstl.dev}"

# Check if credentials file exists
if [ ! -f "$CRED_FILE" ]; then
    echo '{"authenticated": false, "email": null, "expired": false, "message": "No credentials found"}'
    exit 0
fi

# Read credentials
ACCESS_TOKEN=$(grep -E "^access_token=" "$CRED_FILE" 2>/dev/null | cut -d'=' -f2-)
REFRESH_TOKEN=$(grep -E "^refresh_token=" "$CRED_FILE" 2>/dev/null | cut -d'=' -f2-)
EXPIRES_AT=$(grep -E "^expires_at=" "$CRED_FILE" 2>/dev/null | cut -d'=' -f2-)
EMAIL=$(grep -E "^email=" "$CRED_FILE" 2>/dev/null | cut -d'=' -f2-)

if [ -z "$ACCESS_TOKEN" ]; then
    echo '{"authenticated": false, "email": null, "expired": false, "message": "Invalid credentials file"}'
    exit 0
fi

# Check if token is expired
CURRENT_TIME=$(date +%s)
if [ -n "$EXPIRES_AT" ]; then
    # Parse ISO date to timestamp
    EXPIRES_TS=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${EXPIRES_AT%%.*}" +%s 2>/dev/null || echo "0")

    if [ "$CURRENT_TIME" -gt "$EXPIRES_TS" ]; then
        # Token expired, try to refresh
        if [ -n "$REFRESH_TOKEN" ]; then
            REFRESH_RESULT=$(curl -sL -X POST "$API_URL/api/auth/refresh" \
                -H "Content-Type: application/json" \
                -d "{\"refresh_token\": \"$REFRESH_TOKEN\"}")

            NEW_TOKEN=$(echo "$REFRESH_RESULT" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
            NEW_EXPIRES=$(echo "$REFRESH_RESULT" | grep -o '"expires_at":"[^"]*"' | cut -d'"' -f4)

            if [ -n "$NEW_TOKEN" ]; then
                # Update credentials file
                cat > "$CRED_FILE" << EOF
access_token=$NEW_TOKEN
refresh_token=$REFRESH_TOKEN
expires_at=$NEW_EXPIRES
email=$EMAIL
EOF
                echo "{\"authenticated\": true, \"email\": \"$EMAIL\", \"expired\": false, \"message\": \"Token refreshed\"}"
                exit 0
            fi
        fi

        echo "{\"authenticated\": false, \"email\": \"$EMAIL\", \"expired\": true, \"message\": \"Token expired and refresh failed\"}"
        exit 0
    fi
fi

# Token seems valid
echo "{\"authenticated\": true, \"email\": \"$EMAIL\", \"expired\": false, \"message\": \"Authenticated\"}"
