# Sharing Code between Lockwise + CredentialProvider

### Overview

There are many `View`s, `Presenter`s, and `Store`s with code useful in both the Lockwise application and the CredentialProvider app extension. In service to iOS' restriction that apps and their extension run in separate processes ([extension documentation here](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionOverview.html)), the following code sharing strategy minimizes the amount of code required in each to keep binary sizes small and performance snappy.

### Strategy

Rather than having a custom `.framework` to be imported into both (which is a good candidate for future re-organizing), we have three directories at the top level of the project -- `lockbox-ios`, `CredentialProvider`, and `Shared`. Each of those directories is broken down into the same set of folders. All classes in the `Shared` directory are included in both the `Lockwise` and `CredentialProvider` targets; the other directories' code is included only in their respective targets.

### Inheritance

For classes that are used in both the `CredentialProvider` and `Lockwise`,
