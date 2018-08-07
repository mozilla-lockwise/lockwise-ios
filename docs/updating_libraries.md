# External Dependencies

With the addition of the Credential Provider API in iOS 12, you will need to use **Xcode 10** (beta 5) and **Swift 4.2** (`swiftlang-1000.0.32.1 clang-1000.10.39`) to work on Lockbox.

And if you are running the beta, and haven't already: `sudo xcode-select --switch` to point to the beta Xcode app

## Swift frameworks

All Swift frameworks are managed via [Carthage](https://github.com/carthage/carthage).

1. In the home directory for the project, run `carthage update` to fetch dependencies.

  You cannot use `--no-use-binaries` with Carthage in this project unless you have the proper Rust environment set up. Documentation is forthcoming on the right way to do this.

2. Grab a quick ☕️ or 🍵 !!

  -  If you recieve the "Incompatible Swift version" error you may have a different version of Xcode beta then what we've last built against.
