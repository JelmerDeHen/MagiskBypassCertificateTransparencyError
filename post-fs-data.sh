#!/system/bin/sh
MODDIR=${0%/*}

printf 'chrome --ignore-certificate-errors-spki-list=1' "${SPKI}" > "${MODDIR}/chrome-command-line"

while read -r; do
  cp "${MODDIR}/chrome-command-line" "${REPLY}"
  chmod 555 "${REPLY}"
done < <<EOF
/data/local/chrome-command-line
/data/local/android-webview-command-line
/data/local/webview-command-line
/data/local/content-shell-command-line
/data/local/tmp/chrome-command-line
/data/local/tmp/android-webview-command-line
/data/local/tmp/webview-command-line
/data/local/tmp/content-shell-command-line
EOF

# Causes shouldUseDebugCommandLine() to return true in Chrome while using user build type rom
settings put global adb_enabled 1
settings put global debug_app com.android.chrome
