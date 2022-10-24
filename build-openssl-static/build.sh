#!/bin/bash
# This will be executed on the container
compile() {
  local TARGET="${1}"

  # Without -D__ANDROID__=33 it targets latest version
  if ! ./Configure "${1}" no-asm no-hw no-engine no-threads no-tests -static; then
    printf >&2 './Configure failed for %s\n' "${TARGET}"
    return 1
  fi

  if ! make -j"$(nproc)"; then
    printf >&2 'Failed to build %s\n' "${1}"
    return 2
  fi
}

main() {
  local -a TARGETS=("android-arm" "android-arm64" "android-x86" "android-x86_64")
  local TARGET

  rm -f /out/*

  for TARGET in "${TARGETS[@]}"; do
    if ! compile "${TARGET}"; then
      break
    fi

    [ "${TARGET}" = "android-x86_64" ] && TARGET="android-x64"

    cp apps/openssl "/out/openssl${TARGET#android}"
    make clean
  done
}

main
