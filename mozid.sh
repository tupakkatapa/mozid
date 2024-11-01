#!/usr/bin/env bash

# Display usage information
display_usage() {
    cat <<USAGE
Usage: mozid [options] <url>

Description:
  This script downloads a Firefox extension from the given URL, extracts it, and retrieves the extension ID from the manifest.json file.

Options:
  -v, --verbose
    Enable verbose output for debugging

  --json
    Output result in JSON format

  -h, --help
    Display this help message and exit

Example:
  mozid https://addons.mozilla.org/en-US/firefox/addon/vimium-ff/

USAGE
}

# Initialize variables
verbose=false
json_output=false
extension_url=""

# Parse arguments using a while loop
while [[ $# -gt 0 ]]; do
    case $1 in
        -v | --verbose)
            verbose=true
            shift
            ;;
        --json)
            json_output=true
            shift
            ;;
        -h | --help)
            display_usage
            exit 0
            ;;
        *)
            # Treat the first non-option argument as the URL
            if [[ -z "$extension_url" ]]; then
                extension_url="$1"
                shift
            else
                echo "error: unknown option -- '$1'"
                echo "try '--help' for more information"
                exit 1
            fi
            ;;
    esac
done

# Check if the URL is provided
if [[ -z "$extension_url" ]]; then
    echo "error: no url provided"
    display_usage
    exit 1
fi

# Ensure the URL has a trailing slash
if [[ "${extension_url: -1}" != "/" ]]; then
    extension_url="${extension_url}/"
fi

# Verbose output function
say() {
    if [[ "$verbose" = true ]]; then
        echo "$@"
    fi
}

# Create a temporary directory and set trap for cleanup
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT SIGINT

if [[ ! "$TMP_DIR" || ! -d "$TMP_DIR" ]]; then
    echo "error: failed to create a temporary directory"
    exit 1
fi
say "status: using temporary directory '$TMP_DIR'"

# Download the page and extract the .xpi URL
say "status: fetching .xpi download link from '$extension_url'"
XPI_URL=$(curl -s "$extension_url" | grep -oP '(?<=href=")https://addons.mozilla.org/firefox/downloads/file/[^"]+.xpi(?=")' | head -n 1)
if [ -z "$XPI_URL" ]; then
    echo "error: failed to extract '.xpi' download link from the provided url"
    exit 1
fi
say "status: downloading .xpi file from '$XPI_URL'"

# Download the .xpi file
XPI_FILE="$TMP_DIR/extension.xpi"
if ! wget -q -O "$XPI_FILE" "$XPI_URL"; then
    echo "error: failed to download '.xpi' file"
    exit 1
fi
say "status: downloaded .xpi file '$XPI_FILE'"

# Extract the files
EXTRACT_DIR="$TMP_DIR/extracted_xpi"
mkdir -p "$EXTRACT_DIR"
if ! unzip -q "$XPI_FILE" -d "$EXTRACT_DIR"; then
    echo "error: failed to extract '.xpi' file"
    exit 1
fi
say "status: extracted .xpi file to '$EXTRACT_DIR'"

# Check if manifest.json exists
MANIFEST_FILE="$EXTRACT_DIR/manifest.json"
if [ ! -f "$MANIFEST_FILE" ]; then
    echo "error: 'manifest.json' not found in the extracted files"
    exit 1
fi
say "status: found 'manifest.json' file"

# Extract the ID
ID=$(grep -Po '(?<="id": ")[^"]+' "$MANIFEST_FILE")
if [ -z "$ID" ]; then
    echo "error: id not found in the 'manifest.json' file"
    exit 1
fi

# Output results in the appropriate format
if [[ "$json_output" = true ]]; then
  EXTENSION_NAME=$(echo "$extension_url" | grep -oP '(?<=/addon/)[^/]+')
  HOMEPAGE_URL=$(jq -r '.homepage_url // empty' "$MANIFEST_FILE")
  AUTHOR=$(jq -r '.author // empty' "$MANIFEST_FILE")
  VERSION=$(jq -r '.version // empty' "$MANIFEST_FILE")

  cat <<EOF
{
  "name": "$EXTENSION_NAME",
  "id": "$ID",
  "version": "$VERSION",
  "author": "$AUTHOR",
  "url": "$extension_url",
  "homepage_url": "$HOMEPAGE_URL"
}
EOF
else
  echo "$ID"
fi

# The trap will automatically clean up the temporary directory
say "info: cleaned up temporary files"
