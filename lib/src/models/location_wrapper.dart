class LocationWrapper {
  /// Constructs an instance with the given values for testing. [LocationWrapper]
  /// instances constructed this way won't actually reflect any real information
  /// from the platform, just whatever was passed in at construction time.
  const LocationWrapper({
    required this.longitude,
    required this.latitude,
    required this.timestamp,
    required this.accuracy,
    required this.altitude,
    required this.altitudeAccuracy,
    required this.heading,
    required this.headingAccuracy,
    required this.speed,
    required this.speedAccuracy,
    this.floor,
    this.isMocked = false,
    this.provider,
    this.exception,
  });

  /// The latitude of this position in degrees normalized to the interval -90.0
  /// to +90.0 (both inclusive).
  final double latitude;

  /// The longitude of the position in degrees normalized to the interval -180
  /// (exclusive) to +180 (inclusive).
  final double longitude;

  /// The time at which this position was determined.
  final DateTime timestamp;

  /// The altitude of the device in meters.
  ///
  /// The altitude is not available on all devices. In these cases the returned
  /// value is 0.0.
  final double altitude;

  /// The estimated vertical accuracy of the position in meters.
  ///
  /// The accuracy is not available on all devices. In these cases the value is
  /// 0.0.
  final double altitudeAccuracy;

  /// The estimated horizontal accuracy of the position in meters.
  ///
  /// The accuracy is not available on all devices. In these cases the value is
  /// 0.0.
  final double accuracy;

  /// The heading in which the device is traveling in degrees.
  ///
  /// The heading is not available on all devices. In these cases the value is
  /// 0.0.
  final double heading;

  /// The estimated heading accuracy of the position in degrees.
  ///
  /// The heading accuracy is not available on all devices. In these cases the
  /// value is 0.0.
  final double headingAccuracy;

  /// The floor specifies the floor of the building on which the device is
  /// located.
  ///
  /// The floor property is only available on iOS and only when the information
  /// is available. In all other cases this value will be null.
  final int? floor;

  /// The speed at which the devices is traveling in meters per second over
  /// ground.
  ///
  /// The speed is not available on all devices. In these cases the value is
  /// 0.0.
  final double speed;

  /// The estimated speed accuracy of this position, in meters per second.
  ///
  /// The speedAccuracy is not available on all devices. In these cases the
  /// value is 0.0.
  final double speedAccuracy;

  /// Will be true on Android (starting from API lvl 18) when the location came
  /// from the mocked provider.
  ///
  /// On iOS this value will always be false.
  final bool isMocked;

  final String? provider;
  final LocationException? exception;
  bool get isException => exception != null;

  @override
  bool operator ==(Object other) {
    var areEqual = other is LocationWrapper &&
        other.accuracy == accuracy &&
        other.altitude == altitude &&
        other.altitudeAccuracy == altitudeAccuracy &&
        other.heading == heading &&
        other.headingAccuracy == headingAccuracy &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.floor == floor &&
        other.speed == speed &&
        other.speedAccuracy == speedAccuracy &&
        other.timestamp == timestamp &&
        other.isMocked == isMocked &&
        other.provider == provider;

    return areEqual;
  }

  @override
  int get hashCode =>
      accuracy.hashCode ^
      altitude.hashCode ^
      altitudeAccuracy.hashCode ^
      heading.hashCode ^
      headingAccuracy.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      floor.hashCode ^
      speed.hashCode ^
      speedAccuracy.hashCode ^
      timestamp.hashCode ^
      isMocked.hashCode ^
      provider.hashCode ^
      exception.hashCode;

  @override
  String toString() {
    return 'Latitude: $latitude, Longitude: $longitude';
  }

  ///Convert from Geolocator Position to location wrapper
  factory LocationWrapper.fromPosition(Map<String, dynamic> json){

    if (!json.containsKey('latitude')) {
      throw ArgumentError.value(json, 'json',
          'The supplied map doesn\'t contain the mandatory key `latitude`.');
    }

    if (!json.containsKey('longitude')) {
      throw ArgumentError.value(json, 'json',
          'The supplied map doesn\'t contain the mandatory key `longitude`.');
    }

    // Assume that the timestamp is null if the map does not contain one
    dynamic timestampInMap = json['timestamp'];
    final timestamp = timestampInMap == null
        ? DateTime.now()
        : DateTime.fromMillisecondsSinceEpoch(
      timestampInMap.toInt(),
      isUtc: true,
    );

    return LocationWrapper(
      //provider: json['provider'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      timestamp: timestamp,
      altitude: json['altitude'] ?? 0.0,
      altitudeAccuracy: json['altitude_accuracy'] ?? 0.0,
      accuracy: json['accuracy'] ?? 0.0,
      heading: json['heading'] ?? 0.0,
      headingAccuracy: json['heading_accuracy'] ?? 0.0,
      floor: json['floor'],
      speed: json['speed'] ?? 0.0,
      speedAccuracy: json['speed_accuracy'] ?? 0.0,
      isMocked: json['is_mocked'] ?? false,
    );
  }

  ///Convert from Huawei Location to location wrapper
  factory LocationWrapper.fromLocation(Map<String, dynamic> json){

    if (!json.containsKey('latitude')) {
      throw ArgumentError.value(json, 'json',
          'The supplied map doesn\'t contain the mandatory key `latitude`.');
    }

    if (!json.containsKey('longitude')) {
      throw ArgumentError.value(json, 'json',
          'The supplied map doesn\'t contain the mandatory key `longitude`.');
    }

    // Assume that the timestamp is null if the map does not contain one
    dynamic timestampInMap = json['time'];
    final timestamp = timestampInMap == null
        ? DateTime.now()
        : DateTime.fromMillisecondsSinceEpoch(
      timestampInMap.toInt(),
      isUtc: true,
    );

    return LocationWrapper(
      provider: json['provider'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      timestamp: timestamp,
      altitude: json['altitude'] ?? 0.0,
      altitudeAccuracy: json['verticalAccuracyMeters'] ?? 0.0,
      accuracy: json['horizontalAccuracyMeters'] ?? 0.0,
      heading: json['bearing'] ?? 0.0,
      headingAccuracy: json['bearingAccuracyDegrees'] ?? 0.0,
      floor: json['floor'],
      speed: json['speed'] ?? 0.0,
      speedAccuracy: json['speedAccuracyMetersPerSecond'] ?? 0.0,
      isMocked: json['is_mocked'] ?? false,
    );
  }

  factory LocationWrapper.timeoutException([String? message]) => LocationWrapper.fromException(
    LocationException.timeout(message),
  );

  factory LocationWrapper.permissionPermanentlyDenied([String? message]) => LocationWrapper.fromException(
    LocationException.permissionPermanentlyDenied(message),
  );

  factory LocationWrapper.locationServiceDisabled([String? message]) => LocationWrapper.fromException(
    LocationException.locationServiceDisabled(message),
  );

  factory LocationWrapper.unknownException([String? message]) => LocationWrapper.fromException(
    LocationException.unknownException(message),
  );

  factory LocationWrapper.fromException(LocationException exception) => LocationWrapper(
    exception: exception,
    longitude: 0,
    latitude: 0,
    timestamp: DateTime.now(),
    accuracy: 0,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
    isMocked: false,
  );

  factory LocationWrapper.fromJson(Map<String, dynamic> json) => LocationWrapper(
    provider: json['provider'],
      longitude: json['longitude'] ?? 0,
      latitude: json['latitude'] ?? 0,
      timestamp: json['timestamp'] != null ? DateTime.fromMillisecondsSinceEpoch(json['timestamp']) : DateTime.now(),
      accuracy: json['accuracy'] ?? 0,
      altitude: json['altitude'] ?? 0,
      altitudeAccuracy: json['altitude_accuracy'] ?? 0,
      heading: json['heading'] ?? 0,
      headingAccuracy: json['heading_accuracy'] ?? 0,
      speed: json['speed'] ?? 0,
      speedAccuracy: json['speed_accuracy'] ?? 0,
    floor: json['floor'],
    isMocked: json['is_mocked'] ?? false,
  );

  /// Converts the [LocationWrapper] instance into a [Map] instance that can be
  /// serialized to JSON.
  Map<String, dynamic> toJson() => {
    'provider': provider,
    'longitude': longitude,
    'latitude': latitude,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'accuracy': accuracy,
    'altitude': altitude,
    'altitude_accuracy': altitudeAccuracy,
    'floor': floor,
    'heading': heading,
    'heading_accuracy': headingAccuracy,
    'speed': speed,
    'speed_accuracy': speedAccuracy,
    'is_mocked': isMocked,
  };
}

enum LocationExceptionType{
  permissionPermanentlyDenied,
  timeout,
  locationServiceDisabled,
  unknown;
}

class LocationException implements Exception{
  final LocationExceptionType type;
  final String? message;
  LocationException(this.type, [this.message]);

  factory LocationException.permissionPermanentlyDenied([String? message]) => LocationException(LocationExceptionType.permissionPermanentlyDenied, message);
  factory LocationException.timeout([String? message]) => LocationException(LocationExceptionType.timeout, message);
  factory LocationException.locationServiceDisabled([String? message]) => LocationException(LocationExceptionType.locationServiceDisabled, message);
  factory LocationException.unknownException([String? message]) => LocationException(LocationExceptionType.unknown, message);
}