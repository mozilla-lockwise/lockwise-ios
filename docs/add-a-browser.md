# Add a browser setting to Firefox Lockbox

_These instructions are for developers wanting to add another browser setting so when users tap to open an entry's URL it will be sent to the web browser of their choice._


1. Find and add the query scheme the new browser has registered to `LSApplicationQueriesSchemes` in `Common/Resources/Info.plist`. For example we'll use [DuckDuckGo](https://github.com/mozilla-lockbox/lockbox-ios/compare/master...joeyg:duckduckgo?expand=1):

  ```
  <string>ddgQuickLink</string>
  ```


2. Then add a new case to `PreferredBrowserSetting` in `ExternalLinkAction.swift`:

  ```swift
  case DuckDuckGo
  ```

3. Define that new case in the `getPreferredBrowserDeeplink` switch statement and return the string (with that new query scheme as the expected URL syntax):

  ```swift
  case .DuckDuckGo:
    return URL(string: "ddgQuickLink://\(url)")
  ```

3. Add a constant (string) for the name of the browser (this will be used for the setting) to `Common/Resources/Constants.swift`:

  ```swift
  static let settingsBrowserDuckDuckGo = NSLocalizedString("settings.browser.duckduckgo", value: "Duck Duck Go", comment: "Duck Duck Go Browser")
  ```

4. Then include the constant (name of the browser) to the case in the `toString()` function back in `Action/ExternalLinkAction.swift`:

  ```swift
  case .DuckDuckGo:
    return Constant.string.settingsBrowserDuckDuckGo
```

5. Also add the name constant to the `initialSettings` variable in `Presenter/PreferredBrowserSettingPresenter.swift` so the `PreferredBrowserSettingPresenter` class can mark the browser as "checked" when selected:

  ```swift
  lazy var initialSettings = [
    CheckmarkSettingCellConfiguration(text: Constant.string.settingsBrowserDuckDuckGo,
    valueWhenChecked: PreferredBrowserSetting.DuckDuckGo),
  ```
  
That's it!

If you'd like to contribute a patch with the above, or anything else, please read our [contributing guidelines](contributing.md).
