#!/bin/zsh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "1/3 Generating Phone Screenshots (iOS 1242x2688 & Android 1080x1920)..."
swift -module-cache-path /tmp/swift-cache "$SCRIPT_DIR/generate_screenshots.swift"

echo "2/3 Generating Tablet Screenshots (iPad & Android Tablet 2048x2732)..."
swift -module-cache-path /tmp/swift-cache "$SCRIPT_DIR/generate_tablet_screenshots.swift"

echo "3/3 Generating Creative Assets (Headers, Search Results & Feature Graphic)..."
swift -module-cache-path /tmp/swift-cache "$SCRIPT_DIR/generate_creative_assets.swift"

echo "Done! All screenshots and creative assets have been generated."
