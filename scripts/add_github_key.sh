#!/usr/bin/env sh
: '
This script automatically adds SSH keys from a specified GitHub user to the authorized_keys file on a local machine.

Usage:
./add_github_key.sh [OPTIONS]

Dependencies:
- curl

Options:
  -u, --user USERNAME     The GitHub username to retrieve SSH keys from
  -c, --comment COMMENT   The comment to add to the end of each key         (default: "GH-Key")
  -f, --file FILE         The path to the authorized_keys file              (default: "~/.ssh/authorized_keys")

Example Usage:
./add_github_key.sh -u myusername -c "mykey" -f "/path/to/authorized_keys"

Example Installation:
1. Download the script and make it executable:
curl -LJ -o add_github_key.sh https://gist.github.com/Raiu/23418eac4e78856167121b4f02c13db7/raw && chmod +x add_github_key.sh
2. Run the script with desired options:
./add_github_key.sh -u myusername

Note:
To run without arguments the default values for the options can be manually edited in the script
'

GITHUB_USER="YOURUSERNAME" # Change this if you want to run without arguments
GITHUB_KEY_COMMENT="GH-Key"
AUTHORIZED_KEYS_FILE="$HOME/.ssh/authorized_keys"
TEMP_KEYS_FILE=$(mktemp)

if ! command -v curl >/dev/null; then
    printf "Error: curl is not installed or not in PATH.\n" >&2
    exit 1
fi
print_error_exit () {
    printf "Error: %s\n" "$1" >&2
    exit 1
}
print_help () {
    cat << EOF
Usage: ${0##*/} [OPTIONS]

Automatically add SSH keys from a specified GitHub user to the authorized_keys file on a local machine.

Options:
  -u, --user USERNAME     The GitHub username to retrieve SSH keys from
  -c, --comment COMMENT   The comment to add to the end of each key         (default: $GITHUB_KEY_COMMENT)
  -f, --file FILE         The path to the authorized_keys file              (default: $AUTHORIZED_KEYS_FILE)
  -h, --help              Display this help message and exit

Example:
./add_github_key.sh -u myusername -c "mykey" -f "/path/to/authorized_keys"

EOF
}
validate_key () {
    printf "%s\n" "$1" | grep -E '^ssh-(rsa|dss|ed25519) AAAA[0-9A-Za-z+/]+[=]{0,3}(\s+.+)?$' >/dev/null 2>&1
}

# Parse command-line options
while [ $# -gt 0 ]; do
    case "$1" in
        -u|--user)
            GITHUB_USER="$2"
            shift 2
            ;;
        -c|--comment)
            GITHUB_KEY_COMMENT="$2"
            shift 2
            ;;
        -f|--file)
            AUTHORIZED_KEYS_FILE="$2"
            shift 2
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        *)
            printf "Error: Unknown option '%s'\n" "$1" >&2
            print_help >&2
            exit 1
    esac
done

if [ "$GITHUB_USER" = "YOURUSERNAME" ]; then
    printf "Error: Please specify a GitHub username or manually edit the default value in the script.\n" >&2
    print_help >&2
    exit 1
fi

# Check that authorized_keys exist and is writeble
if [ ! -f "$AUTHORIZED_KEYS_FILE" ]; then
    touch "$AUTHORIZED_KEYS_FILE"
    chmod 600 "$AUTHORIZED_KEYS_FILE"
fi
if [ ! -w "$AUTHORIZED_KEYS_FILE" ]; then
    print_error_exit "The file '$AUTHORIZED_KEYS_FILE' is not writable. Please check permissions."
fi

# Grab all existing ssh-keys that doesnt have the comment
awk -v key_comment="$GITHUB_KEY_COMMENT" '$1 ~ /^ssh/ && $NF != key_comment {print}' "$AUTHORIZED_KEYS_FILE" > "$TEMP_KEYS_FILE"

# Get SSH keys from GitHub API and append the comment
printf "\n# GITHUB KEYS\n" >> "$TEMP_KEYS_FILE"
curl -s "https://github.com/$GITHUB_USER.keys" | while read -r key; do
    if validate_key "$key"; then
        printf "%s %s\n" "$key" "$GITHUB_KEY_COMMENT" >> "$TEMP_KEYS_FILE"
    fi
done

# Compare and write if changed
if cmp "$AUTHORIZED_KEYS_FILE" "$TEMP_KEYS_FILE" >/dev/null 2>&1; then
    rm "$TEMP_KEYS_FILE"
else
    mv "$TEMP_KEYS_FILE" "$AUTHORIZED_KEYS_FILE"
    chmod 600 "$AUTHORIZED_KEYS_FILE"
fi