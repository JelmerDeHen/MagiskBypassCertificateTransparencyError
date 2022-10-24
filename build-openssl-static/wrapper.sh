#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Build & print image ID
function buildAndGetDockerId() {
  # Cache the build
  if ! docker 1>&2 build .; then
    printf >&2 'Build failed\n'
    return 2
  fi

  # Get the ID
  local ID
  if ! ID="$(docker build -q .)"; then
    printf >&2 'Build fail\n'
    return 3
  fi

  printf '%s' "${ID}"
}

# Finds ndk locally
function getNdkPath() {
  local SDK
  if [ -n "${ANDROID_HOME}" ]; then
    SDK="${ANDROID_HOME}"
  elif [ -n "${ANDROID_SDK_ROOT}" ]; then
    SDK="${ANDROID_SDK_ROOT}"
  else
    return 1
  fi

  if ! [ -d "${SDK}/ndk" ]; then
    return 2
  fi
  
  local NDK
  # Find numerically highest version
  if ! NDK="$(find "${SDK}/ndk" -mindepth 1 -maxdepth 1 -type d | sort -n | tail -n1)"; then
    return 3
  fi

  if ! [ -d "${NDK}" ]; then
      return 4
  fi

  printf '%s' "${NDK}"
}

build() {
  local ID NDK
  if ! ID="$(buildAndGetDockerId)"; then
    return 1
  fi

  if ! NDK="$(getNdkPath)"; then
    printf 'Could not find NDK\n'
    return 2
  fi

  # Artifcats are stored in out
  mkdir -pv "${DIR}/out"
  chmod 777 "${DIR}/out"

  docker run --rm -ti \
    -v "${DIR}/out:/out" \
    -v "${NDK}:/ndk" \
    "${ID}"
}

# docker run
function attach() {
  local ID NDK
  if ! ID="$(buildAndGetDockerId)"; then
    return 1
  fi
  
  if ! NDK="$(getNdkPath)"; then
    printf 'Could not find NDK\n'
    return 2
  fi

  docker run --rm -ti \
    -v "${DIR}/out:/out" \
    -v "${NDK}:/ndk" \
    --entrypoint /bin/bash \
      "${ID}"
}

main() {
  if [ "${1}" = "build" ]; then
    build
  elif [ "${1}" = "attach" ]; then
    attach
  else
    printf '%s <build|attach>\n' "${0}"
  fi
}

if [[ "${BASH_SOURCE[0]}" = "${0}" ]]; then
  main "$@"
fi
