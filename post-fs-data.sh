#!/system/bin/sh
MODDIR=${0%/*}

# Testing: ASH_STANDALONE=1 /data/adb/magisk/busybox sh post-fs-data.sh
if [ "${ANDROID_SOCKET_adbd}x" != "x" ]; then
  MODDIR="$(pwd)"
  alias abort=echo
fi

# Consumes cert in DER format and prints SPKI fingerprint
der2spki () {
  openssl="${MODDIR}/openssl"
  chmod +x "${openssl}"
  $openssl x509 -inform der | \
    $openssl x509 -pubkey -noout | \
    $openssl pkey -pubin -outform der | \
    $openssl dgst -sha256 -binary | \
    $openssl enc -base64
}

# Create SPKI fingerprints for all user installed certificates
getUserCertSPKIs() {
  find /data/misc/user/0/cacerts-added -type f | while read -r; do
    FINGERPRINT="$(der2spki < "${REPLY}")"
    if [ "${FINGERPRINT}x" = "x" ]; then
      continue
    fi
    printf '%s,' "$(der2spki < "${REPLY}")"
  done
}

# Creates chrome-command-file with chrome flags
createFlagFile() {
  SPKI="$(getUserCertSPKIs)"
  SPKI="${SPKI%,}"

  if [ "${SPKI}x" = "x" ]; then
    return 1
  fi
  
  printf 'chrome --ignore-certificate-errors-spki-list=%s' "${SPKI}" > "${MODDIR}/chrome-command-line"
}

# Duplicates the created flag file to /data
# Seems like only /data/local/tmp/chrome-command-line is used
copyFlagFileToData() {
  while read -r; do
    #rm -vf "${REPLY}"
    cp -v "${MODDIR}/chrome-command-line" "${REPLY}"
    chmod -v 555 "${REPLY}"
  done <<EOF
/data/local/chrome-command-line
/data/local/android-webview-command-line
/data/local/webview-command-line
/data/local/content-shell-command-line
/data/local/tmp/chrome-command-line
/data/local/tmp/android-webview-command-line
/data/local/tmp/webview-command-line
/data/local/tmp/content-shell-command-line
EOF
}

# Causes shouldUseDebugCommandLine() to return true in Chrome while using user build type rom
fixUserDebug() {
  settings put global adb_enabled 1
  settings put global debug_app com.android.chrome
}

{
  createFlagFile || abort "Could not create flag file, did you install any user certificates?"
  copyFlagFileToData
  fixUserDebug
  # killall com.android.chrome
}
