#!/bin/sh
# Verifies the signed App Store IPA emitted by an Xcode Cloud archive action.
set -eu

if [ "${CI_XCODEBUILD_ACTION:-}" != "archive" ]; then
  exit 0
fi

if [ "${CI_XCODEBUILD_EXIT_CODE:-1}" != "0" ]; then
  echo "xcodebuild failed; no IPA signing verification is possible."
  exit 1
fi

IPA_PATH="${CI_APP_STORE_SIGNED_APP_PATH:?CI_APP_STORE_SIGNED_APP_PATH is required for an archive}"
EXPECTED_BUNDLE_ID="com.lapiramide.laPiramide"

test -f "${IPA_PATH}"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT

unzip -q "${IPA_PATH}" -d "${WORK_DIR}"
APP_PATH="$(find "${WORK_DIR}/Payload" -maxdepth 1 -type d -name '*.app' -print -quit)"
test -n "${APP_PATH}"

codesign --verify --deep --strict --verbose=2 "${APP_PATH}"

BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "${APP_PATH}/Info.plist")"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "${APP_PATH}/Info.plist")"
BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "${APP_PATH}/Info.plist")"

test "${BUNDLE_ID}" = "${EXPECTED_BUNDLE_ID}"
echo "Verified App Store IPA: ${IPA_PATH}"
echo "Bundle ID: ${BUNDLE_ID}; version: ${VERSION}; build: ${BUILD}"
