#!/system/bin/sh
# Please don't hardcode /magisk/modname/... ; instead, please use $MODDIR/...
# This will make your scripts compatible even if Magisk change its mount point in the future
MODDIR=${0%/*}

# static openssl
openssl="${MODDIR}/openssl"
chmod +x "${openssl}"

# This script will be executed in post-fs-data mode
# More info in the main Magisk thread

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
  
  printf 'chrome --ignore-certificate-errors-spki-list=%s\n' "${SPKI}" > "${MODDIR}/chrome-command-line"
}

# Duplicates the created flag file to /data
copyFlagFileToData() {
  while read -r; do
    cp "${MODDIR}/chrome-command-line" "${REPLY}"
    chmod 555 "${REPLY}"
  done < "${MODDIR}/flagfiles.txt"
}

# Causes shouldUseDebugCommandLine() to return true in Chrome while using user build type rom
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
