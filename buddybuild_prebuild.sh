#!/usr/bin/env bash
echo "Setting SentryDSN to $SENTRY_DSN"
/usr/libexec/PlistBuddy -c "Set SentryDSN $SENTRY_DSN" "lockbox-ios/Common/Resources/Info.plist"
