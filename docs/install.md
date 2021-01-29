> As of January 28, 2021, Lockwise iOS only builds with Xcode 11.7 and the Swift 5.2.4 that comes with it. Any other version, older or newer is not supported.

1. Install Xcode version 11.7

2. Make the command line tools that ship with Xcode the default:

    ```
    sudo xcode-select -s /Applications/Xcode.app
    ```

3. Install Carthage

    ```
    brew update
    brew install carthage
    ```

4. Clone the repository

    ```
    git clone https://github.com/mozilla-lockwise/lockwise-ios
    ```

5. Pull in the project dependencies:

    ```
    cd lockbox-ios
    sh ./bootstrap.sh
    ```

6. Open `Lockbox.xcodeproj` in Xcode

7. Build/Run the `lockbox` scheme in Xcode
