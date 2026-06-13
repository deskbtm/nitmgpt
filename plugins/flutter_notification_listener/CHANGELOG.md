## 1.4.0

- feat: add Android 14 (API 34) support
- feat: upgrade Android Gradle Plugin to 8.7.0 and Kotlin to 2.1.0
- fix: add `@pragma('vm:entry-point')` annotation to `callbackDispatcher` for Flutter 3.x compatibility
- fix: add `RECEIVER_NOT_EXPORTED` flag for Android 13+ BroadcastReceiver registration
- fix: handle nullable Drawable in `convertIconToByteArray`
- chore: add required permissions for Android 13/14 (`POST_NOTIFICATIONS`, `FOREGROUND_SERVICE_SPECIAL_USE`)
- chore: upgrade example project to new Flutter Gradle plugin format

## 1.3.4

- chore: support gradle plugin version

## 1.3.3

- bugfix: fix NullPointerException sometimes thrown by label field

## 1.3.2

- bugfix: with some kotlin version build error (asserts-null)

## 1.3.1

- chore: imporve code style
- bugfix: fix foreground when first started, #16

## 1.3.0

- feature: support full notification information
- chore: add funding support

## 1.2.0

- feature: add unique id for notification
- feature: support interactive notification
- chore: add docs for readme

## 1.1.3

- fix: add try catch while invoke method

## 1.1.2

- hotfix: fix exception of some app send bitmap as large icon

## 1.1.1

- hotfix: fix utils class miss


## 1.1.0

- feature: add notification id
- feature: add notification large icon

## 1.0.8

- hotfix: fix start service failed after reboot

## 1.0.7

- feature: add foreground service 

## 1.0.6

- fix: charseq cause excatpion

## 1.0.5

- fix: textLines cause panic
- chore: format code

## 1.0.4

- chore
## 1.0.3

- remove extra

## 1.0.1

- fix dart in backgroun run
- change the api for register handle
- add log in android

## 1.0.0

First implement.
