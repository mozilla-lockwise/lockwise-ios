# External Dependencies

With the addition of the Credential Provider API in iOS 12, you will need to use **Xcode 10.2.1** and **Swift 4.2.1** (`swiftlang-1000.0.36 clang-1000.10.44`) to work on Lockbox.

## Swift frameworks

All Swift frameworks are managed via [Carthage](https://github.com/carthage/carthage).

1. In the home directory for the project, run `carthage update` to fetch dependencies.

  You cannot use `--no-use-binaries` with Carthage in this project unless you have a Rust environment set up.

2. Grab a quick ☕️ or 🍵 !!

  -  If you receive the "Incompatible Swift version" error you may have a different version of Xcode beta then what we've last built against.

## Rust Dependencies

### `mozilla/application-services` versions

The Lockwise for iOS `application-services` and Xcode versions are tied to Firefox for iOS to limit the burden on the application-services group in maintaining versioned binaries. To check the FxiOS `application-services` version against Lockwise, you can look at [their Cartfile](https://github.com/mozilla-mobile/firefox-ios/blob/master/Cartfile). Any updates to Xcode version must be submitted as PRs and include updates to both this document and the [installation](install.md) document.

Ask in the #application-services channel on Slack or IRC if you need support for application-services versioning.

### Setting up Rust with iOS

If you would like to compile Carthage using `--no-use-binaries`, you need to add iOS targets to your local installation You can do this
