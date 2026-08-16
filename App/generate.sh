#!/usr/bin/env bash
# Regenerates the Xcode project via Tuist and patches a known deployment-
# target quirk: SwiftProtobuf's synthesized resource-bundle target
# (SwiftProtobuf_SwiftProtobuf) gets IPHONEOS_DEPLOYMENT_TARGET=12.0 baked
# in by Tuist on every generate, and it's not reachable via
# PackageSettings.targetSettings by name (unlike a normal SPM target -
# Swinject's equivalent quirk is fixed at the source in Tuist/Package.swift
# instead). Always use this script instead of calling `tuist generate`
# directly.
set -euo pipefail

cd "$(dirname "$0")"

tuist generate --no-open

find . -name "*.pbxproj" -print0 | xargs -0 grep -l "IPHONEOS_DEPLOYMENT_TARGET = 12.0" 2>/dev/null | while read -r f; do
  sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 12.0;/IPHONEOS_DEPLOYMENT_TARGET = 15.0;/g' "$f"
  echo "Patched deployment target in: $f"
done

echo "Done."
