import 'package:firebase_messaging/firebase_messaging.dart' as fm;
import 'package:jc_service_wrapper/src/models/types.dart';

/// A class representing a notification which has been construted and sent to the
/// device via FCM.
///
/// This class can be accessed via a [RemoteMessage.notification].
class RemoteNotificationWrapper {
  // ignore: public_member_api_docs
  const RemoteNotificationWrapper({
    this.android,
    this.apple,
    this.title,
    this.titleLocArgs = const <String>[],
    this.titleLocKey,
    this.body,
    this.bodyLocArgs = const <String>[],
    this.bodyLocKey,
  });

  factory RemoteNotificationWrapper.fromFirebase(Map<String, dynamic> json) {
    return RemoteNotificationWrapper(
      title: json['title'],
      titleLocArgs: _toList(json['titleLocArgs']),
      titleLocKey: json['titleLocKey'],
      body: json['body'],
      bodyLocArgs: _toList(json['bodyLocArgs']),
      bodyLocKey: json['bodyLocKey'],
      android: json['android'] != null
          ? AndroidNotification.fromFirebase(
          Map<String, dynamic>.from(json['android']))
          : null,
      apple: json['apple'] != null
          ? AppleNotification.fromFirebase(Map<String, dynamic>.from(json['apple']))
          : null,
    );
  }

  fm.RemoteNotification toFirebase() {
    return fm.RemoteNotification(
      title: title,
      titleLocArgs: titleLocArgs,
      body: body,
      bodyLocArgs: bodyLocArgs,
      bodyLocKey: bodyLocKey,
      android: android?.toFirebase(),
      apple: apple?.toFirebase(),
    );
  }

  factory RemoteNotificationWrapper.fromHuawei(Map<String, dynamic> json) {
    return RemoteNotificationWrapper(
      title: json['title'],
      titleLocArgs: _toList(json['titleLocalizationArgs']),
      titleLocKey: json['titleLocalizationKey'],
      body: json['body'],
      bodyLocArgs: _toList(json['bodyLocalizationArgs']),
      bodyLocKey: json['bodyLocalizationKey'],
      android: AndroidNotification.fromHuawei(json),
    );
  }

  factory RemoteNotificationWrapper.fromJson(Map<String, dynamic> json) {
    return RemoteNotificationWrapper(
      title: json['title'],
      titleLocArgs: _toList(json['titleLocArgs']),
      titleLocKey: json['titleLocKey'],
      body: json['body'],
      bodyLocArgs: _toList(json['bodyLocArgs']),
      bodyLocKey: json['bodyLocKey'],
      android: json['android'] != null ? AndroidNotification.fromJson(json['android'] as Map<String, dynamic>) : null,
      apple: json['apple'] != null ? AppleNotification.fromFirebase(json['apple'] as Map<String, dynamic>) : null,
    );
  }

  /// Returns the [RemoteNotification] as a raw Map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'titleLocArgs': titleLocArgs,
      'titleLocKey': titleLocKey,
      'body': body,
      'bodyLocArgs': bodyLocArgs,
      'bodyLocKey': bodyLocKey,
      'android': android?.toJson(),
      'apple': apple?.toJson(),
    };
  }

  /// Android specific notification properties.
  final AndroidNotification? android;

  /// Apple specific notification properties.
  final AppleNotification? apple;

  /// The notification title.
  final String? title;

  /// Any arguments that should be formatted into the resource specified by titleLocKey.
  final List<String> titleLocArgs;

  /// The native localization key for the notification title.
  final String? titleLocKey;

  /// The notification body content.
  final String? body;

  /// Any arguments that should be formatted into the resource specified by bodyLocKey.
  final List<String> bodyLocArgs;

  /// The native localization key for the notification body content.
  final String? bodyLocKey;
}

/// Android specific properties of a [RemoteNotification].
///
/// This will only be populated if the current device is Android.
class AndroidNotification {
  // ignore: public_member_api_docs
  const AndroidNotification({
    this.channelId,
    this.clickAction,
    this.color,
    this.count,
    this.imageUrl,
    this.link,
    this.priority = AndroidNotificationPriority.defaultPriority,
    this.smallIcon,
    this.sound,
    this.ticker,
    this.tag,
    this.visibility = AndroidNotificationVisibility.private,
  });

