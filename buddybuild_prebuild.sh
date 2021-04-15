#!/usr/bin/env bash
echo "Setting SentryDSN to $SENTRY_DSN"
/usr/libexec/PlistBuddy -c "Set SentryDSN $SENTRY_DSN" "lockbox-ios/Common/Resources/Info.plist"

if ! [ -x "$(command -v swiftlint)" ] ; then
echo "swiftlint is not installed, installing"
brew install swiftlint
else
echo "swiftlint already installed"
fi
