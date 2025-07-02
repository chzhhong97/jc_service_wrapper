import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:jc_service_wrapper/src/models/location_wrapper.dart';
import 'package:jc_service_wrapper/src/models/remote_message_wrapper.dart';
import 'package:jc_service_wrapper/src/service_wrapper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

@pragma('vm:entry-point')
void _firebaseMessagingCallbackDispatcher() {
  // Initialize state necessary for MethodChannels.
  WidgetsFlutterBinding.ensureInitialized();

  const MethodChannel _channel = MethodChannel(
    'plugins.flutter.io/firebase_messaging_background',
  );

  // This is where we handle background events from the native portion of the plugin.
  _channel.setMethodCallHandler((MethodCall call) async {
    if (call.method == 'MessagingBackground#onMessage') {
      final CallbackHandle handle =
      CallbackHandle.fromRawHandle(call.arguments['userCallbackHandle']);

      // PluginUtilities.getCallbackFromHandle performs a lookup based on the
      // callback handle and returns a tear-off of the original callback.
      final closure = PluginUtilities.getCallbackFromHandle(handle)!
      as OnBackgroundNotification;

      try {
        Map<String, dynamic> messageMap =
        Map<String, dynamic>.from(call.arguments['message']);
        await closure(RemoteMessageWrapper.fromFirebaseMessage(messageMap));
      } catch (e) {
        // ignore: avoid_print
        print(
            'FirebaseService Messaging: An error occurred in your background messaging handler:');
        // ignore: avoid_print
        print(e);
      }
    } else {
      throw UnimplementedError('${call.method} has not been implemented');
    }
  });

  // Once we've finished initializing, let the native portion of the plugin
  // know that it can start scheduling alarms.
  _channel.invokeMethod<void>('MessagingBackground#initialized');
}

class FirebaseService extends Service{

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _bgHandlerInitialized = false;
  Completer? _localNotificationInitialized;
  final MethodChannel channel = const MethodChannel(
    'plugins.flutter.io/firebase_messaging',
  );

  @override
  Future<void> initialize(OnBackgroundNotification handler, {dynamic options,  List<AndroidNotificationChannel> androidLocalNotificationChannelList = const []}) async {
    /*await Firebase.initializeApp(
      options: options
    );

    await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true
    );

    _registerBackgroundMessageHandler(handler);
    FirebaseMessaging.onMessage.listen((event) {
      onReceivedStream.add(RemoteMessageWrapper.fromFirebaseMessage(event.toMap()));
    });

    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      onOpenedStream.add(RemoteMessageWrapper.fromFirebaseMessage(event.toMap()));
    });

    debugPrint('Firebase FCM Token: ${await getToken()}');

    var initialMsg = await FirebaseMessaging.instance.getInitialMessage();
    if(initialMsg != null){
      print('Got Initial Message');
      onOpenedStream.add(RemoteMessageWrapper.fromFirebaseMessage(initialMsg.toMap()));
    }*/

    await initLocalNotification(androidLocalNotificationChannelList: androidLocalNotificationChannelList);
  }

  @override
  Future<void> initLocalNotification({List<AndroidNotificationChannel> androidLocalNotificationChannelList = const []}) async {
    print('Local Notification: Start init');
    print('Local Notification: Completer, isNull: ${_localNotificationInitialized == null}, isCompleted: ${_localNotificationInitialized?.isCompleted}');
    if(_localNotificationInitialized?.isCompleted == true){
      print('Local Notification: already initialize');
      return;
    }

    if(_localNotificationInitialized != null && _localNotificationInitialized?.isCompleted != true){
      print('Local Notification: Waiting initialize');
      await _localNotificationInitialized?.future;
      return;
    }

    _localNotificationInitialized ??= Completer();

    var android = AndroidInitializationSettings(NOTIFICATION_ICON);
    var ios = const DarwinInitializationSettings();
    var settings = InitializationSettings(android: android, iOS: ios);

    await _notificationsPlugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (response){
          debugPrint('On Local Notification Tap');
          if(response.payload != null){
            try{
              final json = jsonDecode(response.payload.toString());
              onOpenedStream.add(RemoteMessageWrapper.fromJson(json));
            }
            catch (e){
              print(e);
              print('Please set local notification payload with remote json');
            }
          }
        }
    );

