import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_hms_gms_availability/flutter_hms_gms_availability.dart';
import 'package:jc_service_wrapper/src/models/location_wrapper.dart';
import 'package:jc_service_wrapper/src/models/remote_message_wrapper.dart';
import 'package:jc_service_wrapper/src/services/empty_web_service.dart'
  if(dart.library.js) 'package:jc_service_wrapper/src/services/web_service.dart';
import 'package:jc_service_wrapper/src/services/firebase_service.dart';
import 'package:jc_service_wrapper/src/services/huawei_service.dart';
import 'package:jc_service_wrapper/src/utils/service_utils.dart';
import 'package:jc_utils/jc_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class ServiceWrapper{
  ServiceWrapper._();
  factory ServiceWrapper() => _instance;
  static final ServiceWrapper _instance =  ServiceWrapper._();
  ServiceType get serviceType => _serviceType;
  ServiceType _serviceType = ServiceType.NONE;

  bool isInit = false;

  Future<void> initServiceType() async {
    _serviceType = await getServiceType();

    switch(_serviceType){
      case ServiceType.GMS:
        Service.instance = FirebaseService();
        break;
      case ServiceType.HMS:
        Service.instance = HuaweiService();
        break;
      case ServiceType.WEB:
        Service.instance = WebService();
        break;
      default:
    }
  }

  /// WEB: [vapidKey] is needed for Web to get token
  ///
  /// background notification for web need to setup using broadcast channel in firebase-messaging-sw.js
  ///
  /// Please refer to example project for full setup
  ///
  /// Example code:
  /// ```
  /// const channel = new BroadcastChannel('sw-messages');
  ///
  /// // Optional:
  /// messaging.onBackgroundMessage((m) => {
  ///   console.log("onBackgroundMessage", m);
  ///   channel.postMessage(m);
  /// });
  /// ```
  ///
  /// In index.html
  /// ```
  /// const channel = new BroadcastChannel('sw-messages');
  ///  channel.addEventListener("message", function (event) {
  ///    localStorage.setItem('flutter.notificationExist', true)
  ///    window.postMessage(JSON.stringify(event.data))
  ///   })
  /// ```
  Future<void> initialize(
      OnBackgroundNotification onBackgroundNotification,
      {
        FirebaseOptions? options,
        WebTokenOptions? webTokenOptions,
        String? vapidKey,
        List<AndroidNotificationChannel> androidLocalNotificationChannelList = const [],
      }) async {
    if(isInit) return;
    isInit = true;

    _serviceType = await getServiceType();

    switch(_serviceType){
      case ServiceType.GMS:
        Service.instance = FirebaseService();
        await resolveServiceSpecificImplementation<FirebaseService>()
            ?.initialize(
            onBackgroundNotification,
            options: options,
            androidLocalNotificationChannelList: androidLocalNotificationChannelList
        );
        break;
      case ServiceType.HMS:
        Service.instance = HuaweiService();
        await resolveServiceSpecificImplementation<HuaweiService>()
            ?.initialize(onBackgroundNotification);
        break;
      case ServiceType.WEB:
        Service.instance = WebService();
        await resolveServiceSpecificImplementation<WebService>()
            ?.initialize(
            onBackgroundNotification,
            options: options,
          vapidKey: vapidKey,
          webTokenOptions: webTokenOptions,
        );
        break;
      default:
    }

    //crashlytics
    FlutterError.onError = (error){
      onFlutterError(error);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      recordError(error, stack);
      return true;
    };
  }

  T? resolveServiceSpecificImplementation<T extends Service>(){
    if(T == Service){
      throw ArgumentError.value(
        T,
        "The type argument must be a concrete subclass of"
            "Service"
      );
    }

    if((serviceType == ServiceType.GMS &&
      T == FirebaseService &&
      Service.instance is FirebaseService) ||
        (serviceType == ServiceType.HMS &&
            T == HuaweiService &&
            Service.instance is HuaweiService) ||
        (serviceType == ServiceType.WEB &&
            T == WebService &&
            Service.instance is WebService
        )
    ){
      return Service.instance as T?;
    }

    return null;
  }

  Future<ServiceType> getServiceType() async {
    if(kIsWeb) return ServiceType.WEB;
    if(defaultTargetPlatform == TargetPlatform.iOS) return ServiceType.GMS;

    bool google = await FlutterHmsGmsAvailability.isGmsAvailable;
    bool huawei = await FlutterHmsGmsAvailability.isHmsAvailable;

    if(google) return ServiceType.GMS;
    if(huawei) return ServiceType.HMS;

    return ServiceType.NONE;
  }

  Future<String?> getToken() async {
    switch(serviceType){
      case ServiceType.GMS:
        return resolveServiceSpecificImplementation<FirebaseService>()
            ?.getToken();
      case ServiceType.HMS:
        return resolveServiceSpecificImplementation<HuaweiService>()
            ?.getToken();
      case ServiceType.WEB:
        return resolveServiceSpecificImplementation<WebService>()
            ?.getToken();
      default:
        return null;
    }
  }

  Stream<RemoteMessageWrapper>? get onMessageReceivedStream {
    switch(serviceType){
      case ServiceType.GMS:
        return resolveServiceSpecificImplementation<FirebaseService>()
            ?.onMessageReceivedStream;
      case ServiceType.HMS:
        return resolveServiceSpecificImplementation<HuaweiService>()
            ?.onMessageReceivedStream;
      case ServiceType.WEB:
        return resolveServiceSpecificImplementation<WebService>()
            ?.onMessageReceivedStream;
      default:
        return null;
    }
  }

  Stream<RemoteMessageWrapper>? get onMessageOpenedStream {
    switch(serviceType){
      case ServiceType.GMS:
        return resolveServiceSpecificImplementation<FirebaseService>()
            ?.onMessageOpenedStream;
      case ServiceType.HMS:
        return resolveServiceSpecificImplementation<HuaweiService>()
            ?.onMessageOpenedStream;
      case ServiceType.WEB:
        return resolveServiceSpecificImplementation<WebService>()
            ?.onMessageOpenedStream;
      default:
        return null;
    }
  }

  StreamSubscription<RemoteMessageWrapper>? onMessage(OnMessageReceived onMessageReceived) {
    switch(serviceType){
      case ServiceType.GMS:
        return resolveServiceSpecificImplementation<FirebaseService>()
            ?.onMessage(onMessageReceived);
      case ServiceType.HMS:
        return resolveServiceSpecificImplementation<HuaweiService>()
            ?.onMessage(onMessageReceived);
      case ServiceType.WEB:
        return resolveServiceSpecificImplementation<WebService>()
            ?.onMessage(onMessageReceived);
      default:
        return null;
    }
  }

  StreamSubscription<RemoteMessageWrapper>? onMessageOpened(OnMessageReceived onMessageReceived) {
    switch(serviceType){
      case ServiceType.GMS:
        return resolveServiceSpecificImplementation<FirebaseService>()
            ?.onMessageOpened(onMessageReceived);
      case ServiceType.HMS:
        return resolveServiceSpecificImplementation<HuaweiService>()
            ?.onMessageOpened(onMessageReceived);
      case ServiceType.WEB:
        return resolveServiceSpecificImplementation<WebService>()
            ?.onMessageOpened(onMessageReceived);
      default:
        return null;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    switch (serviceType) {
      case ServiceType.GMS:
        return resolveServiceSpecificImplementation<FirebaseService>()
            ?.subscribeToTopic(topic);
      case ServiceType.HMS:
        return resolveServiceSpecificImplementation<HuaweiService>()
            ?.subscribeToTopic(topic);
      case ServiceType.WEB:
        return resolveServiceSpecificImplementation<WebService>()
            ?.subscribeToTopic(topic);
      default:
    }
  }
  Future<void> unsubscribeFromTopic(String topic) async {
    switch (serviceType) {
      case ServiceType.GMS:
        return resolveServiceSpecificImplementation<FirebaseService>()
            ?.unsubscribeFromTopic(topic);
      case ServiceType.HMS:
        return resolveServiceSpecificImplementation<HuaweiService>()
            ?.unsubscribeFromTopic(topic);
      case ServiceType.WEB:
        return resolveServiceSpecificImplementation<WebService>()
            ?.unsubscribeFromTopic(topic);
      default:
    }
  }

  Future<bool?> requestNotificationPermission() async {
    switch (serviceType) {
      case ServiceType.GMS:
        return resolveServiceSpecificImplementation<FirebaseService>()
            ?.requestNotificationPermission();
      case ServiceType.HMS:
        return resolveServiceSpecificImplementation<HuaweiService>()
            ?.requestNotificationPermission();
      case ServiceType.WEB:
        return resolveServiceSpecificImplementation<WebService>()
            ?.requestNotificationPermission();
      default:
        return null;
    }
  }

  Future<void> deleteAllNotificationChannel() async {
    switch (serviceType) {
      case ServiceType.GMS:
        return resolveServiceSpecificImplementation<FirebaseService>()
            ?.deleteAllNotificationChannel();
      case ServiceType.HMS:
        return resolveServiceSpecificImplementation<HuaweiService>()
            ?.deleteAllNotificationChannel();
      default:
        return;
    }
  }

  Future<void> showNotification({
    int? id,
    String? title,
    String? body,
    String? payload,
    String? bigText,
    List<int>? bigPicture,
    List<int>? largeIcon,
    bool onGoing = false,
    String? channelId,
    String? channelName,
    bool isHtmlFormat = false,
    String? bigPictureUrl,
    String? largeIconUrl,
    int? timeoutAfter,
    int? when,
    List<AndroidNotificationAction>? androidActions,
  }) async {
    switch(serviceType){
      case ServiceType.GMS:
        return resolveServiceSpecificImplementation<FirebaseService>()
            ?.showNotification(
            id: id,
            title: title,
            body: body,
            payload: payload,
            onGoing: onGoing,
          bigPicture: bigPicture,
          largeIcon: largeIcon,
          bigText: bigText,
          channelId: channelId,
          channelName: channelName,
          isHtmlFormat: isHtmlFormat,
          timeoutAfter: timeoutAfter,
          when: when,
          androidActions: androidActions,
        );
      case ServiceType.HMS:
        return resolveServiceSpecificImplementation<HuaweiService>()
            ?.showNotification(
            id: id,
            title: title,
            body: body,
            bigPictureUrl: bigPictureUrl,
            largeIconUrl: largeIconUrl,
            payload: payload,
            onGoing: onGoing,
          bigText: bigText,
          channelId: channelId,
          channelName: channelName,
        );
      default:
        return;
    }
  }

  Future<bool> showScheduledNotification({
    int? id,
    String? title,
    String? body,
    String? bigText,
    String? payload,
    List<int>? bigPicture,
    List<int>? largeIcon,
    bool onGoing = false,
    required DateTime scheduledDate,
    String? channelId,
    String? channelName,
    bool isHtmlFormat = false,
    String? bigPictureUrl,
    String? largeIconUrl,
    int? timeoutAfter,
    int? when,
    List<AndroidNotificationAction>? androidActions,
  }) async {
    if(defaultTargetPlatform == TargetPlatform.android){
      final result = await Permission.scheduleExactAlarm.request();
      print(result);
      if(result.isDenied || result.isPermanentlyDenied) return false;
    }

    switch(serviceType){
      case ServiceType.GMS:
        await resolveServiceSpecificImplementation<FirebaseService>()
            ?.showScheduledNotification(
            id: id,
            title: title,
            body: body,
          bigPicture: bigPicture,
          largeIcon: largeIcon,
            payload: payload,
            onGoing: onGoing,
          bigText: bigText,
            scheduledDate: scheduledDate,
          channelId: channelId,
          channelName: channelName,
          isHtmlFormat: isHtmlFormat,
          timeoutAfter: timeoutAfter,
          when: when,
          androidActions: androidActions,
        );
        break;
      case ServiceType.HMS:
        await resolveServiceSpecificImplementation<HuaweiService>()
            ?.showScheduledNotification(
            id: id,
            title: title,
            body: body,
          bigPictureUrl: bigPictureUrl,
          largeIconUrl: largeIconUrl,
            payload: payload,
            onGoing: onGoing,
          bigText: bigText,
            scheduledDate: scheduledDate,
          channelId: channelId,
          channelName: channelName,
        );
        break;
      default:
    }

    return true;
  }

  Future<void> cancelNotification(int id) async {
    switch(serviceType){
      case ServiceType.GMS:
        return resolveServiceSpecificImplementation<FirebaseService>()
            ?.cancelNotification(id);
      case ServiceType.HMS:
        return resolveServiceSpecificImplementation<HuaweiService>()
            ?.cancelNotification(id);
      default:
        return;
    }
  }

  Future<void> cancelAll() async {
    switch(serviceType){
      case ServiceType.GMS:
        return resolveServiceSpecificImplementation<FirebaseService>()
            ?.cancelAll();
      case ServiceType.HMS:
        return resolveServiceSpecificImplementation<HuaweiService>()
            ?.cancelAll();
      default:
        return;
    }
  }

  Future<LocationWrapper?> getCurrentLocation({bool checkPermission = true, Duration? timeLimit}) async {
    if(checkPermission){
      if(defaultTargetPlatform == TargetPlatform.iOS){
        final serviceStatus = await Permission.location.serviceStatus.isDisabled;
        if(serviceStatus) return LocationWrapper.locationServiceDisabled();
      }
      final result = await Permission.location.request();
      if(result.isDenied || result.isPermanentlyDenied){
        if(result.isPermanentlyDenied) return LocationWrapper.permissionPermanentlyDenied();
        return null;
      }
    }

    switch(serviceType){
      case ServiceType.GMS:
        return resolveServiceSpecificImplementation<FirebaseService>()
            ?.getCurrentLocation(timeLimit: timeLimit);
      case ServiceType.HMS:
        return resolveServiceSpecificImplementation<HuaweiService>()
            ?.getCurrentLocation();
      case ServiceType.WEB:
        return resolveServiceSpecificImplementation<WebService>()
            ?.getCurrentLocation();
      default:
        return null;
    }
  }

  void onFlutterError(FlutterErrorDetails errorDetails) {
    switch(serviceType){
      case ServiceType.GMS:
        return resolveServiceSpecificImplementation<FirebaseService>()
            ?.onFlutterError(errorDetails);
      case ServiceType.HMS:
        return resolveServiceSpecificImplementation<HuaweiService>()
            ?.onFlutterError(errorDetails);
      default:
    }
  }
  void recordError(Object exception, StackTrace stackTrace) {
    switch(serviceType){
      case ServiceType.GMS:
        return resolveServiceSpecificImplementation<FirebaseService>()
            ?.recordError(exception, stackTrace);
      case ServiceType.HMS:
        return resolveServiceSpecificImplementation<HuaweiService>()
            ?.recordError(exception, stackTrace);
      default:
    }
  }
}

