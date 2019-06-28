#!/usr/bin/env bash
echo "Setting SentryDSN to $SENTRY_DSN"
/usr/libexec/PlistBuddy -c "Set SentryDSN $SENTRY_DSN" "lockbox-ios/Common/Resources/Info.plist"

if ! [ -x "$(command -v swiftlint)" ] ; then
echo "swiftlint is not installed, installing"
brew install swiftlint
else
echo "swiftlint already installed"
fi

if [ "$BUDDYBUILD_SCHEME" = "uispecs" ]; then

# Check if python is installed
python3 --version

cd scripts/
# Install cryptography
pip3 install PyFxA syncclient cryptography
# Run script to upload new login
python3 upload_fake_passwordsBB.py 1
fi
