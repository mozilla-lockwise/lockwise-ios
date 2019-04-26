1. Install Xcode version 10.1

2. Install the latest [Xcode developer tools](https://developer.apple.com/xcode/downloads/) from Apple

3. Install Carthage

    ```
    brew update
    brew install carthage
    ```

4. Clone the repository

    ```
    git clone https://github.com/mozilla-lockbox/lockbox-ios
    ```

5. Pull in the project dependencies:

    ```
    cd lockbox-ios
    sh ./bootstrap.sh
    ```

6. Open `Lockbox.xcodeproj` in Xcode

7. Build/Run the `lockbox` scheme in Xcode
