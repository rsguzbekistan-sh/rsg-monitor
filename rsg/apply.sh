#!/usr/bin/env bash
# RSG monitor branding: icons, logo, colours, app name, built-in server and key.
# Runs inside GitHub Actions right after the source checkout.
set -euo pipefail
cd "$(dirname "$0")/.."

: "${RSG_SERVER:?Secret RSG_SERVER is not set (Settings > Secrets and variables > Actions)}"
: "${RSG_KEY:?Secret RSG_KEY is not set (Settings > Secrets and variables > Actions)}"
APP_NAME="${RSG_APP_NAME:-RSG-monitor}"
export RSG_SERVER RSG_KEY APP_NAME

# 1. icons and logos
cp -R rsg/overlay/. .

# 2. built-in server, key and app name
CFG=libs/hbb_common/src/config.rs
perl -0pi -e 's/pub const RENDEZVOUS_SERVERS: &\[&str\] = &\[[^\]]*\];/pub const RENDEZVOUS_SERVERS: &[&str] = &["$ENV{RSG_SERVER}"];/' "$CFG"
perl -0pi -e 's/pub const RS_PUB_KEY: &str = "[^"]*";/pub const RS_PUB_KEY: &str = "$ENV{RSG_KEY}";/' "$CFG"
perl -0pi -e 's/RwLock::new\("RustDesk"\.to_owned\(\)\)/RwLock::new("$ENV{APP_NAME}".to_owned())/' "$CFG"

# 3. brand colours (red accent)
DART=flutter/lib/common.dart
perl -pi -e 's/0xFF0071FF/0xFFE30D0C/g; s/0x770071FF/0x77E30D0C/g; s/0xAA0071FF/0xAAE30D0C/g; s/0xFF2C8CFF/0xFFE30D0C/g; s/0xFF00B6F0/0xFFE30D0C/g' "$DART"

# 4. Windows file properties
RC=flutter/windows/runner/Runner.rc
perl -pi -e 's/"RustDesk Remote Desktop"/"RSG monitor"/; s/"ProductName", "RustDesk"/"ProductName", "RSG monitor"/' "$RC"

# 5. verify that every patch landed
grep -q "\"$RSG_SERVER\"" "$CFG"          || { echo "server patch failed"; exit 1; }
grep -qF "\"$RSG_KEY\"" "$CFG"            || { echo "key patch failed"; exit 1; }
grep -q "\"$APP_NAME\".to_owned" "$CFG"   || { echo "app name patch failed"; exit 1; }
grep -q "0xFFE30D0C" "$DART"              || { echo "colour patch failed"; exit 1; }
echo "RSG branding applied: $APP_NAME -> $RSG_SERVER"
