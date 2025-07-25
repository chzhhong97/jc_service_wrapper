import 'package:flutter/foundation.dart'
    show immutable, objectRuntimeType, visibleForTesting;
import 'package:google_maps_flutter/google_maps_flutter.dart' as g show LatLng, LatLngBounds;
import 'package:huawei_map/huawei_map.dart' as h show LatLng, LatLngBounds;
import 'dart:math' as math;

/// A pair of latitude and longitude coordinates, stored as degrees.
@immutable
class LatLng {
  /// Creates a geographical location specified in degrees [latitude] and
  /// [longitude].
  ///
  /// The latitude is clamped to the inclusive interval from -90.0 to +90.0.
  ///
  /// The longitude is normalized to the half-open interval from -180.0
  /// (inclusive) to +180.0 (exclusive).
  const LatLng(double latitude, double longitude)
      : latitude =
  latitude < -90.0 ? -90.0 : (90.0 < latitude ? 90.0 : latitude),
  // Avoids normalization if possible to prevent unnecessary loss of precision
        longitude = longitude >= -180 && longitude < 180
            ? longitude
            : (longitude + 180.0) % 360.0 - 180.0;

  /// The latitude in degrees between -90.0 and 90.0, both inclusive.
  final double latitude;

  /// The longitude in degrees between -180.0 (inclusive) and 180.0 (exclusive).
  final double longitude;

  /// Converts this object to something serializable in JSON.
  Object toJson() {
    return <double>[latitude, longitude];
  }

  /// Initialize a LatLng from an \[lat, lng\] array.
  static LatLng? fromJson(Object? json) {
    if (json == null) {
      return null;
    }
    assert(json is List && json.length == 2);
    final List<Object?> list = json as List<Object?>;
    return LatLng(list[0]! as double, list[1]! as double);
  }

  static LatLng get zero => const LatLng(0.0, 0.0);
  @override
  String toString() =>
      '${objectRuntimeType(this, 'LatLng')}($latitude, $longitude)';

  @override
  bool operator ==(Object other) {
    return other is LatLng &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude);

  factory LatLng.fromGoogle(g.LatLng latLng){
    return LatLng(latLng.latitude, latLng.longitude);
  }

  factory LatLng.fromHuawei(h.LatLng latLng){
    return LatLng(latLng.lat, latLng.lng);
  }

  g.LatLng toGoogle(){
    return g.LatLng(
      latitude,
      longitude
    );
  }

  h.LatLng toHuawei(){
    return h.LatLng(
      latitude,
      longitude,
    );
  }

  LatLng toPrecision(int n) => LatLng(
      double.parse(latitude.toStringAsFixed(n)),
    double.parse(longitude.toStringAsFixed(n)),
  );

  double distanceBetween(LatLng other){
    var p = 0.017453292519943295;
    var c = math.cos;
    var a = 0.5 - c((other.latitude - latitude) * p)/2 +
        c(latitude * p) * c(other.latitude * p) *
            (1 - c((other.longitude - longitude) * p))/2;
    return 12742 * math.asin(math.sqrt(a));
  }
}

/// A latitude/longitude aligned rectangle.
///
/// The rectangle conceptually includes all points (lat, lng) where
/// * lat ∈ [`southwest.latitude`, `northeast.latitude`]
/// * lng ∈ [`southwest.longitude`, `northeast.longitude`],
///   if `southwest.longitude` ≤ `northeast.longitude`,
/// * lng ∈ [-180, `northeast.longitude`] ∪ [`southwest.longitude`, 180],
///   if `northeast.longitude` < `southwest.longitude`
@immutable
class LatLngBounds {
  /// Creates geographical bounding box with the specified corners.
  ///
  /// The latitude of the southwest corner cannot be larger than the
  /// latitude of the northeast corner.
  LatLngBounds({required this.southwest, required this.northeast})
      : assert(southwest.latitude <= northeast.latitude);

  /// The southwest corner of the rectangle.
  final LatLng southwest;

  /// The northeast corner of the rectangle.
  final LatLng northeast;

  /// Converts this object to something serializable in JSON.
  Object toJson() {
    return <Object>[southwest.toJson(), northeast.toJson()];
  }

  /// Returns whether this rectangle contains the given [LatLng].
  bool contains(LatLng point) {
    return _containsLatitude(point.latitude) &&
        _containsLongitude(point.longitude);
  }

  bool _containsLatitude(double lat) {
    return (southwest.latitude <= lat) && (lat <= northeast.latitude);
  }

  bool _containsLongitude(double lng) {
    if (southwest.longitude <= northeast.longitude) {
      return southwest.longitude <= lng && lng <= northeast.longitude;
    } else {
      return southwest.longitude <= lng || lng <= northeast.longitude;
    }
  }

  /// Converts a list to [LatLngBounds].
  @visibleForTesting
  static LatLngBounds? fromList(Object? json) {
    if (json == null) {
      return null;
    }
    assert(json is List && json.length == 2);
    final List<Object?> list = json as List<Object?>;
    return LatLngBounds(
      southwest: LatLng.fromJson(list[0])!,
      northeast: LatLng.fromJson(list[1])!,
    );
  }

  @override
  String toString() {
    return '${objectRuntimeType(this, 'LatLngBounds')}($southwest, $northeast)';
  }

  @override
  bool operator ==(Object other) {
    return other is LatLngBounds &&
        other.southwest == southwest &&
        other.northeast == northeast;
  }

  @override
  int get hashCode => Object.hash(southwest, northeast);

  g.LatLngBounds toGoogle(){
    return g.LatLngBounds(
      southwest: southwest.toGoogle(),
      northeast: northeast.toGoogle(),
    );
  }

  h.LatLngBounds toHuawei(){
    return h.LatLngBounds(
      southwest: southwest.toHuawei(),
      northeast: northeast.toHuawei(),
    );
  }
}
