# Lockbox for iOS Metrics Plan

_Last Updated: March 14, 2018_

<!-- TOC depthFrom:2 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [Analysis](#analysis)
- [Collection](#collection)
- [List of Proposed Events](#list-of-proposed-events)
- [References](#references)

<!-- /TOC -->

This is the metrics collection plan for the Lockbox iOS app. It documents all events that are planned to be collected through telemetry. It will be updated periodically to reflect all new and planned data collection.

## Analysis

Data collection is done solely for the purpose of product development, improvement and maintenance.

More here TBD

## Collection

Data will be collected using this library:

https://github.com/mozilla-mobile/telemetry-ios/

We plan to submit two ping types.

First is the "core ping", which contains information about the iOS version, architecture, etc of the device lockbox has been installed on:

https://firefox-source-docs.mozilla.org/toolkit/components/telemetry/telemetry/data/core-ping.html

The second is the "focus event ping" which allows us to record event telemetry:

https://github.com/mozilla-mobile/focus-ios/wiki/Event-Tracking-with-Mozilla%27s-Telemetry-Service

The ping types are defined in `lockbox-ios/Common/AppDelegate.swift`. Scheduling of ping transmission is done in the same file.

Every event must contain `category`, `method` and `object` fields, and may optionally contain `value` and `extra` fields as well. Possible values for the former three fields are defined in `lockbox-ios/TelemetryIntegration.swift`

Events related to specific items should have an item id in the extra field where possible.

Here's an example of (something like) the swift code needed to record the event that fires when an item in the entry list is tapped:

```swift
Telemetry.default.recordEvent(
	category: TelemetryEventCategory.action,
	method: TelemetryEventMethod.tap,
	object: TelemetryEventObject.entryList,
	value: nil,
	extras: ["itemid" : itemid]
)
```

Finally, the `appName` metadata sent with each ping should always be 'Lockbox'.

See here for more information on event schemas:

https://firefox-source-docs.mozilla.org/toolkit/components/telemetry/telemetry/collection/events.html#public-js-api

## List of Proposed Events

1. When the app starts up:
	* `category`: action
	* `method`: startup
	* `object`: app
	* `value`: nil
	* `extras`: nil

2. When a user taps the fxa signin button:
	* `category`: action
	* `method`: tap
	* `object`: fxaSigninButton
	* `value`: nil
	* `extras`: nil

2. Whether a user successfully authorizes with FxA:
	* `category`: action
	* `method`: signin
	* `object`: app
	* `value`: `true` or `false`
	* `extras`: ["error" : nil or string]
		* Note: If there is an authentication error, let's put it in the extra field here, if possible.

3. When a user taps an item in the entry list:
	* `category`: action
	* `method`: tap
	* `object`: entryList
	* `value`: nil
	* `extras`: ["itemid" : itemid]

4. When a user taps one of the buttons available after entering the entry view:
	* `category`: action
	* `method`: tap
	* `object`: entryCopyUsernameButton, entryCopyPasswordButton, viewPasswordButton, entryShowPasswordButton
	* `value`: nil
	* `extras`: ["itemid" : itemid]

5. When a user taps the settings button:
	* `category`: action
	* `method`: tap
	* `object`: settingsButton
	* `value`: nil
	* `extras`: nil

6. When a user taps the FAQ button:
	* `category`: action
	* `method`: tap
	* `object`: faqButton
	* `value`: nil
	* `extras`: nil

7. When the app enters the background or foreground:
	* `category`: action
	* `method`: background, foreground
	* `object`: app
	* `value`: nil
	* `extras`: nil

## References

[Library used to collect and send telemetry on iOS](https://github.com/mozilla-mobile/telemetry-ios/)

[Description of the "Core" ping](https://firefox-source-docs.mozilla.org/toolkit/components/telemetry/telemetry/data/core-ping.html)

[Description of the "Focus Event" Ping](https://github.com/mozilla-mobile/focus-ios/wiki/Event-Tracking-with-Mozilla%27s-Telemetry-Service)

[Description of Event Schemas in General](https://firefox-source-docs.mozilla.org/toolkit/components/telemetry/telemetry/collection/events.html#public-js-api)
