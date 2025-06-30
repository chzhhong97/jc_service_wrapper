import 'package:firebase_messaging/firebase_messaging.dart' as fm;

enum AndroidNotificationPriority {
  /// The application small icon will not show up in the status bar, or alert the user. The notification
  /// will be in a collapsed state in the notification shade and placed at the bottom of the list.
  minimumPriority,

  /// The application small icon will show in the device status bar, however the notification will
  /// not alert the user (no sound or vibration). The notification will show in it's expanded state
  /// when the notification shade is pulled down.
  lowPriority,

  /// When a notification is received, the device smallIcon will appear in the notification shade.
  /// When the user pulls down the notification shade, the content of the notification will be shown
  /// in it's expanded state.
  defaultPriority,

  /// Notifications will appear on-top of applications, allowing direct interaction without pulling
  /// own the notification shade. This level is used for urgent notifications, such as
  /// incoming phone calls, messages etc, which require immediate attention.
  highPriority,

  /// The highest priority level a notification can be set to.
  maximumPriority;

  fm.AndroidNotificationPriority toFirebase() {
    switch (this) {
      case minimumPriority:
        return fm.AndroidNotificationPriority.minimumPriority;
      case lowPriority:
        return fm.AndroidNotificationPriority.lowPriority;
      case defaultPriority:
        return fm.AndroidNotificationPriority.defaultPriority;
      case highPriority:
        return fm.AndroidNotificationPriority.highPriority;
      case maximumPriority:
        return fm.AndroidNotificationPriority.maximumPriority;
      default:
        return fm.AndroidNotificationPriority.defaultPriority;
    }
  }

  static AndroidNotificationPriority fromName(String name){
    for(final i in AndroidNotificationPriority.values){
      if(i.name.toLowerCase() == name.toLowerCase()) return i;
    }

    return AndroidNotificationPriority.defaultPriority;
  }
}

/// An enum representing the visibility level of a notification on Android.
enum AndroidNotificationVisibility {
  /// Do not reveal any part of this notification on a secure lock-screen.
  secret,

  /// Show this notification on all lock-screens, but conceal sensitive or private information on secure lock-screens.
  private,

  /// Show this notification in its entirety on all lock-screens.
  public;

  fm.AndroidNotificationVisibility toFirebase() {
    switch (this) {
      case secret:
        return fm.AndroidNotificationVisibility.secret;
      case private:
        return fm.AndroidNotificationVisibility.private;
      case public:
        return fm.AndroidNotificationVisibility.public;
      default:
        return fm.AndroidNotificationVisibility.private;
    }
  }

  static AndroidNotificationVisibility fromName(String name){
    for(final i in AndroidNotificationVisibility.values){
      if(i.name.toLowerCase() == name.toLowerCase()) return i;
    }

    return AndroidNotificationVisibility.private;
  }
}

/// Converts an [int] into it's [AndroidNotificationPriority] representation.
AndroidNotificationPriority convertToAndroidNotificationPriority(
    int? priority) {
  switch (priority) {
    case -2:
      return AndroidNotificationPriority.minimumPriority;
    case -1:
      return AndroidNotificationPriority.lowPriority;
    case 0:
      return AndroidNotificationPriority.defaultPriority;
    case 1:
      return AndroidNotificationPriority.highPriority;
    case 2:
      return AndroidNotificationPriority.maximumPriority;
    default:
      return AndroidNotificationPriority.defaultPriority;
  }
}

/// Converts an [AndroidNotificationPriority] into it's [int] representation.
int convertAndroidNotificationPriorityToInt(
    AndroidNotificationPriority? priority) {
  switch (priority) {
    case AndroidNotificationPriority.minimumPriority:
      return -2;
    case AndroidNotificationPriority.lowPriority:
      return -1;
    case AndroidNotificationPriority.defaultPriority:
      return 0;
    case AndroidNotificationPriority.highPriority:
      return 1;
    case AndroidNotificationPriority.maximumPriority:
      return 2;
    default:
      return 0;
  }
}

/// Converts an [int] into it's [AndroidNotificationVisibility] representation.
AndroidNotificationVisibility convertToAndroidNotificationVisibility(
    int? visibility) {
  switch (visibility) {
    case -1:
      return AndroidNotificationVisibility.secret;
    case 0:
      return AndroidNotificationVisibility.private;
    case 1:
      return AndroidNotificationVisibility.public;
    default:
      return AndroidNotificationVisibility.private;
  }
}

/// Converts an [AndroidNotificationVisibility] into it's [int] representation.
int convertAndroidNotificationVisibilityToInt(
    AndroidNotificationVisibility? visibility) {
  switch (visibility) {
    case AndroidNotificationVisibility.secret:
      return -1;
    case AndroidNotificationVisibility.private:
      return 0;
    case AndroidNotificationVisibility.public:
      return 1;
    default:
      return 0;
  }
}