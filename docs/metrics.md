# Firefox Lockbox for iOS Metrics Plan

_Last Updated: May 1, 2018_

<!-- TOC depthFrom:2 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [Analysis](#analysis)
- [Collection](#collection)
- [List of Proposed Events](#list-of-proposed-events)
- [References](#references)

<!-- /TOC -->

This is the metrics collection plan for the Lockbox iOS app. It documents all events that are planned to be collected through telemetry. It will be updated periodically to reflect all new and planned data collection.

## Analysis

Data collection is done solely for the purpose of product development, improvement and maintenance.

We will analyze the data described in this doc *primarily* with the purpose of (dis)confirming the following hypothesis:

`If Firefox users have access to their browser-saved passwords, outside of the mobile browser, then they will use those passwords to log into accounts (both in mobile browsers and in apps). We will know this to be true when copy credentials (username or password) is the most frequent action taken in the app.`

Note that because the first version of the app will not allow for "auto-filling" of credentials, the copy events (and to a lesser extent, the password reveal events) are the best signal we have that users are gaining the intended value from the app.

In service to validating the above hypothesis, we plan on answering these specific questions, given the data we plan to collect (see [List of Proposed Events](#list-of-proposed-events)):

*Note that when referring to copying of "credentials", we mean copying of either usernames or passwords.*

* Are users using Lockbox to retrieve credentials?
	* For different intervals of time (e.g. day, week, month), what is:
		* The average rate with which a user copies a credential or reveals a password
		* The distribution of above rates across all users
* Pending the implementation of a share sheet, how often do users access Lockbox via a mobile browser?
	* Out of all the times a credential was copied, how often was it a result of tap on the share sheet?
		* This will help us understand whether users are primarily accessing credentials for use in a browser or with third party apps.
* Once downloaded, do users continue to use the app? (i.e., how well are they retained?)
	* We will count a user as retained in a given time interval if they perform one of the following actions:
		* Display the credential list
		* Tap a credential in the credential list
		* Copy a credential to the clipboard
		* Reveal a password
		* Tap the URI associated with a credential (to open it in an app or browser)
	* Since they can be performed automatically, we will **not** count a user as retained if they *only* perform the following actions (in absence of any in the list above):
		* Unlock their credentials
		* Sync their credentials from the Firefox desktop browser
* Does requiring a Firefox Account constitute a roadblock to adoption?
	* What proportion of new Lockbox users are pre-existing Firefox Account users?
	* What proportion of users start the Account sign-in process but never complete it?
* Does adoption of Lockbox lead to adoption of Firefox Mobile browsers (e.g. Focus)?
	* Do users set the default browser in Lockbox to be a Firefox-related browser?

In addition to answering the above questions that directly concern actions in the app, we will also be analyzing telemetry emitted from the password manager that exists in the the Firefox desktop browser. These analyses will primarily examine whether users of Lockbox start active curation of their credentials in the desktop browser (Lockbox users will not be able to edit credentials directly from the app).

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

## List of Implemented Events

1. When the app starts up:
	* `category`: action
	* `method`: startup
	* `object`: app
	* `value`: nil
	* `extras`: nil

2. Events that fire during the signin process:
	* `category`: action
	* `method`: show
	* `object`: login_welcome, login_fxa, login_learn_more
	* `value`: nil
	* `extras`: nil

3. When the main item list is shown to the user:
	* `category`: action
	* `method`: show
	* `object`: entryList
	* `value`: nil
	* `extras`: nil

4. When a user shows the details of an item in the entry list:
	* `category`: action
	* `method`: show
	* `object`: entryDetail
	* `value`: nil
	* `extras`: ["itemid" : itemid]

5. When a user taps one of the copy buttons available after being shown entry details:
	* `category`: action
	* `method`: tap
	* `object`: entryCopyUsernameButton, entryCopyPasswordButton
	* `value`: nil
	* `extras`: ["itemid" : itemid]

6. When a user shows details from an item, is the password shown?:
	* `category`: action
	* `method`: tap
	* `object`: reveal_password
	* `value`: true or false, whether the pw is displayed
	* `extras`: nil

7. When one of the settings pages is shown to the user:
	* `category`: action
	* `method`: show
	* `object`: settings_list, settings_autolock, settings_preferred_browser, settings_account, settings_faq, settings_provide_feedback
	* `value`: whatever the value of each of the above was changed to, or nil for settings_reset
	* `extras`: nil

8. When a user changes something on the settings page:
	* `category`: action
	* `method`: settingsChanged
	* `object`: settings_biometric_login, settings_autolock_time, settings_reset, settings_visual_lock, settings_preferred_browser, settings_record_usage_data
	* `value`: whatever the value of each of the above was changed to, or nil for settings_reset
	* `extras`: nil

9. When the app enters the background or foreground:
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
