import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:agconnect_crash/agconnect_crash.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:huawei_location/huawei_location.dart';
import 'package:huawei_push/huawei_push.dart';
import 'package:jc_service_wrapper/src/models/location_wrapper.dart';
import 'package:jc_service_wrapper/src/models/remote_message_wrapper.dart';
import 'package:jc_service_wrapper/src/service_wrapper.dart';
import 'package:jc_utils/jc_utils.dart';
import 'package:permission_handler/permission_handler.dart';

//override huawei push background callback
@pragma('vm:entry-point')
void _huaweiPushCallbackDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('Huawei Push: Start Huawei Push Callback Dispatcher');
  const MethodChannel backgroundMessageMethodChannel = MethodChannel(
    'com.huawei.flutter.push/background',
  );

  backgroundMessageMethodChannel.setMethodCallHandler((MethodCall call) async {
    final Function rawHandler = PluginUtilities.getCallbackFromHandle(
      CallbackHandle.fromRawHandle(call.arguments[0]),
    )! as OnBackgroundNotification;
    try {
      /*debugPrint('Huawei Service: received background notification ${call.arguments[1]}');
      debugPrint('Huawei Service: received background notification type ${call.arguments[1].runtimeType}');
      debugPrint('Huawei Service: is String ${call.arguments[1] is String}');
      debugPrint('Huawei Service: is Map ${call.arguments[1] is Map<dynamic, dynamic>}');*/
      await rawHandler(RemoteMessageWrapper.fromHuaweiPush(Map<String, dynamic>.from(call.arguments[1])));
    }
    on TypeError catch (e){
      // ignore: avoid_print
      print(
          'Huawei Push: An error occurred in your background messaging handler:');
      // ignore: avoid_print
      print(e);
      print(e.stackTrace);
    }
    catch (e) {
      // ignore: avoid_print
      print(
          'Huawei Push: An error occurred in your background messaging handler:');
      // ignore: avoid_print
      print(e);
    }
  });

  debugPrint('Huawei Push: Invoke Method BackgroundRunner.initialize');
  backgroundMessageMethodChannel.invokeMethod(
    'BackgroundRunner.initialize',
  );
}

class HuaweiService extends Service{

  Completer<String?> _pushToken = Completer();
  final MethodChannel _methodChannel = const MethodChannel(
    'com.huawei.flutter.push/method',
  );

  late final FusedLocationProviderClient _fusedLocation = FusedLocationProviderClient()
    ..initFusedLocationService();

  @override
  Future<void> initialize(OnBackgroundNotification handler) async {
    try{
      await Push.turnOnPush();

      _registerBackgroundMessageHandler(handler);

      Push.getTokenStream.listen((event){
        if(_pushToken.isCompleted){
          _pushToken = Completer();
        }
        _pushToken.complete(event);
        debugPrint("Huawei Push Token get : $event");
      }, onError: (error) {
        PlatformException e = error;
        if(!_pushToken.isCompleted){
          _pushToken.complete(null);
        }
        debugPrint("Huawei Token Error: ${e.message}");
      });
      Push.getToken("");

      Push.onMessageReceivedStream.listen((event) {
        try{
          debugPrint('HuaweiOnMessage: ${event.toMap()}');
          onReceivedStream.add(RemoteMessageWrapper.fromHuaweiPush(event.toMap()));
        }
        catch(e){
          debugPrint('HuaweiOnMessageException: $e');
        }
      },
          onError: (error){
            debugPrint(error.toString());
          });

      Push.onNotificationOpenedApp.listen((event){
        debugPrint('HuaweiOnMessageOpened: ${event.toString()}');
        final remoteMessage = _dynamicToRemoteMessage(event);
        if(remoteMessage != null){
          onOpenedStream.add(remoteMessage);
        }
      });
    }
    catch(e){
      if(!_pushToken.isCompleted){
        _pushToken.complete(null);
      }
      debugPrint('HuaweiInitializeException: $e');
    }

    final remoteMessageWrapper = await getInitialMessage();
    if(remoteMessageWrapper != null){
      onOpenedStream.add(remoteMessageWrapper);
    }
  }

  Map<String, dynamic> _safeRecursiveCast(Map<Object?, Object?> value){
    Map<String, dynamic> result = {};
    value.forEach((key, value) {
      if (key is String) {
        if (value is Map<Object?, Object?>) {
          // Recursively cast nested maps
          result[key] = _safeRecursiveCast(value);
        } else if (value is List) {
          // Recursively cast lists if they contain maps
          result[key] = _safeRecursiveCastList(value);
        } else {
          // For other types, just assign the value
          result[key] = value;
        }
      } else {
        debugPrint('Skipping invalid key: $key');
      }
    });

    return result;
  }

