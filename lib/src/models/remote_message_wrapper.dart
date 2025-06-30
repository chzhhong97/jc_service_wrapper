import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart' as fm;
import 'package:jc_service_wrapper/src/models/remote_notification_wrapper.dart';
import 'package:jc_service_wrapper/src/service_wrapper.dart';

class RemoteMessageWrapper {
  final String serviceType;
  ServiceType get serviceTypeEnum => ServiceType.fromName(serviceType);
  
  /// The ID of the upstream sender location.
  final String? senderId;

  /// The iOS category this notification is assigned to.
  final String? category;

  /// The collapse key a message was sent with. Used to override existing messages with the same key.
  final String? collapseKey;

  /// Whether the iOS APNs message was configured as a background update notification.
  final bool contentAvailable;

  /// Any additional data sent with the message.
  final Map<String, dynamic> data;

  /// The topic name or message identifier.
  final String? from;

  /// A unique ID assigned to every message.
  final String? messageId;

  /// The message type of the message.
  final String? messageType;

  /// Whether the iOS APNs `mutable-content` property on the message was set
  /// allowing the app to modify the notification via app extensions.
  final bool mutableContent;

  /// Additional Notification data sent with the message.
  final RemoteNotificationWrapper? notification;

  /// The time the message was sent, represented as a [DateTime].
  final DateTime? sentTime;

  /// An iOS app specific identifier used for notification grouping.
  final String? threadId;

  /// The time to live for the message in seconds.
  final int? ttl;
  final Map<String, dynamic>? rawData;

  const RemoteMessageWrapper({
    this.serviceType = 'NONE',
    this.senderId,
    this.category,
    this.collapseKey,
    this.contentAvailable = false,
    this.data = const <String, dynamic>{},
    this.from,
    this.messageId,
    this.messageType,
    this.mutableContent = false,
    this.notification,
    this.sentTime,
    this.threadId,
    this.ttl,
    this.rawData,
  });
  
  factory RemoteMessageWrapper.fromFirebaseMessage(Map<String, dynamic> json){
    return RemoteMessageWrapper(
      serviceType: ServiceType.GMS.name,
      senderId: json['senderId'],
      category: json['category'],
      collapseKey: json['collapseKey'],
      contentAvailable: json['contentAvailable'] ?? false,
      data: json['data'] == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(json['data']),
      from: json['from'],
      // Note: using toString on messageId as it can be an int or string when being sent from native.
      messageId: json['messageId']?.toString(),
      messageType: json['messageType'],
      mutableContent: json['mutableContent'] ?? false,
      notification: json['notification'] == null
          ? null
          : RemoteNotificationWrapper.fromFirebase(Map<String, dynamic>.from(json['notification'])),
      // Note: using toString on sentTime as it can be an int or string when being sent from native.
      sentTime: json['sentTime'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
          int.parse(json['sentTime'].toString())),
      threadId: json['threadId'],
      ttl: json['ttl'],
      rawData: json
    );
  }

  fm.RemoteMessage toFirebaseMessage() {
    return fm.RemoteMessage(
      senderId: senderId,
      category: category,
      collapseKey: collapseKey,
      contentAvailable: contentAvailable,
      data: data,
      from: from,
      messageId: messageId,
      messageType: messageId,
      mutableContent: mutableContent,
      notification: notification?.toFirebase(),
      sentTime: sentTime,threadId: threadId,
      ttl: ttl,
    );
  }

  factory RemoteMessageWrapper.fromHuaweiPush(Map<String, dynamic> json){
    final notification = json['notification'] == null
        ? null
        : Map<String, dynamic>.from(json['notification']);
    if(notification != null){
      for(final key in notification.keys){
        if(notification[key] is Uri){
          notification[key] = notification[key].toString();
        }
      }
      json['notification'] = notification;
    }

    return RemoteMessageWrapper(
      //senderId: json['from'],
      serviceType: ServiceType.HMS.name,
      category: json['category'],
      collapseKey: json['collapseKey'],
      contentAvailable: json['contentAvailable'] ?? false,
      data: dynamicData(json['dataOfMap']),
      from: json['from'],
      // Note: using toString on messageId as it can be an int or string when being sent from native.
      messageId: json['messageId']?.toString(),
      messageType: json['messageType'],
      mutableContent: json['mutableContent'] ?? false,
      notification: notification == null
          ? null
          : RemoteNotificationWrapper.fromHuawei(notification),
      // Note: using toString on sentTime as it can be an int or string when being sent from native.
      sentTime: json['sentTime'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
          int.parse(json['sentTime'].toString())),
      threadId: json['threadId'],
      ttl: json['ttl'],
      rawData: json
    );
  }

  factory RemoteMessageWrapper.fromJson(Map<String, dynamic> json){
    return RemoteMessageWrapper(
      serviceType: (json['serviceType'] as String?) ?? ServiceType.NONE.name,
      senderId: json['senderId'] as String?,
      category: json['category'] as String?,
      collapseKey: json['collapseKey'] as String?,
      contentAvailable: json['contentAvailable'] as bool? ?? false,
      data: json['data'] == null ? {} : json['data'] as Map<String, dynamic>,
      from: json['from'] as String?,
      messageId: json['messageId'] as String?,
      messageType: json['messageType'] as String?,
      mutableContent: json['mutableContent'] as bool? ?? false,
      notification: json['notification'] == null
          ? null
          : RemoteNotificationWrapper.fromJson(json['notification']),
      sentTime: json['sentTime'] != null ? DateTime.fromMillisecondsSinceEpoch(json['sentTime']) : null,
      threadId: json['threadId'] as String?,
      ttl: json['ttl'] as int?,
      rawData: json
    );
  }

  static Map<String, dynamic> dynamicData(dynamic data){
    if(data is String){
      return Map<String, dynamic>.from(jsonDecode(data));
    }

    if(data is Map){
      return Map<String, dynamic>.from(data);
    }

    return {};
  }

  /// Returns the [RemoteMessage] as a raw Map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'serviceType': serviceType,
      'senderId': senderId,
      'category': category,
      'collapseKey': collapseKey,
      'contentAvailable': contentAvailable,
      'data': data,
      'from': from,
      'messageId': messageId,
      'messageType': messageType,
      'mutableContent': mutableContent,
      'notification': notification?.toJson(),
      'sentTime': sentTime?.millisecondsSinceEpoch,
      'threadId': threadId,
      'ttl': ttl,
      'rawData': rawData,
    };
  }
}