#!/usr/bin/env bash
# Maps PHP minor version -> latest full version.
# Update these when new patch releases come out, then commit to trigger a rebuild.

declare -A PHP_VERSIONS=(
    ["8.0"]="8.0.30"
    ["8.1"]="8.1.32"
    ["8.2"]="8.2.28"
    ["8.3"]="8.3.21"
    ["8.4"]="8.4.7"
)
