1. Install the latest [Xcode developer tools](https://developer.apple.com/xcode/downloads/) from Apple

2. Install Carthage

    ```
    brew update
    brew install carthage
    ```

3. Clone the repository

    ```
    git clone https://github.com/mozilla-lockbox/lockbox-ios
    ```

4. Pull in the project dependencies:

    ```
    cd lockbox-ios
    sh ./bootstrap.sh
    ```

5. Open `Lockbox.xcodeproj` in Xcode

6. Build/Run the `lockbox` scheme in Xcode
