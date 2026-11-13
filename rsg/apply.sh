#!/usr/bin/env bash
# RSG monitor branding: icons, logo, colours, app name, built-in server and key.
# Runs inside GitHub Actions right after the source checkout.
set -euo pipefail
cd "$(dirname "$0")/.."

: "${RSG_SERVER:?Secret RSG_SERVER is not set (Settings > Secrets and variables > Actions)}"
: "${RSG_KEY:?Secret RSG_KEY is not set (Settings > Secrets and variables > Actions)}"
APP_NAME="${RSG_APP_NAME:-RSG-monitor}"
VARIANT="${RSG_VARIANT:-full}"
if [ "$VARIANT" = host ]; then PRODUCT="RSG Host"; else PRODUCT="RSG monitor"; fi
export RSG_SERVER RSG_KEY APP_NAME PRODUCT

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
perl -pi -e 's/"RustDesk Remote Desktop"/"$ENV{PRODUCT}"/; s/"ProductName", "RustDesk"/"ProductName", "$ENV{PRODUCT}"/' "$RC"

# 5. Windows install fix: the installer copies rustdesk.exe but then starts
#    "<APP_NAME>.exe", so rename the program file during install (same as update does)
WIN=src/platform/windows.rs
perl -0pi -e 's/copy_exe = copy_exe_cmd\(&src_exe, &exe, &path\)\?,(\r?\n\s*)import_config/copy_exe = format!("{}\\n{}", copy_exe_cmd(&src_exe, &exe, &path)?, rename_exe_cmd(&src_exe, &path)?),$1import_config/' "$WIN"

# 6. our own server is built in, so hide the "please set up your own server" hint
perl -0pi -e 's/(pub fn using_public_server\(\) -> bool \{)(\r?\n)[^\r\n]*\r?\n\}/$1$2    false$2}/' src/common.rs

# 6b. host variant: incoming connections only (no "connect to" field, cannot control other PCs)
if [ "$VARIANT" = host ]; then
  perl -0pi -e 's/pub static ref HARD_SETTINGS: RwLock<HashMap<String, String>> = Default::default\(\);/pub static ref HARD_SETTINGS: RwLock<HashMap<String, String>> = RwLock::new(HashMap::from([("conn-type".to_owned(), "incoming".to_owned())]));/' "$CFG"
  grep -q '"conn-type".to_owned(), "incoming"' "$CFG" || { echo "host patch failed"; exit 1; }
fi

# 7. verify that every patch landed
grep -q "\"$RSG_SERVER\"" "$CFG"          || { echo "server patch failed"; exit 1; }
grep -qF "\"$RSG_KEY\"" "$CFG"            || { echo "key patch failed"; exit 1; }
grep -q "\"$APP_NAME\".to_owned" "$CFG"   || { echo "app name patch failed"; exit 1; }
grep -q "0xFFE30D0C" "$DART"              || { echo "colour patch failed"; exit 1; }
grep -q "rename_exe_cmd(&src_exe, &path)?),"  "$WIN"  || { echo "install fix failed"; exit 1; }
grep -A1 "pub fn using_public_server" src/common.rs | grep -q "false" || { echo "server hint patch failed"; exit 1; }
echo "RSG branding applied: $APP_NAME ($VARIANT) -> $RSG_SERVER"
