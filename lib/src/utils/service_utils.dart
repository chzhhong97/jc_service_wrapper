import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jc_service_wrapper/src/models/remote_message_wrapper.dart';
import 'package:jc_service_wrapper/src/service_wrapper.dart';

mixin ServiceRemoteMessageMixin<T extends StatefulWidget> on State<T> {
  late StreamSubscription<RemoteMessageWrapper>? _onMessageReceived;
  late StreamSubscription<RemoteMessageWrapper>? _onMessageOpened;

  @override
  void initState() {
    _onMessageReceived = ServiceWrapper().onMessage(_onNewNotify);
    _onMessageOpened = ServiceWrapper().onMessageOpened(_onNewOpened);
    super.initState();
  }

  @override
  void dispose() {
    _onMessageReceived?.cancel();
    _onMessageOpened?.cancel();
    super.dispose();
  }

  bool get notifyOnReceived => true;
  bool get notifyOnOpened => true;

  /// Will be called whenever a new notification come and app is in foreground
  Future<void> onNotify(RemoteMessageWrapper notification);

  void onOpened(RemoteMessageWrapper notification);

  void _onNewNotify(RemoteMessageWrapper notification) {
    if (mounted && notifyOnReceived) onNotify(notification);
  }

  void _onNewOpened(RemoteMessageWrapper notification) {
    if (mounted && notifyOnOpened) onOpened(notification);
  }
}

class WebTokenOptions{
  final int? maxRetries;
  final Duration delay;
  final Function(String? token)? onToken;
  final Function(String error)? onError;

  WebTokenOptions({
    this.maxRetries = 3,
    this.delay = const Duration(seconds: 5),
    this.onToken,
    this.onError,
  });
}