#!/bin/bash

# Consumes cert in DER format and prints SPKI
function der2spki () {
  cat | \
    openssl x509 -inform der | \
    openssl x509 -pubkey -noout | \
    openssl pkey -pubin -outform der | \
    openssl dgst -sha256 -binary | \
    openssl enc -base64
}

# Get SPKIs from installed user certificates
function derFromAdb2spki () {
  while read -r; do
    adb shell su -c cat "${REPLY}" | der2spki
  done < <(adb shell su -c find /data/misc/user/0/cacerts-added/ -type f)
}

function main() {
  case "${1,,}" in
    adb)
      derFromAdb2spki
      ;;
    *)
      if [ -f "${1}" ]; then
        der2spki < "${1}"
        return
      fi
      printf "Usage: %s <adb|der>\n" "${0}"
      ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" = "${0}" ]]; then
  main "$@"
fi

