#!/usr/bin/env bash

set -euo pipefail

display_usage() {
    cat <<USAGE
Usage: mozid [options] <slug|url>

Description:
  Retrieves Firefox extension ID from Mozilla Add-ons using the official API.
  Accepts either a slug (shortId) or a full addon URL.

Options:
  -v, --verbose
    Enable verbose output for debugging

  -h, --help
    Display this help message and exit

Examples:
  mozid vimium-ff
  mozid https://addons.mozilla.org/en-US/firefox/addon/vimium-ff/

USAGE
}

# Parse arguments
verbose=false
input=""

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
            if [[ -z "$input" ]]; then
                input="$1"
                shift
            else
                echo "error: unknown option -- '$1'" >&2
                echo "try '--help' for more information" >&2
                exit 1
            fi
            ;;
    esac
done

if [[ -z "$input" ]]; then
    echo "error: no slug or url provided" >&2
    display_usage
    exit 1
fi

# Evaluate the Nix expression to get the extension ID
if [[ "$verbose" = true ]]; then
    echo "info: fetching extension ID from Mozilla API" >&2
fi

nix eval --impure --raw --expr "(import @lib@ {})._cli \"$input\""
