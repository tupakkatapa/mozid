#!/usr/bin/env bash

# Display usage information
display_usage() {
    cat <<USAGE
Usage: mozid [options] <url>

Description:
  This script downloads a Firefox extension from the given URL, extracts it, and retrieves the extension ID from the manifest.json file.

Options:
  -v, --verbose
    Enable verbose output for debugging.

  -h, --help
    Display this help message and exit.

Example:
  mozid https://addons.mozilla.org/en-US/firefox/addon/vimium-ff/

USAGE
}

# Initialize variables
verbose=false
extension_url=""

# Parse arguments using a while loop
while [[ $# -gt 0 ]]; do
    case $1 in
        -v | --verbose)
            verbose=true
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
                echo "try '--help' for more information."
                exit 1
            fi
            ;;
    esac
done

# Check if the URL is provided
if [[ -z "$extension_url" ]]; then
    echo "error: no url provided."
    display_usage
    exit 1
fi

# Verbose output function
log() {
    if [[ "$verbose" = true ]]; then
        echo "$@"
    fi
}

# Create a temporary directory
TMP_DIR=$(mktemp -d)
if [[ ! "$TMP_DIR" || ! -d "$TMP_DIR" ]]; then
    echo "error: failed to create a temporary directory."
    exit 1
fi
log "using temporary directory: $TMP_DIR"

# Download the page and extract the .xpi URL
log "fetching .xpi download link from: $extension_url"
XPI_URL=$(curl -s "$extension_url" | grep -oP '(?<=href=")https://addons.mozilla.org/firefox/downloads/file/[^"]+.xpi(?=")' | head -n 1)
if [ -z "$XPI_URL" ]; then
    echo "error: failed to extract .xpi download link from the provided url."
    rm -rf "$TMP_DIR"
    exit 1
fi
log "downloading .xpi file from: $XPI_URL"

# Download the .xpi file
XPI_FILE="$TMP_DIR/wayback_machine_new.xpi"
if ! wget -q -O "$XPI_FILE" "$XPI_URL"; then
    echo "error: failed to download .xpi file."
    rm -rf "$TMP_DIR"
    exit 1
fi
log "downloaded .xpi file: $XPI_FILE"

# Extract the files
EXTRACT_DIR="$TMP_DIR/extracted_xpi"
mkdir -p "$EXTRACT_DIR"
if ! unzip -q "$XPI_FILE" -d "$EXTRACT_DIR"; then
    echo "error: failed to extract .xpi file."
    rm -rf "$TMP_DIR"
    exit 1
fi
log "extracted .xpi file to: $EXTRACT_DIR"

# Check if manifest.json exists
MANIFEST_FILE="$EXTRACT_DIR/manifest.json"
if [ ! -f "$MANIFEST_FILE" ]; then
    echo "error: manifest.json not found in the extracted files."
    rm -rf "$TMP_DIR"
    exit 1
fi
log "found manifest.json file."

# Extract the ID
ID=$(grep -Po '(?<="id": ")[^"]+' "$MANIFEST_FILE")
if [ -z "$ID" ]; then
    echo "error: id not found in the manifest.json file."
else
    echo "$ID"
fi

# Clean up temporary directory
rm -rf "$TMP_DIR"
log "cleaned up temporary files."
