#!/usr/bin/env bash
# pinalove-auth.sh
# Authenticates with pinalove.com and saves session cookies.
# Run this whenever your session expires.

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/pinaloveMonitor"
mkdir -p "$DATA_DIR"
COOKIE_JAR="$DATA_DIR/session.cookie"
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36"
BASE_URL="https://www.pinalove.com"

echo ""
echo "=== Pinalove Session Authentication ==="
echo ""

# --- Step 0: read credentials -------------------------------------------------
if [[ -f "$DATA_DIR/session.user" ]]; then
    SAVED_USER=$(cat "$DATA_DIR/session.user")
    read -rp "Email or username [$SAVED_USER]: " INPUT_USER
    EMAIL="${INPUT_USER:-$SAVED_USER}"
else
    read -rp "Email or username: " EMAIL
fi

[[ -z "$EMAIL" ]] && { echo "Error: no email/username provided."; exit 1; }
echo "$EMAIL" > "$DATA_DIR/session.user"

# --- Step 1: request one-time code --------------------------------------------
echo ""
echo "Requesting login code for '$EMAIL' ..."

SEND_RESP=$(curl -sS --max-time 15 \
    -c "$COOKIE_JAR" \
    -A "$UA" \
    -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "Origin: $BASE_URL" \
    -H "Referer: $BASE_URL/el/" \
    "$BASE_URL/nt/app.php" \
    --data-urlencode "z=emailcodesend" \
    --data-urlencode "usernameoremail=$EMAIL" \
    --data-urlencode "signup=1")

echo "Server response: $SEND_RESP"

if echo "$SEND_RESP" | grep -qi '"success":true\|already'; then
    echo "Code sent (or already pending). Check your email."
elif echo "$SEND_RESP" | grep -qi '"success":false'; then
    echo ""
    echo "Warning: server reported failure. The code may still have been sent."
    echo "Try entering the code anyway."
fi

# --- Step 2: verify code ------------------------------------------------------
echo ""
read -rp "Enter the 5-digit code from your email: " CODE
[[ ${#CODE} -ne 5 ]] && { echo "Error: code must be exactly 5 digits."; exit 1; }

echo ""
echo "Verifying code ..."

VERIFY_RESP=$(curl -sS --max-time 15 \
    -c "$COOKIE_JAR" -b "$COOKIE_JAR" \
    -A "$UA" \
    -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "Origin: $BASE_URL" \
    -H "Referer: $BASE_URL/el/" \
    -D /tmp/pinalove_headers.txt \
    "$BASE_URL/el/index.php" \
    --data-urlencode "z=cwecodeconfirm" \
    --data-urlencode "code=$CODE" \
    --data-urlencode "email=$EMAIL" \
    --data-urlencode "desktop=1")

echo "Server response: $VERIFY_RESP"

# --- Step 3: extract and validate session cookies -----------------------------

JWT=$(echo "$VERIFY_RESP" | grep -o '"scjwt":"[^"]*"' | cut -d'"' -f4 || true)

if [[ -n "$JWT" ]]; then
    echo ""
    echo "JWT token received. Saving as Bearer token ..."
    echo "Authorization: Bearer $JWT" > "$DATA_DIR/session.bearer"
    echo "jwt" > "$DATA_DIR/session.type"
elif echo "$VERIFY_RESP" | grep -qi "redirect\|Active\|success"; then
    echo ""
    echo "Session cookie flow detected."
    echo "cookie" > "$DATA_DIR/session.type"
    rm -f "$DATA_DIR/session.bearer"
else
    echo ""
    echo "ERROR: Unexpected response. Authentication may have failed."
    echo "Full response: $VERIFY_RESP"
    exit 1
fi

if grep -qi "set-cookie" /tmp/pinalove_headers.txt 2>/dev/null; then
    echo "Session cookies saved to: $COOKIE_JAR"
fi

# --- Step 4: smoke-test the session ------------------------------------------
echo ""
echo "Testing session ..."

TEST_HTTP=$(curl -sS --max-time 15 \
    -c "$COOKIE_JAR" -b "$COOKIE_JAR" \
    -A "$UA" \
    -o /dev/null \
    -w "%{http_code}" \
    "$BASE_URL/")

if [[ "$TEST_HTTP" == "200" ]]; then
    echo "Session is working (HTTP $TEST_HTTP)."
else
    echo "Session test returned HTTP $TEST_HTTP - session may not be active."
fi

# --- Done ---------------------------------------------------------------------
echo ""
echo "Done. The plugin daemon will pick up the new session automatically."
echo "Session files: $DATA_DIR/"