typedef OnBackgroundNotification = Future<void> Function(RemoteMessageWrapper remoteMessage);
typedef OnMessageReceived = void Function(RemoteMessageWrapper remoteMessage);

abstract class Service{
  Service();
  static late Service _instance;
  static Service get instance => _instance;
  static set instance(Service instance) => _instance = instance;

  String get NOTIFICATION_ICON => "notification_icon";
  String get CHANNEL_ID => "notification_channel";
  String get CHANNEL_NAME => "Notification Channel";
  String get CHANNEL_DESCRIPTION => "Use to post notification";
  Color get notificationColor => const Color(0xffFC9220);

  Future<Map<String, String>> getNotificationChannel() async {
    final packageInfo = await PackageInfo.fromPlatform();

    return {
      'CHANNEL_ID': '${packageInfo.appName.toLowerCase().replaceAll(' ', '_')}_channel',
      'CHANNEL_NAME': packageInfo.appName,
      'CHANNEL_DESCRIPTION': 'Use to post notification for ${packageInfo.appName}',
    };
  }

  final StreamControllerReEmitOnce<RemoteMessageWrapper> onReceivedStream = StreamControllerReEmitOnce<RemoteMessageWrapper>();
  final StreamControllerReEmitOnce<RemoteMessageWrapper> onOpenedStream = StreamControllerReEmitOnce<RemoteMessageWrapper>();

