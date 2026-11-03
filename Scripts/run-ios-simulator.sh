#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SIMULATOR_NAME="${1:-${IOS_SIMULATOR_NAME:-iPhone 17}}"

if ! xcodebuild -version >/dev/null 2>&1; then
  for xcode_app in /Applications/Xcode.app "$HOME/Applications/Xcode.app" "$HOME/Desktop/Xcode.app"; do
    if [[ -x "$xcode_app/Contents/Developer/usr/bin/xcodebuild" ]]; then
      export DEVELOPER_DIR="$xcode_app/Contents/Developer"
      break
    fi
  done
fi

if ! command -v xcodebuild >/dev/null 2>&1 || ! xcodebuild -version >/dev/null 2>&1; then
  cat >&2 <<'EOF'
Full Xcode is required to build and run Bloom; the Command Line Tools alone are not enough.

Install Xcode from the Mac App Store, open it once to finish setup, then select its developer directory, for example:
  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

In Xcode, install an iOS Simulator runtime from Settings > Components, then run this script again.
EOF
  exit 1
fi

if ! xcrun --find simctl >/dev/null 2>&1; then
  echo "The iOS Simulator tools are unavailable. Install an iOS Simulator runtime in Xcode > Settings > Components." >&2
  exit 1
fi

DEVICE_ID="$(xcrun simctl list devices available --json | /usr/bin/python3 -c '
import json, sys
name = sys.argv[1]
devices = json.load(sys.stdin).get("devices", {})
matches = [device for runtime in devices.values() for device in runtime
           if device.get("isAvailable") and device.get("name") == name
           and "iPhone" in device.get("name", "")]
if not matches:
    available = sorted({device.get("name", "") for runtime in devices.values()
                        for device in runtime if device.get("isAvailable")
                        and "iPhone" in device.get("name", "")})
    print(f"No available iPhone Simulator named {name!r}.", file=sys.stderr)
    if available:
        print("Available iPhone simulators: " + ", ".join(available), file=sys.stderr)
    else:
        print("Install an iOS Simulator runtime in Xcode > Settings > Components.", file=sys.stderr)
    sys.exit(1)
print(matches[0]["udid"])
' "$SIMULATOR_NAME")"

echo "Building Bloom for $SIMULATOR_NAME..."
xcodebuild \
  -quiet \
  -project "$ROOT_DIR/Bloom.xcodeproj" \
  -scheme Bloom \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$DEVICE_ID" \
  -derivedDataPath "$ROOT_DIR/DerivedData" \
  CODE_SIGNING_ALLOWED=NO \
  build

DEVICE_STATE="$(xcrun simctl list devices available --json | /usr/bin/python3 -c '
import json, sys
udid = sys.argv[1]
for runtime in json.load(sys.stdin).get("devices", {}).values():
    for device in runtime:
        if device.get("udid") == udid:
            print(device.get("state", "Unknown"))
            sys.exit(0)
print("Unknown")
' "$DEVICE_ID")"

if [[ "$DEVICE_STATE" != "Booted" ]]; then
  xcrun simctl boot "$DEVICE_ID"
fi
xcrun simctl bootstatus "$DEVICE_ID" -b

SIMULATOR_APP="${DEVELOPER_DIR:-$(xcode-select -p)}/Applications/Simulator.app"
if [[ -d "$SIMULATOR_APP" ]]; then
  open -a "$SIMULATOR_APP" --args -CurrentDeviceUDID "$DEVICE_ID"
elif [[ -d /Applications/Simulator.app ]]; then
  open -a /Applications/Simulator.app --args -CurrentDeviceUDID "$DEVICE_ID"
elif open -Ra Simulator >/dev/null 2>&1; then
  open -a Simulator --args -CurrentDeviceUDID "$DEVICE_ID"
else
  echo "Simulator.app UI was not found; continuing with the booted simulator." >&2
fi

APP_PATH="$ROOT_DIR/DerivedData/Build/Products/Debug-iphonesimulator/Bloom.app"
BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$APP_PATH/Info.plist")"
xcrun simctl install "$DEVICE_ID" "$APP_PATH"
xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID"
