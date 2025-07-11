import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:jc_service_wrapper/src/models/location_wrapper.dart';
import 'package:jc_service_wrapper/src/service_wrapper.dart';

class WebService extends Service{

  @override
  Future<void> initialize(OnBackgroundNotification handler,) async {

  }

  @override
  Future<void> subscribeToTopic(String topic) => Future.value();
  @override
  Future<void> unsubscribeFromTopic(String topic) => Future.value();

  @override
  Future<String?> getToken() => Future.value(null);

  @override
  void onFlutterError(FlutterErrorDetails errorDetails){}

  @override
  void recordError(Object exception, StackTrace stackTrace){}

  @override
  Future<void> showNotification({
    int? id,
    String? title,
    String? body,
    String? bigText,
    String? payload,
    String? icon,
    Color? notificationColor,
    bool onGoing = false,
    String? channelId,
    String? channelName,
  }) async {}

  @override
  Future<void> showScheduledNotification({
    int? id,
    String? title,
    String? body,
    String? bigText,
    String? payload,
    String? icon,
    Color? notificationColor,
    bool onGoing = false,
    String? channelId,
    String? channelName,
    required DateTime scheduledDate
  }) async {}

  @override
  Future<void> cancelNotification(int id) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<LocationWrapper?> getCurrentLocation() async {
    return null;
  }
}