  Future<void> initialize(OnBackgroundNotification handler);
  Future<void> initLocalNotification() async {}
  Future<void> deleteAllNotificationChannel() async {}
  Future<bool> requestNotificationPermission() => throw UnimplementedError('requestNotificationPermission() has not been implemented');

  //notification
  Future<void> showNotification({
    int? id,
    String? title,
    String? body,
    String? bigText,
    String? payload,
    bool onGoing = false,
    String? channelId,
    String? channelName,
  }) async {
    throw UnimplementedError('showNotification() has not been implemented');
  }

  Future<void> showScheduledNotification({
    int? id,
    String? title,
    String? body,
    String? bigText,
    String? payload,
    bool onGoing = false,
    String? channelId,
    String? channelName,
    required DateTime scheduledDate,
  }) async {
    throw UnimplementedError('showScheduledNotification() has not been implemented');
  }
  Future<void> cancelNotification(int id){
    throw UnimplementedError('cancelNotification() has not been implemented');
  }
  Future<void> cancelAll(){
    throw UnimplementedError('cancelAll() has not been implemented');
  }

  //crashlytic
  void onFlutterError(FlutterErrorDetails errorDetails) => throw UnimplementedError('onFlutterError() has not been implemented');
  void recordError(Object exception, StackTrace stackTrace) => throw UnimplementedError('recordError() has not been implemented');

