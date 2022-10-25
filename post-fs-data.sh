#!/system/bin/sh
MODDIR=${0%/*}

# Determine architecture with ro.product.cpu.abi
function arch() {
  ABI="$(getprop ro.product.cpu.abi)"
  if [ "${ABI}" = "x86" ]; then
      printf '%s' "x86"
  elif [ "${ABI}" = "x86_64" ]; then
      printf '%s' "x64"
  elif [[ "${ABI}" = "arm64*" ]]; then
      printf '%s' "arm64"
  else
      printf '%s' "arm"
  fi
}

# Figure out which binary to use
openssl="${MODDIR}/bin/openssl-$(arch)"
chmod +x "${openssl}"

# Consumes cert in DER format and prints SPKI fingerprint
der2spki () {
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
    if [ "${FINGERPRINT}" = "" ]; then
      continue
    fi
    printf '%s,' "$(der2spki < "${REPLY}")"
  done
}

# Creates chrome-command-file with chrome flags
createFlagFile() {
  SPKI="$(getUserCertSPKIs)"
  SPKI="${SPKI%,}"

  if [ "${SPKI}" = "" ]; then
    return 1
  fi
  
  printf 'chrome --ignore-certificate-errors-spki-list=%s' "${SPKI}" > "${MODDIR}/chrome-command-line"
}

# Duplicates the created flag file to /data
copyFlagFileToData() {
  while read -r; do
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

# Causes shouldUseDebugCommandLine() to return true in Chrome when running `user` build
fixUserDebug() {
  settings put global adb_enabled 1
  settings put global debug_app com.android.chrome
}

main() {
  createFlagFile || abort "Could not create flag file, did you install any user certificates?"
  copyFlagFileToData
  fixUserDebug
}

main