  List<dynamic> _safeRecursiveCastList(List<dynamic> inputList) {
    return inputList.map((item) {
      if (item is Map<Object?, Object?>) {
        // Recursively cast if the item is a Map
        return _safeRecursiveCast(item);
      } else if (item is List) {
        // Recursively cast nested lists
        return _safeRecursiveCastList(item);
      } else {
        // Otherwise, just return the item as is
        return item;
      }
    }).toList();
  }

  RemoteMessageWrapper? _dynamicToRemoteMessage(dynamic value){
    try{
      if(value is RemoteMessage){
        return RemoteMessageWrapper.fromHuaweiPush(value.toMap());
      }
      if(value is Map<String, dynamic>){
        return RemoteMessageWrapper.fromHuaweiPush(value);
      }
      if(value is String){
        final json = jsonDecode(value);
        return RemoteMessageWrapper.fromHuaweiPush(json);
      }
    }
    catch(e){
      debugPrint('HuaweiDynamicToRemoteMessageException: $e');
    }

    return null;
  }

  Future<void> _registerBackgroundMessageHandler(OnBackgroundNotification handler) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final int rawHandle =
    PluginUtilities.getCallbackHandle(_huaweiPushCallbackDispatcher)!.toRawHandle();
    debugPrint('Huawei Service rawHandle $rawHandle');

    final int rawCallback =
    PluginUtilities.getCallbackHandle(handler)!.toRawHandle();
    debugPrint('Huawei Service rawCallback $rawCallback');

