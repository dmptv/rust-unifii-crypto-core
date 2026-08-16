#!/usr/bin/env bash
# Regenerates Sources/ElizaProtoKit/Generated/eliza.pb.swift from proto/eliza.proto.
#
# protoc-gen-swift must be the exact same swift-protobuf version this package
# depends on (see Package.swift) — a version mismatch is a real compile error
# (the internal _NameMap init signature changes between versions), not a
# warning. Homebrew only ships the latest protoc-gen-swift, so this script
# builds the matching one from source once and caches it in .tools/.
set -euo pipefail

cd "$(dirname "$0")"

SWIFT_PROTOBUF_VERSION="1.30.0"
TOOLS_DIR=".tools"
CHECKOUT_DIR="${TOOLS_DIR}/swift-protobuf-src"
PLUGIN_BIN="${TOOLS_DIR}/protoc-gen-swift"

if [ ! -x "$PLUGIN_BIN" ]; then
  echo "protoc-gen-swift ${SWIFT_PROTOBUF_VERSION} not found — building it once (~1 min)..."
  mkdir -p "$TOOLS_DIR"

  if [ ! -d "$CHECKOUT_DIR" ]; then
    git clone --depth 1 --branch "$SWIFT_PROTOBUF_VERSION" \
      https://github.com/apple/swift-protobuf.git "$CHECKOUT_DIR"
  fi

  (cd "$CHECKOUT_DIR" && swift build -c release --product protoc-gen-swift)
  cp "$CHECKOUT_DIR/.build/release/protoc-gen-swift" "$PLUGIN_BIN"
fi

echo "Generating eliza.pb.swift with protoc-gen-swift $("$PLUGIN_BIN" --version)..."

protoc \
  --plugin=protoc-gen-swift="$PLUGIN_BIN" \
  --swift_out=Sources/ElizaProtoKit/Generated \
  --swift_opt=Visibility=Public \
  --proto_path=proto \
  proto/eliza.proto

echo "Done: Sources/ElizaProtoKit/Generated/eliza.pb.swift"
