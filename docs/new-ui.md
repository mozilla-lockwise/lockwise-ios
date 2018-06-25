# Adding new UI or features to Firefox Lockbox

## Testing

Is it covered by XCUITests already? If not, make sure to add `accessibilityID`s to all relevant view components in the form:
- `descriptiveCamelCase.button` for buttons
- `descriptiveCamelCase.textField` for text fields
- etc...

## Accessibility

Have you tried using VoiceOver to access your feature? Do all important and / or visible view components have `accessibilityLabel`s?

## Localization

Does your feature have strings? They should probably go in `Constants.swift` (more recommendations tbd on localization infrastructure for Lockbox)

## User Defaults

Are you adding a new value to `UserDefaults`? Is there an upgrade path for users that don't have the value yet?
