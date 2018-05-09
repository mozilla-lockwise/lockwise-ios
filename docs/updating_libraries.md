# External Dependencies

## Swift frameworks

All Swift frameworks are managed via [Carthage](https://github.com/carthage/carthage). In the home directory for the project, run `carthage update --platform iOS` to fetch & build dependencies.

**NOTE:**  In some cases, the Swift frameworks might be built using a different version of Swift (e.g., 4.0 versus 4.1) and an error like the following is encountered for the mismatch:

```
	Incompatible Swift version - framework was built with 4.0.3 (swiftlang-900.0.74.1 clang-900.0.39.2) and the local version is 4.1 (swiftlang-902.0.48 clang-902.0.37.1).
```

If this occurs, run `carthage update --platform iOS --no-use-binaries` to build from sources instead.

## C Libraries

Firefox Lockbox for iOS uses [cjose](https://github.com/cisco/cjose) for JOSE encryption & decryption in the FxA OAuth flow. The binaries to support this external dependency are provided along with this code (in the `lockbox-ios/binaries` folder). However, if you find yourself wanting to update this library (or either of its dependencies, Jansson or OpenSSL), navigate to the `scripts` directory and run `./update-dependencies`. NOTE: You will have to build the project at least once for the appropriate `binaries` folder to get un-tarred (or you can do it yourself).
