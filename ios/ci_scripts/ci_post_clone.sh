#!/bin/sh
# Prepares the Flutter and CocoaPods dependencies required by Xcode Cloud.
set -eu

REPOSITORY_PATH="${CI_PRIMARY_REPOSITORY_PATH:?CI_PRIMARY_REPOSITORY_PATH is required}"
FLUTTER_VERSION="3.41.2"
FLUTTER_ROOT="${CI_WORKSPACE_PATH:?CI_WORKSPACE_PATH is required}/flutter-sdk-${FLUTTER_VERSION}"

echo "Installing Flutter ${FLUTTER_VERSION}"
git clone --depth 1 --branch "${FLUTTER_VERSION}" \
  https://github.com/flutter/flutter.git "${FLUTTER_ROOT}"
export PATH="${FLUTTER_ROOT}/bin:${PATH}"

flutter config --no-analytics
flutter --version
flutter precache --ios

cd "${REPOSITORY_PATH}"
flutter pub get

if ! command -v pod >/dev/null 2>&1; then
  HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods
fi

cd ios
pod install --repo-update
