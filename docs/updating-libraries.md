# External Dependencies

## Swift frameworks

All Swift frameworks are managed via [Carthage](https://github.com/carthage/carthage). In the home directory for the project, run `carthage update --platform iOS` to fetch & build dependencies.

## C Libraries

Lockbox for iOS uses [cjose](https://github.com/cisco/cjose) for JOSE encryption & decryption in the FxA OAuth flow. The binaries to support this external dependency are provided along with this code (in the `lockbox-ios/binaries` folder). However, if you find yourself wanting to update this library (or either of its dependencies, Jansson or OpenSSL), navigate to the `scripts` directory and run `./update-dependencies`. NOTE: You will have to build the project at least once for the appropriate `binaries` folder to get un-tarred (or you can do it yourself).

## Datastore

Lockbox for iOS uses the Lockbox [Datastore](https://github.com/mozilla-lockbox/lockbox-datastore) to provide data storage & encryption. The datastore code is bundled into a `bundle.js` file using [browserify](http://browserify.org/) (available via npm) and provided along with this code (in the `lockbox-datastore` folder). However, if you find yourself wanting to update this library, clone the source code, install *its* dependencies with `npm install`, and run `browserify lib/index.js -s DataStoreModule -o bundle.js`. Replace the version at `lockbox-datastore/bundle.js` with the newly browserify-ed `bundle.js`.