  factory AndroidNotification.fromFirebase(Map<String, dynamic> json) {
    return AndroidNotification(
      channelId: json['channelId'],
      clickAction: json['clickAction'],
      color: json['color'],
      count: json['count'],
      imageUrl: json['imageUrl'],
      link: json['link'],
      priority: convertToAndroidNotificationPriority(json['priority']),
      smallIcon: json['smallIcon'],
      sound: json['sound'],
      ticker: json['ticker'],
      tag: json['tag'],
      visibility: convertToAndroidNotificationVisibility(json['visibility']),
    );
  }

  fm.AndroidNotification toFirebase() {
    return fm.AndroidNotification(
      channelId: channelId,
      clickAction: clickAction,
      color: color,
      count: count,
      imageUrl: imageUrl,
      link: link,
      priority: priority.toFirebase(),
      smallIcon: smallIcon,
      sound: sound,
      ticker: ticker,
      tag: tag,
      visibility: visibility.toFirebase(),
    );
  }

  factory AndroidNotification.fromHuawei(Map<String, dynamic> json) {
    return AndroidNotification(
      channelId: json['ChannelId'],
      clickAction: json['ClickAction'],
      color: json['Color'],
      count: json['BadgeNumber'],
      imageUrl: dynamicUrl(json['ImageUrl']),
      link: dynamicUrl(json['Link']),
      priority: convertToAndroidNotificationPriority(json['Importance']),
      smallIcon: json['icon'],
      sound: json['Sound'],
      ticker: json['Ticker'],
      tag: json['Tag'],
      visibility: convertToAndroidNotificationVisibility(json['visibility']),
    );
  }

  static String? dynamicUrl(dynamic url){
    if(url is String) return url;
    if(url is Uri) return url.toString();
    return null;
  }

  factory AndroidNotification.fromJson(Map<String, dynamic> json) {
    return AndroidNotification(
      channelId: json['channelId'],
      clickAction: json['clickAction'],
      color: json['color'],
      count: json['count'],
      imageUrl: json['imageUrl'],
      link: json['link'],
      priority: convertToAndroidNotificationPriority(json['priority']),
      smallIcon: json['smallIcon'],
      sound: json['sound'],
      ticker: json['ticker'],
      tag: json['tag'],
      visibility: convertToAndroidNotificationVisibility(json['visibility']),
    );
  }

  /// Returns the [AndroidNotification] as a raw Map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'channelId': channelId,
      'clickAction': clickAction,
      'color': color,
      'count': count,
      'imageUrl': imageUrl,
      'link': link,
      'priority': convertAndroidNotificationPriorityToInt(priority),
      'smallIcon': smallIcon,
      'sound': sound,
      'ticker': ticker,
      'tag': tag,
      'visibility': convertAndroidNotificationVisibilityToInt(visibility),
    };
  }

  /// The channel the notification is delivered on.
  final String? channelId;

  /// A spcific click action was defined for the notification.
  ///
  /// This property is not required to handle user interaction.
  final String? clickAction;

  /// The color of the notification.
  final String? color;

  /// The current notification count for the application.
  final int? count;

  /// The image URL for the notification.
  ///
  /// Will be `null` if the notification did not include an image.
  final String? imageUrl;

  // ignore: public_member_api_docs
  final String? link;

  /// The priority for the notifcation.
  ///
  /// This property only has impact on devices running Android 8.0 (API level 26) +.
  /// Later than this, they use the channel importance instead.
  final AndroidNotificationPriority priority;

  /// The resource file name of the small icon shown in the notification.
  final String? smallIcon;

  /// The resource file name of the sound used to alert users to the incoming notification.
  final String? sound;

  /// Ticker text for the notification, used for accessibility purposes.
  final String? ticker;

  /// The visibility level of the notification.
  final AndroidNotificationVisibility visibility;

  /// The tag of the notification.
  final String? tag;
}

