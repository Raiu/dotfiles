#!/bin/sh

# Set variables
GITHUB_USER="Raiu"
GITHUB_KEY_COMMENT="GH-Key"
AUTHORIZED_KEYS_FILE="$HOME/.ssh/authorized_keys"
TEMP_KEYS_FILE=$(mktemp)

# Function to validate SSH key format
validate_key () {
    printf "%s\n" "$1" | grep -E '^ssh-(rsa|dss|ed25519) AAAA[0-9A-Za-z+/]+[=]{0,3}(\s+.+)?$' >/dev/null 2>&1
}

if [ ! -f "$AUTHORIZED_KEYS_FILE" ]; then
    touch "$AUTHORIZED_KEYS_FILE"
    chmod 600 "$AUTHORIZED_KEYS_FILE"
fi

# Move other keys already in the file without the "GH-Key" comment to the top of the file.
awk -v key_comment="$GITHUB_KEY_COMMENT" '$1 ~ /^ssh/ && $NF != key_comment {print}' "$AUTHORIZED_KEYS_FILE" > "$TEMP_KEYS_FILE"

# Get SSH keys from GitHub API and add them to the temp file
printf "\n# GITHUB KEYS\n" >> "$TEMP_KEYS_FILE"
curl -s "https://github.com/$GITHUB_USER.keys" | while read key; do
    if validate_key "$key"; then
        printf "%s %s\n" "$key" "$GITHUB_KEY_COMMENT" >> "$TEMP_KEYS_FILE"
    fi
done

if cmp "$AUTHORIZED_KEYS_FILE" "$TEMP_KEYS_FILE" >/dev/null 2>&1; then
    rm "$TEMP_KEYS_FILE"
else
    mv "$TEMP_KEYS_FILE" "$AUTHORIZED_KEYS_FILE"
    chmod 600 "$AUTHORIZED_KEYS_FILE"
fi