    await _methodChannel.invokeMethod(
      'registerBackgroundMessageHandler',
      <String, int>{
        'rawHandle': rawHandle,
        'rawCallback': rawCallback,
      },
    );
  }

  /*@override
  StreamSubscription onMessage(OnMessageReceived onMessageReceived) =>
      Push.onMessageReceivedStream.listen((event) => onMessageReceived(RemoteMessageWrapper.fromHuaweiPush(event.toMap())),
      onError: (error){
        print(error);
      });

  @override
  StreamSubscription onMessageOpened(OnMessageReceived onMessageReceived) =>
      Push.onNotificationOpenedApp.listen((event) => onMessageReceived(RemoteMessageWrapper.fromHuaweiPush(event.toMap())),
          onError: (error){
            print(error);
          });*/

  @override
  Future<RemoteMessageWrapper?> getInitialMessage() async {
    try{
      var remoteMessage = await Push.getInitialNotification();
      if(remoteMessage != null && remoteMessage is Map){
        final json = _safeRecursiveCast(remoteMessage);
        final Map<String, dynamic> temp = json['remoteMessage'] ?? {};
        temp['uriPage'] = json['uriPage'];
        temp['extras'] = json['extras'];

        final remoteMessageWrapper = _dynamicToRemoteMessage(temp);
        if(remoteMessageWrapper != null){
          return remoteMessageWrapper;
        }
      }
    }
    catch(e){
      debugPrint('HuaweiGetInitialMessageException: $e');
    }
    return null;
  }

  @override
  Future<void> deleteAllNotificationChannel() async {
    final channelList = await Push.getChannels();
    for(final channel in channelList){
      await Push.deleteChannel(channel);
    }
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    try{
      await Push.subscribe(topic);
    }
    catch(e){
      debugPrint('HuaweiSubscribeTopicException: $e');
    }
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    try{
      await Push.unsubscribe(topic);
    }
    catch(e){
      debugPrint('HuaweiUnsubscribeTopicException: $e');
    }
  }

  @override
  Future<String?> getToken() => _pushToken.future;

  @override
  void onFlutterError(FlutterErrorDetails errorDetails) {
    try{
      AGCCrash.instance.onFlutterError(errorDetails);
    }
    catch(e){
      debugPrint('HuaweiFlutterErrorException: $e');
    }
  }

  @override
  void recordError(Object exception, StackTrace stackTrace) {
    try{
      AGCCrash.instance.recordError(exception, stackTrace, fatal: true);
    }
    catch(e){
      debugPrint('HuaweiRecordErrorException: $e');
    }
  }

  @override
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status == PermissionStatus.granted;
  }

  @override
  Future<void> showNotification({
    int? id,
    String? title,
    String? body,
    String? bigText,
    String? payload,
    String? bigPictureUrl,
    String? largeIconUrl,
    bool onGoing = false,
    String? channelId,
    String? channelName,
  }) async {
    final channelInfo = await getNotificationChannel();

    Map<String, dynamic> localNotification = {
      HMSLocalNotificationAttr.CHANNEL_ID: channelId ?? channelInfo['CHANNEL_ID'] ?? CHANNEL_ID,
      HMSLocalNotificationAttr.CHANNEL_NAME: channelName ?? channelInfo['CHANNEL_NAME'] ?? CHANNEL_NAME,
      HMSLocalNotificationAttr.CHANNEL_DESCRIPTION: channelInfo['CHANNEL_DESCRIPTION'] ?? CHANNEL_DESCRIPTION,
      HMSLocalNotificationAttr.TITLE: title,
      HMSLocalNotificationAttr.MESSAGE: body,
      HMSLocalNotificationAttr.ONGOING: onGoing,
      HMSLocalNotificationAttr.AUTO_CANCEL: !onGoing,
      HMSLocalNotificationAttr.IMPORTANCE: Importance.MAX,
      HMSLocalNotificationAttr.COLOR: notificationColor.toHex(),
      if(bigText != null) HMSLocalNotificationAttr.BIG_TEXT: bigText,
      if(largeIconUrl != null) HMSLocalNotificationAttr.LARGE_ICON_URL: largeIconUrl,
      if(bigPictureUrl != null) HMSLocalNotificationAttr.BIG_PICTURE_URL: bigPictureUrl,
    };

    if(id != null) localNotification[HMSLocalNotificationAttr.ID] = id.toString();
    Push.localNotification(localNotification);
  }

  @override
  Future<void> showScheduledNotification({
    int? id,
    String? title,
    String? body,
    String? bigText,
    String? payload,
    String? bigPictureUrl,
    String? largeIconUrl,
    bool onGoing = false,
    String? channelId,
    String? channelName,
    required DateTime scheduledDate
  }) async {

    final channelInfo = await getNotificationChannel();

    Map<String, dynamic> localNotification = {
      HMSLocalNotificationAttr.CHANNEL_ID: channelId ?? channelInfo['CHANNEL_ID'] ?? CHANNEL_ID,
      HMSLocalNotificationAttr.CHANNEL_NAME: channelName ?? channelInfo['CHANNEL_NAME'] ?? CHANNEL_NAME,
      HMSLocalNotificationAttr.CHANNEL_DESCRIPTION: channelInfo['CHANNEL_DESCRIPTION'] ?? CHANNEL_DESCRIPTION,
      HMSLocalNotificationAttr.TITLE: title,
      HMSLocalNotificationAttr.MESSAGE: body,
      HMSLocalNotificationAttr.ONGOING: onGoing,
      HMSLocalNotificationAttr.AUTO_CANCEL: !onGoing,
      HMSLocalNotificationAttr.IMPORTANCE: Importance.MAX,
      HMSLocalNotificationAttr.FIRE_DATE: scheduledDate.millisecondsSinceEpoch,
      HMSLocalNotificationAttr.ALLOW_WHILE_IDLE: true,
      if(bigText != null) HMSLocalNotificationAttr.BIG_TEXT: bigText,
      if(largeIconUrl != null) HMSLocalNotificationAttr.LARGE_ICON_URL: largeIconUrl,
      if(bigPictureUrl != null) HMSLocalNotificationAttr.BIG_PICTURE_URL: bigPictureUrl,
    };

    if(id != null) localNotification[HMSLocalNotificationAttr.ID] = id.toString();
    final response = await Push.localNotificationSchedule(localNotification);
    print('Huawei Service: schedule notification response');
    print(response);
  }

  @override
  Future<void> cancelNotification(int id) => Push.cancelNotificationsWithId([id]);

  @override
  Future<void> cancelAll() => Push.cancelAllNotifications();

  @override
  Future<LocationWrapper?> getCurrentLocation() async {
    var locationRequest = LocationRequest();
    var locationSettingsRequest = LocationSettingsRequest(
      requests: [locationRequest],
      needBle: true,
      alwaysShow: true,
    );
    try{
      var states = await _fusedLocation.checkLocationSettings(locationSettingsRequest);
      print(states);
    }
    catch (e){
      return LocationWrapper.unknownException(e.toString());
    }

    await _fusedLocation.requestLocationUpdates(locationRequest);
    final currentLocation = await _fusedLocation.getLastLocation();

    //debugPrint('Huawei Service: Location ${currentLocation.toMap()}');

    return LocationWrapper.fromLocation(currentLocation.toMap());
  }
}