/// Apple specific properties of a [RemoteNotification].
///
/// This will only be populated if the current device is Apple based (iOS/MacOS).
class AppleNotification {
  // ignore: public_member_api_docs
  const AppleNotification({
    this.badge,
    this.sound,
    this.imageUrl,
    this.subtitle,
    this.subtitleLocArgs = const <String>[],
    this.subtitleLocKey,
  });

  factory AppleNotification.fromFirebase(Map<String, dynamic> json) {
    return AppleNotification(
      badge: json['badge'],
      subtitle: json['subtitle'],
      subtitleLocArgs: _toList(json['subtitleLocArgs']),
      subtitleLocKey: json['subtitleLocKey'],
      imageUrl: json['imageUrl'],
      sound: json['sound'] == null
          ? null
          : AppleNotificationSound.fromFirebase(
          Map<String, dynamic>.from(json['sound'])),
    );
  }

  fm.AppleNotification toFirebase(){
    return fm.AppleNotification(
      badge: badge,
      subtitle: subtitle,
      subtitleLocArgs: subtitleLocArgs,
      subtitleLocKey: subtitleLocKey,
      imageUrl: imageUrl,
      sound: sound?.toFirebase(),
    );
  }

  /// Returns the [AppleNotification] as a raw Map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'badge': badge,
      'subtitle': subtitle,
      'subtitleLocArgs': subtitleLocArgs,
      'subtitleLocKey': subtitleLocKey,
      'imageUrl': imageUrl,
      'sound': sound?.toJson(),
    };
  }

  /// The value which sets the application badge.
  final String? badge;

  /// Sound values for the incoming notification.
  final AppleNotificationSound? sound;

  /// The image URL for the notification.
  ///
  /// Will be `null` if the notification did not include an image.
  final String? imageUrl;

  /// Any subtile text on the notification.
  final String? subtitle;

  /// Any arguments that should be formatted into the resource specified by subtitleLocKey.
  final List<String> subtitleLocArgs;

  /// The native localization key for the notification subtitle.
  final String? subtitleLocKey;
}

/// Represents the sound property for [AppleNotification]
class AppleNotificationSound {
  // ignore: public_member_api_docs
  const AppleNotificationSound({
    this.critical = false,
    this.name,
    this.volume = 0,
  });

  /// Constructs an [AppleNotificationSound] from a raw Map.
  factory AppleNotificationSound.fromFirebase(Map<String, dynamic> json) {
    return AppleNotificationSound(
      critical: json['critical'] ?? false,
      name: json['name'],
      volume: json['volume'] ?? 0,
    );
  }

  fm.AppleNotificationSound toFirebase(){
    return fm.AppleNotificationSound(
      critical: critical,
      name: name,
      volume: volume,
    );
  }

  /// Returns the [AppleNotificationSound] as a raw Map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'critical': critical,
      'name': name,
      'volume': volume,
    };
  }

  /// Whether or not the notification sound was critical.
  final bool critical;

  /// The resource name of the sound played.
  final String? name;

  /// The volume of the sound.
  ///
  /// This value is a number between 0.0 & 1.0.
  final num volume;
}

// Utility to correctly cast lists
List<String> _toList(dynamic value) {
  if (value == null) {
    return <String>[];
  }

  return List<String>.from(value);
}

/// Web specific properties of a [RemoteNotification].
class WebNotification {
  const WebNotification({
    this.analyticsLabel,
    this.image,
    this.link,
  });

  /// Constructs a [WebNotification] from a raw Map.
  factory WebNotification.fromMap(Map<String, dynamic> map) {
    return WebNotification(
      analyticsLabel: map['analyticsLabel'],
      image: map['image'],
      link: map['link'],
    );
  }

  /// Returns the [WebNotification] as a raw Map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'analyticsLabel': analyticsLabel,
      'image': image,
      'link': link,
    };
  }

  /// Optional message label for custom analytics.
  final String? analyticsLabel;

  /// The image URL for the notification.
  ///
  /// Will be `null` if the notification did not include an image.
  final String? image;

  /// The url which is typically being navigated to when the notification is clicked.
  final String? link;
}