    tz.initializeTimeZones();
    final locationName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(locationName));

    if(Platform.isAndroid){
      final channelInfo = await getNotificationChannel();
      var androidNotificationChannel = AndroidNotificationChannel(
        channelInfo['CHANNEL_ID'] ?? CHANNEL_ID,
        channelInfo['CHANNEL_NAME'] ?? CHANNEL_NAME,
        description: channelInfo['CHANNEL_DESCRIPTION'] ?? CHANNEL_DESCRIPTION,
        importance: Importance.max,
      );
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidNotificationChannel);

      if(androidLocalNotificationChannelList.isNotEmpty){
        for(final channel in androidLocalNotificationChannelList){
          await _notificationsPlugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.createNotificationChannel(channel);
        }
      }

      /*_notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.deleteNotificationChannel('cmgin_channel');*/
      //_notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    }

    _localNotificationInitialized?.complete();
    print('Local Notification: Done initialize');
  }

  @override
  Future<void> deleteAllNotificationChannel() async {
    if(Platform.isAndroid){
      final channelList = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.getNotificationChannels();

      if(channelList == null) return;

      for(final channel in channelList){
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.deleteNotificationChannel(channel.id);
      }
    }
  }

  Future<void> _registerBackgroundMessageHandler(OnBackgroundNotification handler) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    if (!_bgHandlerInitialized) {
      _bgHandlerInitialized = true;
      final CallbackHandle bgHandle = PluginUtilities.getCallbackHandle(
        _firebaseMessagingCallbackDispatcher,
      )!;
      final CallbackHandle userHandle =
      PluginUtilities.getCallbackHandle(handler)!;
      await channel.invokeMapMethod('Messaging#startBackgroundIsolate', {
        'pluginCallbackHandle': bgHandle.toRawHandle(),
        'userCallbackHandle': userHandle.toRawHandle(),
      });
    }
  }

  @override
  Future<RemoteMessageWrapper?> getInitialMessage() async {
    /*var initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if(initialMessage != null){
      return RemoteMessageWrapper.fromFirebaseMessage(initialMessage.toMap());
    }*/
    return null;
  }

  @override
  Future<void> showNotification({
    int? id,
    String? title,
    String? body,
    String? bigText,
    String? payload,
    List<int>? bigPicture,
    List<int>? largeIcon,
    bool onGoing = false,
    String? channelId,
    String? channelName,
    bool isHtmlFormat = false,
    int? timeoutAfter,
    int? when,
    List<AndroidNotificationAction>? androidActions,
  }) async {
    await initLocalNotification();
    return _notificationsPlugin.show(
        id ?? 0,
        title,
        body,
        await _notificationDetails(
          title: title,
          body: body,
          bigText: bigText,
          onGoing: onGoing,
          bigPicture: bigPicture,
          largeIcon: largeIcon,
          channelId: channelId,
          channelName: channelName,
          isHtmlFormat: isHtmlFormat,
          timeoutAfter: timeoutAfter,
          when: when,
          androidActions: androidActions,
        ),
        payload: payload
    );
  }

  @override
  Future<void> showScheduledNotification({
    int? id,
    String? title,
    String? body,
    String? bigText,
    String? payload,
    List<int>? bigPicture,
    List<int>? largeIcon,
    bool onGoing = false,
    String? channelId,
    String? channelName,
    bool isHtmlFormat = false,
    required DateTime scheduledDate,
    int? timeoutAfter,
    int? when,
    List<AndroidNotificationAction>? androidActions,
  }) async {
    await initLocalNotification();
    return _notificationsPlugin.zonedSchedule(
      id ?? 0,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      await _notificationDetails(
        title: title,
        body: body,
        bigText: bigText,
        onGoing: onGoing,
        bigPicture: bigPicture,
        largeIcon: largeIcon,
        channelId: channelId,
        channelName: channelName,
        isHtmlFormat: isHtmlFormat,
        timeoutAfter: timeoutAfter,
        when: when,
        androidActions: androidActions,
      ),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<NotificationDetails> _notificationDetails({
    String? title,
    String? body,
    String? bigText,
    List<int>? bigPicture,
    List<int>? largeIcon,
    String? channelId,
    String? channelName,
    bool onGoing = false,
    bool isHtmlFormat = false,
    int? timeoutAfter,
    int? when,
    List<AndroidNotificationAction>? androidActions,
  }) async {
    final bigPictureObj = _getBase64StringFromBytes(bigPicture);
    largeIcon ??= bigPicture;

    final styleInformation = bigPictureObj != null
        ? BigPictureStyleInformation(
      bigPictureObj,
      contentTitle: title,
      summaryText: body,
      hideExpandedLargeIcon: largeIcon != null,
      htmlFormatContent: isHtmlFormat,
      htmlFormatContentTitle: isHtmlFormat,
      htmlFormatSummaryText: isHtmlFormat,
      htmlFormatTitle: isHtmlFormat,
    )
        : bigText != null ? BigTextStyleInformation(
      bigText,
      contentTitle: title,
      summaryText: body,
      htmlFormatTitle: isHtmlFormat,
      htmlFormatSummaryText: isHtmlFormat,
      htmlFormatContentTitle: isHtmlFormat,
      htmlFormatContent: isHtmlFormat,
      htmlFormatBigText: isHtmlFormat,
    ) : null;

    final channelInfo = await getNotificationChannel();

    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId ?? channelInfo['CHANNEL_ID'] ?? CHANNEL_ID,
        channelName ?? channelInfo['CHANNEL_NAME'] ?? CHANNEL_NAME,
        channelDescription: channelInfo['CHANNEL_DESCRIPTION'] ?? CHANNEL_DESCRIPTION,
        color: notificationColor,
        importance: Importance.max,
        priority: Priority.max,
        styleInformation: styleInformation,
        ongoing: onGoing,
        autoCancel: !onGoing,
        largeIcon: _getBase64StringFromBytes(largeIcon),
        timeoutAfter: timeoutAfter,
        when: when,
        actions: androidActions,
      ),
      iOS: DarwinNotificationDetails(
        attachments: await _getIOSBigPicture(bigPicture),
      ),
    );
  }

  AndroidBitmap<Object>? _getBase64StringFromBytes(List<int>? bytes){
    if(bytes == null) return null;

    try{
      return ByteArrayAndroidBitmap.fromBase64String(base64Encode(bytes));
    }
    catch(e){

    }

    return null;
  }

  Future<List<DarwinNotificationAttachment>> _getIOSBigPicture(List<int>? bytes) async {
    if(defaultTargetPlatform == TargetPlatform.iOS && bytes != null){
      final dir = await getTemporaryDirectory();
      final fileName = '${dir.path}/temp_image.png';

      final file = File(fileName);
      await file.writeAsBytes(bytes);

      return [
        DarwinNotificationAttachment(fileName),
      ];
    }
    return [];
  }

  @override
  Future<void> cancelNotification(int id) async {
    await initLocalNotification();
    return _notificationsPlugin.cancel(id);
  }

  @override
  Future<void> cancelAll() async {
    await initLocalNotification();
    return _notificationsPlugin.cancelAll();
  }

  @override
  Future<LocationWrapper?> getCurrentLocation({Duration? timeLimit}) async {
    return null;
  }
}