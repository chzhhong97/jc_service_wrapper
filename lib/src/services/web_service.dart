import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jc_service_wrapper/src/models/location_wrapper.dart';
import 'package:jc_service_wrapper/src/models/remote_message_wrapper.dart';
import 'package:jc_service_wrapper/src/service_wrapper.dart';
import 'package:jc_service_wrapper/src/utils/service_utils.dart';

class WebService extends Service {
  Completer<String?>? _tokenCompleter;
  String? vapidKey;
  WebTokenOptions? webTokenOptions;
  bool _previousStatus = false;

  @override
  Future<void> initialize(
    OnBackgroundNotification handler, {
    FirebaseOptions? options,
    String? vapidKey,
    WebTokenOptions? webTokenOptions,
  }) async {
    this.vapidKey = vapidKey;
    this.webTokenOptions = webTokenOptions;

    await Firebase.initializeApp(options: options);

    //FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);
    FirebaseMessaging.onMessage.listen((event) {
      onReceivedStream
          .add(RemoteMessageWrapper.fromFirebaseMessage(event.toMap()));
    });

    html.window.onMessage.listen((html.MessageEvent event) {
      if(!event.data.toString().contains("messageId")) return;

      try {
        handler.call(RemoteMessageWrapper.fromFirebaseMessage(
            jsonDecode(event.data.toString())));
      } catch (e) {
        debugPrint(
            'Failed to parse web background notification: ${event.data}');
      }
    });

    getToken();
  }

  @override
  Future<void> subscribeToTopic(String topic) => Future.value();
  @override
  Future<void> unsubscribeFromTopic(String topic) => Future.value();

  @override
  Future<String?> getToken() async {
    final status = await requestNotificationPermission();
    if (!status) {
      return null;
    }

    if(status != _previousStatus){
      _previousStatus = status;
      if(status) _tokenCompleter = null;
    }

    if (_tokenCompleter == null) {
      _tokenCompleter = Completer();
      _getWebToken(
          vapidKey: vapidKey,
          maxRetries: webTokenOptions != null ? webTokenOptions!.maxRetries : 3,
          webTokenOptions: webTokenOptions);
    }

    return _tokenCompleter?.future;
  }

  void _getWebToken(
      {String? vapidKey,
      int? maxRetries = 3,
      WebTokenOptions? webTokenOptions}) async {
    _tokenCompleter ??= Completer();

    try {
      final token =
          await FirebaseMessaging.instance.getToken(vapidKey: vapidKey);
      if(!_tokenCompleter!.isCompleted) _tokenCompleter!.complete(token);
      webTokenOptions?.onToken?.call(token);
    } catch (e) {
      webTokenOptions?.onError?.call(e.toString());
      if (maxRetries != null && maxRetries <= 0) {
        if(!_tokenCompleter!.isCompleted) _tokenCompleter!.complete(null);
        return;
      }

      await Future.delayed(
          webTokenOptions?.delay ?? const Duration(seconds: 5));
      _getWebToken(
          vapidKey: vapidKey,
          maxRetries: maxRetries != null ? maxRetries - 1 : null,
          webTokenOptions: webTokenOptions);
    }
  }

  @override
  Future<bool> requestNotificationPermission() async {
    try{
      final status = await FirebaseMessaging.instance.requestPermission(
        provisional: true,
      ).timeout(const Duration(seconds: 5));
      return status.authorizationStatus == AuthorizationStatus.authorized
          || status.authorizationStatus == AuthorizationStatus.provisional;
    }
    on TimeoutException catch(e){
      debugPrint('User not allow notification permission: $e');
    }
    catch(e){
      debugPrint('Browser does not support firebase');
    }
    return false;
  }

  @override
  void onFlutterError(FlutterErrorDetails errorDetails) {}

  @override
  void recordError(Object exception, StackTrace stackTrace) {}

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
  }) async {}

  @override
  Future<void> showScheduledNotification(
      {int? id,
      String? title,
      String? body,
      String? bigText,
      String? payload,
        List<int>? bigPicture,
        List<int>? largeIcon,
      bool onGoing = false,
      String? channelId,
      String? channelName,
      required DateTime scheduledDate}) async {}

  @override
  Future<void> cancelNotification(int id) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<LocationWrapper?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      //print(position.toJson());
      return LocationWrapper.fromPosition(position.toJson());
    } on TimeoutException catch (e) {
      return LocationWrapper.timeoutException(e.toString());
    } on LocationServiceDisabledException catch (e) {
      return LocationWrapper.locationServiceDisabled(e.toString());
    }
  }
}