  //remote message
  Stream<RemoteMessageWrapper> get onMessageReceivedStream => onReceivedStream.stream;
  Stream<RemoteMessageWrapper> get onMessageOpenedStream => onOpenedStream.stream;
  Future<RemoteMessageWrapper?> getInitialMessage() => throw UnimplementedError('getInitialMessage() has not been implemented');
  StreamSubscription<RemoteMessageWrapper> onMessage(OnMessageReceived onMessageReceived) => onMessageReceivedStream.listen(onMessageReceived);
  StreamSubscription<RemoteMessageWrapper> onMessageOpened(OnMessageReceived onMessageReceived) => onMessageOpenedStream.listen(onMessageReceived);
  Future<String?> getToken() => throw UnimplementedError('getToken() has not been implemented');
  Future<void> subscribeToTopic(String topic) => throw UnimplementedError('subscribeToTopic() has not been implemented');
  Future<void> unsubscribeFromTopic(String topic) => throw UnimplementedError('unsubscribeFromTopic() has not been implemented');

  //location
  Future<LocationWrapper?> getCurrentLocation() async => throw UnimplementedError('getCurrentLocation() has not been implemented');
}

enum ServiceType{
  NONE,
  GMS,
  HMS,
  WEB;

  static ServiceType fromName(String? type){
    if(type != null){
      for(final t in ServiceType.values){
        if(t.name.toLowerCase() == type.toLowerCase()) return t;
      }
    }

    return ServiceType.NONE;
  }
}