#!/bin/bash

# A script to configure the backend for a given customer
# and then build Flutter for the specified platform (web, ios, or android).

# Default values
CUSTOMER="nutrien"
PLATFORM="web"

which flutter
flutter --version
ls -l pubspec.*
cat pubspec.lock | grep 'package-in-question'

usage() {
  echo "Usage: $0 -c|--customer <customer_name> [--web|--ios|--android]"
  echo ""
  echo "Examples:"
  echo "  $0 --customer nutrien --web"
  echo "  $0 -c default --android"
  echo ""
  echo "Options:"
  echo "  -c, --customer     Customer/brand name (e.g. 'nutrien')"
  echo "  --web              Build for Flutter web"
  echo "  --ios              Build for iOS"
  echo "  --android          Build for Android (APK)"
  echo "  -h, --help         Show this help message"
  exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -c|--customer)
      CUSTOMER="$2"
      shift 2
      ;;
    --web)
      PLATFORM="web"
      shift 1
      ;;
    --ios)
      PLATFORM="ios"
      shift 1
      ;;
    --android)
      PLATFORM="android"
      shift 1
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown parameter: $1"
      usage
      ;;
  esac
done

# Check required parameters
if [[ -z "$CUSTOMER" || -z "$PLATFORM" ]]; then
  echo "Error: You must specify both --customer and one of [--web, --ios, --android]."
  usage
fi

echo "=== Building for customer: $CUSTOMER, platform: $PLATFORM ==="

# 1) Configure the backend branch
#    This calls your existing script that sets up the correct Amplify config, etc.
./scripts/configure-backend-branch.sh -b "$CUSTOMER" || {
  echo "Error calling configure-backend-branch.sh"
  exit 1
}

BASE_HREF="/webapp/$CUSTOMER/web/"

# 2) Run the Flutter build with --dart-define to set APP_COMPANY
case "$PLATFORM" in
  web)
    echo "=== Running: flutter build web --dart-define=APP_COMPANY=$CUSTOMER ==="
    flutter build web --base-href "$BASE_HREF" --dart-define="APP_COMPANY=$CUSTOMER"
    ;;
  ios)
    echo "=== Running: flutter build ios --flavor $CUSTOMER --dart-define=APP_COMPANY=$CUSTOMER ==="
    flutter build ios --flavor $CUSTOMER --dart-define="APP_COMPANY=$CUSTOMER"
    ;;
  android)
    echo "=== Running: flutter build apk --flavor $CUSTOMER --dart-define=APP_COMPANY=$CUSTOMER ==="
    # flutter build apk --flavor $CUSTOMER --dart-define="APP_COMPANY=$CUSTOMER"
    flutter build appbundle --release --flavor maintenance --dart-define="APP_COMPANY=maintenance"
    ;;
  *)
    echo "Unknown platform: $PLATFORM"
    usage
    ;;
esac

echo "=== Build script completed ==="