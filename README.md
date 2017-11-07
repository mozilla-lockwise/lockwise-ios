## Getting Started

This project uses Carthage (available via brew). To install dependencies, run `bootstrap.sh`.

Building the project
--------------------

1. Install the latest [Xcode developer tools](https://developer.apple.com/xcode/downloads/) from Apple.
1. Install Carthage
    ```shell
    brew update
    brew install carthage
    ```
1. Clone the repository:
    ```shell
    git clone https://github.com/mozilla-lockbox/lockbox-ios
    ```
1. Pull in the project dependencies:
    ```shell
    cd mozilla-lockbox
    sh ./bootstrap.sh
    ```
1. Open `Client.xcodeproj` in Xcode.
1. Build the `lockbox-ios` scheme in Xcode.
