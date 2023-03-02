<div align="center">

# flutter_notification_listener

[![Version](https://img.shields.io/pub/v/flutter_notification_listener.svg)](https://pub.dartlang.org/packages/flutter_notification_listener)
[![pub points](https://badges.bar/flutter_notification_listener/pub%20points)](https://pub.dev/packages/flutter_notification_listener/score)
[![popularity](https://badges.bar/flutter_notification_listener/popularity)](https://pub.dev/packages/flutter_notification_listener/score)
[![likes](https://badges.bar/flutter_notification_listener/likes)](https://pub.dev/packages/flutter_notification_listener/score)
[![License](https://img.shields.io/badge/license-AL2-blue.svg)](https://github.com/jiusanzhou/flutter_notification_listener/blob/master/LICENSE)

Flutter plugin to listen for all incoming notifications for Android.

</div>

---

## Features

- **Service**: start a service to listen the notifications.
- **Simple**: it's simple to access notification's fields.
- **Backgrounded**: execute the dart code in the background and auto start the service after reboot.
- **Interactive**: the notification is interactive in flutter.

## Installtion

Open the `pubspec.yaml` file located inside the app folder, and add `flutter_notification_listener`: under `dependencies`.
```yaml
dependencies:
  flutter_notification_listener: <latest_version>
```

The latest version is 
[![Version](https://img.shields.io/pub/v/flutter_notification_listener.svg)](https://pub.dartlang.org/packages/flutter_notification_listener)

Then you should install it,
- From the terminal: Run `flutter pub get`.
- From Android Studio/IntelliJ: Click Packages get in the action ribbon at the top of `pubspec.yaml`.
- From VS Code: Click Get Packages located in right side of the action ribbon at the top of `pubspec.yaml`.

## Quick Start

**1. Register the service in the manifest**

The plugin uses an Android system service to track notifications. To allow this service to run on your application, the following code should be put inside the Android manifest, between the tags.

```xml
<service android:name="im.zoe.labs.flutter_notification_listener.NotificationsHandlerService"
    android:label="Flutter Notifications Handler"
    android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE">
    <intent-filter>
        <action android:name="android.service.notification.NotificationListenerService" />
    </intent-filter>
</service>
```

And don't forget to add the permissions to the manifest,
```xml
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

**2. Init the plugin and add listen handler**

We have a default static event handler which send event with a channel.
So if you can listen the event in the ui logic simply.

```dart
// define the handler for ui
void onData(NotificationEvent event) {
    print(event.toString());
}

Future<void> initPlatformState() async {
    NotificationsListener.initialize();
    // register you event handler in the ui logic.
    NotificationsListener.receivePort.listen((evt) => onData(evt));
}
```

**3. Check permission and start the service**

```dart
void startListening() async {
    print("start listening");
    var hasPermission = await NotificationsListener.hasPermission;
    if (!hasPermission) {
        print("no permission, so open settings");
        NotificationsListener.openPermissionSettings();
        return;
    }

    var isR = await NotificationsListener.isRunning;

    if (!isR) {
        await NotificationsListener.startService();
    }

    setState(() => started = true);
}
```

---

Please check the [./example/lib/main.dart](./example/lib/main.dart) for more detail.

## Usage

### Start the service after reboot

It's every useful while you want to start listening notifications automatically after reboot.

Register a broadcast receiver in the `AndroidManifest.xml`,
```xml
<receiver android:name="im.zoe.labs.flutter_notification_listener.RebootBroadcastReceiver"
    android:enabled="true">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED" />
    </intent-filter>
</receiver>
```

Then the listening service will start automatically when the system fired the `BOOT_COMPLETED` intent.


And don't forget to add the permissions to the manifest,
```xml
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<!-- this pemission is for auto start service after reboot -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

### Execute task without UI thread

> You should know that the function `(evt) => onData(evt)` would **not be called** if the ui thread is not running.

**:warning: It's recommended that you should register your own static function `callbackHandle` to handle the event which make sure events consumed.**

That means the `callbackHandle` static function is guaranteed, while the channel handle function is not. This is every useful when you should persist the events to the database.

> For Flutter 3.x: 
Annotate the _callback function with `@pragma('vm:entry-point')` to prevent Flutter from stripping out this function on services.

We want to run some code in background without UI thread, like persist the notifications to database or storage.

1. Define your own callback to handle the incoming notifications.
    ```dart
    @pragma('vm:entry-point')
    static void _callback(NotificationEvent evt) {
        // persist data immediately
        db.save(evt)

        // send data to ui thread if necessary.
        // try to send the event to ui
        print("send evt to ui: $evt");
        final SendPort send = IsolateNameServer.lookupPortByName("_listener_");
        if (send == null) print("can't find the sender");
        send?.send(evt);
    }
    ```

2. Register the handler when invoke the `initialize`.
    ```dart
    Future<void> initPlatformState() async {
        // register the static to handle the events
        NotificationsListener.initialize(callbackHandle: _callback);
    }
    ```

3. Listen events in the UI thread if necessary.
    ```dart
    // define the handler for ui
    void onData(NotificationEvent event) {
        print(event.toString());
    }

    Future<void> initPlatformState() async {
        // ...
        // register you event handler in the ui logic.
        NotificationsListener.receivePort.listen((evt) => onData(evt));
    }
    ```

### Change notification of listening service

Before you start the listening service, you can offer some parameters.
```dart
await NotificationsListener.startService({
    bool foreground = true, // use false will not promote to foreground and without a notification
    String title = "Change the title",
    String description = "Change the text",
});
```

### Tap the notification

We can tap the notification if it can be triggered in the flutter side.


For example, tap the notification automatically when the notification arrived.

```dart
// define the handler for ui
void onData(NotificationEvent event) {
    print(event.toString());
    // tap the notification automatically
    // usually remove the notification
    if (event.canTap) event.tap();
}
```

### Tap action of the notification

The notifications from some applications will setted the actions.
We can interact with the notificaions in the flutter side.

For example, make  the notification as readed automatically when the notification arrived.

```dart
// define the handler for ui
void onData(NotificationEvent event) {
    print(event.toString());
    
    events.actions.forEach(act => {
        // semantic code is 2 means this is an ignore action
        if (act.semantic == 2) {
            act.tap();
        }
    })
}
```

### Reply to conversation of the notification

Android provider a quick replying method in the notification.
So we can use this to implement a reply logic in the flutter.

For example, reply to the conversation automatically when the notification arrived.

```dart
// define the handler for ui
void onData(NotificationEvent event) {
    print(event.toString());
    
    events.actions.forEach(act => {
        // semantic is 1 means reply quick
        if (act.semantic == 1) {
            Map<String, dynamic> map = {};
            act.inputs.forEach((e) {
                print("set inputs: ${e.label}<${e.resultKey}>");
                map[e.resultKey] = "Auto reply from flutter";
            });

            // send to the data
            act.postInputs(map);
        }
    })
}
```

## API Reference

### Object `NotificationEvent`

Fields of `NotificationEvent`:
- `uniqueId`: `String`, unique id of the notification which generated from `key`.
- `key`: `String`, key of the status bar notification, required android sdk >= 20.
- `packageName`: `String`, package name of the application which notification posted by.
- `uid`: `int`, uid of the notification, required android sdk >= 29.
- `channelId`: `String` channel if of the notification, required android sdk >= 26.
- `id`: `int`, id of the notification.
- `createAt`: `DateTime`, created time of the notfication in the flutter side.
- `timestamp`: `int`, post time of the notfication.
- `title`: `title`, title of the notification.
- `text`: `String`, text of the notification.
- `hasLargeIcon`: `bool`, if this notification has a large icon.
- `largeIcon`: `Uint8List`, large icon of the notification which setted by setLargeIcon. To display as a image use the Image.memory widget.
- `canTap`: `bool`, if this notification has content pending intent.
- `raw`: `Map<String, dynamic>`, the original map of this notification, you can get all fields.

Other original fields in `raw` which not assgin to the class:
- `subText`: `String`, subText of the notification.
- `summaryText`: `String`, summaryText of the notification.
- `textLines`: `List<String>`, multi text lines of the notification.
- `showWhen`: `bool`, if show the time of the notification.

Methods for notification:
- `Future<bool> tap()`: tap the notification if it can be triggered, you should check `canTap` first. Normally will clean up the notification.
- `Future<dynamic> getFull()`: get the full notification object from android.

### Object `Action`

Fields of `Action`:
- `id`: `int`, the index of the action in the actions array
- `title`: `String`, title of the action
- `semantic`: `int`, semantic type of the action, check below for details
- `inputs`: `ActionInput`, emote inputs list of the action

Action's semantic types:
```
SEMANTIC_ACTION_ARCHIVE = 5;
SEMANTIC_ACTION_CALL = 10;
SEMANTIC_ACTION_DELETE = 4;
SEMANTIC_ACTION_MARK_AS_READ = 2;
SEMANTIC_ACTION_MARK_AS_UNREAD = 3;
SEMANTIC_ACTION_MUTE = 6;
SEMANTIC_ACTION_NONE = 0;
SEMANTIC_ACTION_REPLY = 1;
SEMANTIC_ACTION_THUMBS_DOWN = 9;
SEMANTIC_ACTION_THUMBS_UP = 8;
SEMANTIC_ACTION_UNMUTE = 7;
```

For more details, please see [Notification.Action Constants](https://developer.android.com/reference/android/app/Notification.Action#constants_1).


Methods of `Action`:
- `Future<bool> tap()`: tap the action of the notification. If action's semantic code is `1`, it can't be tapped.
- `Future<bool> postInputs(Map<String, dynamic> map)`: post inputs to the notification, useful for replying automaticly. Only works when semantic code  is `1`.

### Object `ActionInput`

Fields of `ActionInput`:
- `label`: `String`, label for input.
- `resultKey`: `String`, result key for input. Must use correct to post data to inputs.


### Class `NotificationsListener`

Fields of `NotificationsListener`:
- `isRunning`: `bool`, check if the listener service is running.
- `hasPermission`: `bool`, check if grant the permission to start the listener service.
- `receivePort`: `ReceivePort`, default receive port for listening events.

Static methods of `NotificationsListener`:
- `Future<void> initialize()`: initialize the plugin, must be called at first.
- `Future<void> registerEventHandle(EventCallbackFunc callback)`: register the event handler which will be called from android service, **shoube be static function**.
- `Future<void> openPermissionSettings()`: open the system listen notifactoin permission setting page.
- `Future<bool?> startService({...})`: start the listening service. arguments,
    - `foreground`: `bool`, optional, promote the service to foreground.
    - `subTitle`: `String`, optional, sub title of the service's notification.
    - `title`: `String`, optional, title of the service's notification.
    - `description`: `String`, optional, text contenet of the service's notification.
    - `showWhen`: `bool`, optional
- `Future<bool?> stopService()`: stop the listening service.
- `Future<void> promoteToForeground({...})` proomte the service to the foreground. *Arguments are same `startService`*.
- `Future<void> demoteToBackground()`: demote the service to background.

## Known Issues

- If the service is not foreground, service will start failed after reboot.

## Support

Did you find this plugin useful? Please consider to make a donation to help improve it!

## Contributing

Contributions are always welcome!
