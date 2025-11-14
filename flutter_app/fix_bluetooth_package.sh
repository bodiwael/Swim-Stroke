#!/bin/bash

# Script to fix flutter_bluetooth_serial namespace issue
# This adds the missing namespace to the package's build.gradle

echo "Fixing flutter_bluetooth_serial namespace issue..."

# Determine OS-specific pub cache location
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    # Windows
    PUB_CACHE="$LOCALAPPDATA/Pub/Cache"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    PUB_CACHE="$HOME/.pub-cache"
else
    # Linux
    PUB_CACHE="$HOME/.pub-cache"
fi

# Find the flutter_bluetooth_serial package
PACKAGE_PATH="$PUB_CACHE/hosted/pub.dev/flutter_bluetooth_serial-0.4.0/android/build.gradle"

if [ -f "$PACKAGE_PATH" ]; then
    echo "Found package at: $PACKAGE_PATH"

    # Check if namespace already exists
    if grep -q "namespace" "$PACKAGE_PATH"; then
        echo "Namespace already exists. No changes needed."
    else
        echo "Adding namespace to build.gradle..."

        # Backup original file
        cp "$PACKAGE_PATH" "$PACKAGE_PATH.backup"

        # Add namespace after 'android {' line
        sed -i.tmp "/^android {/a\\
    namespace 'io.github.edufolly.flutterbluetoothserial'
" "$PACKAGE_PATH"

        echo "Namespace added successfully!"
    fi
else
    echo "Error: Package not found at expected location."
    echo "Please run 'flutter pub get' first."
    exit 1
fi

echo "Done! You can now build the app."
