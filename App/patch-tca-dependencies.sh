#!/usr/bin/env bash
# Re-applies the three source patches TCA's dependency tree needs on Xcode
# 27 beta (see README, "Known environment quirk: TCA dependency source
# patches"). These live in Tuist/.build/checkouts/, which is gitignored and
# gets reset by `tuist install --update` or `tuist clean` (not by a plain
# `tuist generate` or `xcodebuild build`) - run this once after either of
# those. Idempotent: safe to run again if the patches are already applied.
set -euo pipefail

cd "$(dirname "$0")"

# 1. swift-perception: Bindable's Identifiable/Sendable extensions don't
# repeat the type's own `obsoleted: 17` availability, so Xcode 27 beta
# errors on referencing it even in this dead-at-our-target code.
F1="Tuist/.build/checkouts/swift-perception/Sources/PerceptionCore/SwiftUI/Bindable.swift"
if [ -f "$F1" ]; then
  OCCURRENCES=$(grep -c "@available(iOS, obsoleted: 17)" "$F1" 2>/dev/null || true)
  if [ "${OCCURRENCES:-0}" -ge 2 ]; then
    echo "already patched: $F1"
  else
    chmod u+w "$F1"
    python3 - "$F1" <<'PYEOF'
import sys
path = sys.argv[1]
with open(path) as f:
    content = f.read()
old1 = "  @available(visionOS, unavailable)\n  extension Bindable: Identifiable where Value: Identifiable {"
new1 = "  @available(iOS, obsoleted: 17)\n  @available(macOS, obsoleted: 14)\n  @available(tvOS, obsoleted: 17)\n  @available(watchOS, obsoleted: 10)\n  @available(visionOS, unavailable)\n  extension Bindable: Identifiable where Value: Identifiable {"
old2 = "  @available(visionOS, unavailable)\n  extension Bindable: Sendable where Value: Sendable {}"
new2 = "  @available(iOS, obsoleted: 17)\n  @available(macOS, obsoleted: 14)\n  @available(tvOS, obsoleted: 17)\n  @available(watchOS, obsoleted: 10)\n  @available(visionOS, unavailable)\n  extension Bindable: Sendable where Value: Sendable {}"
if old1 not in content or old2 not in content:
    print("WARNING: expected pattern not found - skipping (upstream file may have changed)")
    sys.exit(0)
content = content.replace(old1, new1).replace(old2, new2)
with open(path, "w") as f:
    f.write(content)
print("patched: " + path)
PYEOF
  fi
else
  echo "skip (not found): $F1"
fi

# 2. swift-sharing: the pre-iOS-17 fallback branch (dead at our deployment
# target) references the same obsoleted Bindable - replaced with a
# fatalError, matching the visionOS case already in this file.
F2="Tuist/.build/checkouts/swift-sharing/Sources/Sharing/SharedBinding.swift"
if [ -f "$F2" ]; then
  if grep -qF "our deployment target is iOS 17+" "$F2" 2>/dev/null; then
    echo "already patched: $F2"
  else
    chmod u+w "$F2"
    python3 - "$F2" <<'PYEOF'
import sys
path = sys.argv[1]
with open(path) as f:
    content = f.read()
old = """      else {
        #if os(visionOS)
          fatalError("This should be unreachable: visionOS should always support Observation")
        #else
          func open(_ reference: some MutableReference<Value>) -> Binding<Value> {
            @PerceptionCore.Bindable var reference = reference
            return $reference._wrappedValue
          }
          self = open(base.reference)
          return
        #endif
      }"""
new = """      else {
        fatalError("This should be unreachable: our deployment target is iOS 17+")
      }"""
if old not in content:
    print("WARNING: expected pattern not found - skipping (upstream file may have changed)")
    sys.exit(0)
content = content.replace(old, new)
with open(path, "w") as f:
    f.write(content)
print("patched: " + path)
PYEOF
  fi
else
  echo "skip (not found): $F2"
fi

# 3. swift-navigation: _UIBindingWrapper already conforms to Observable
# directly when the Perception trait is off (via the _Observable
# typealias) - this extra conformance is only needed when Perception is
# on, so it needs the same guard to avoid a genuinely redundant
# conformance declaration.
F3="Tuist/.build/checkouts/swift-navigation/Sources/SwiftNavigation/UIBinding.swift"
if [ -f "$F3" ]; then
  if grep -qF "#if Perception && canImport(Observation)" "$F3" 2>/dev/null; then
    echo "already patched: $F3"
  else
    chmod u+w "$F3"
    python3 - "$F3" <<'PYEOF'
import sys
path = sys.argv[1]
with open(path) as f:
    content = f.read()
old = """#if canImport(Observation)
  @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
  extension _UIBindingWrapper: Observable {}
#endif"""
new = """#if Perception && canImport(Observation)
  @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
  extension _UIBindingWrapper: Observable {}
#endif"""
if old not in content:
    print("WARNING: expected pattern not found - skipping (upstream file may have changed)")
    sys.exit(0)
content = content.replace(old, new)
with open(path, "w") as f:
    f.write(content)
print("patched: " + path)
PYEOF
  fi
else
  echo "skip (not found): $F3"
fi

echo "Done."
