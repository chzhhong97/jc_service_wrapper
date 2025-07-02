import 'dart:ui' show Offset;
import 'package:google_maps_flutter/google_maps_flutter.dart' as g
    show CameraUpdate, CameraPosition, CameraTargetBounds;
import 'package:huawei_map/huawei_map.dart' as h
    show CameraUpdate, CameraPosition, CameraTargetBounds;

import 'lat_lng.dart';

/// The position of the map "camera", the view point from which the world is shown in the map view.
///
/// Aggregates the camera's [target] geographical location, its [zoom] level,
/// [tilt] angle, and [bearing].
class CameraPosition {
  /// Direction that the camera is pointing in.
  final double bearing;

  /// Longitude and latitude of the location that the camera is pointing at.
  final LatLng target;

  /// Angle of the camera from the nadir (directly facing the Earth's surface).
  final double tilt;

  /// Zoom level near the center of the screen.
  final double zoom;

  /// Creates a [CameraPosition] object.
  const CameraPosition({
    this.bearing = 0.0,
    required this.target,
    this.tilt = 0.0,
    this.zoom = 0.0,
  });

  dynamic toMap() {
    return <String, dynamic>{
      'bearing': bearing,
      'target': target.toJson(),
      'tilt': tilt,
      'zoom': zoom,
    };
  }

  /// Creates a [CameraPosition] object from a map.
  static CameraPosition? fromMap(Object? json) {
    if (json == null || json is! Map<dynamic, dynamic>) {
      return null;
    }
    final LatLng? target = LatLng.fromJson(json['target']);
    if (target == null) {
      return null;
    }
    return CameraPosition(
      bearing: json['bearing'] as double,
      target: target,
      tilt: json['tilt'] as double,
      zoom: json['zoom'] as double,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (runtimeType != other.runtimeType) {
      return false;
    }
    return other is CameraPosition &&
        bearing == other.bearing &&
        target == other.target &&
        tilt == other.tilt &&
        zoom == other.zoom;
  }

  @override
  int get hashCode => Object.hash(bearing, target, tilt, zoom);

  factory CameraPosition.fromGoogle(g.CameraPosition cameraPosition) {
    return CameraPosition(
      target: LatLng.fromGoogle(cameraPosition.target),
      bearing: cameraPosition.bearing,
      tilt: cameraPosition.tilt,
      zoom: cameraPosition.zoom,
    );
  }

  factory CameraPosition.fromHuawei(h.CameraPosition cameraPosition) {
    return CameraPosition(
      target: LatLng.fromHuawei(cameraPosition.target),
      bearing: cameraPosition.bearing,
      tilt: cameraPosition.tilt,
      zoom: cameraPosition.zoom,
    );
  }

  g.CameraPosition toGoogle() {
    return g.CameraPosition(
      bearing: bearing,
      target: target.toGoogle(),
      tilt: tilt,
      zoom: zoom,
    );
  }

  h.CameraPosition toHuawei() {
    return h.CameraPosition(
      bearing: bearing,
      target: target.toHuawei(),
      tilt: tilt,
      zoom: zoom,
    );
  }
}

/// Defines a camera move, supporting absolute moves as well as moves relative
/// the current position.
abstract class CameraUpdate {
  const CameraUpdate._();

  /// Returns a camera update that moves the camera to the specified position.
  static CameraUpdate newCameraPosition(CameraPosition cameraPosition) {
    return CameraUpdateNewCameraPosition(cameraPosition);
  }

  /// Returns a camera update that moves the camera target to the specified
  /// geographical location.
  static CameraUpdate newLatLng(LatLng latLng) {
    return CameraUpdateNewLatLng(latLng);
  }

  /// Returns a camera update that transforms the camera so that the specified
  /// geographical bounding box is centered in the map view at the greatest
  /// possible zoom level. A non-zero [padding] insets the bounding box from the
  /// map view's edges. The camera's new tilt and bearing will both be 0.0.
  static CameraUpdate newLatLngBounds(LatLngBounds bounds, double padding) {
    return CameraUpdateNewLatLngBounds(bounds, padding);
  }

  /// Returns a camera update that moves the camera target to the specified
  /// geographical location and zoom level.
  static CameraUpdate newLatLngZoom(LatLng latLng, double zoom) {
    return CameraUpdateNewLatLngZoom(latLng, zoom);
  }

  /// Returns a camera update that moves the camera target the specified screen
  /// distance.
  ///
  /// For a camera with bearing 0.0 (pointing north), scrolling by 50,75 moves
  /// the camera's target to a geographical location that is 50 to the east and
  /// 75 to the south of the current location, measured in screen coordinates.
  static CameraUpdate scrollBy(double dx, double dy) {
    return CameraUpdateScrollBy(dx, dy);
  }

  /// Returns a camera update that modifies the camera zoom level by the
  /// specified amount. The optional [focus] is a screen point whose underlying
  /// geographical location should be invariant, if possible, by the movement.
  static CameraUpdate zoomBy(double amount, [Offset? focus]) {
    return CameraUpdateZoomBy(amount, focus);
  }

  /// Returns a camera update that zooms the camera in, bringing the camera
  /// closer to the surface of the Earth.
  ///
  /// Equivalent to the result of calling `zoomBy(1.0)`.
  static CameraUpdate zoomIn() {
    return const CameraUpdateZoomIn();
  }

  /// Returns a camera update that zooms the camera out, bringing the camera
  /// further away from the surface of the Earth.
  ///
  /// Equivalent to the result of calling `zoomBy(-1.0)`.
  static CameraUpdate zoomOut() {
    return const CameraUpdateZoomOut();
  }

  /// Returns a camera update that sets the camera zoom level.
  static CameraUpdate zoomTo(double zoom) {
    return CameraUpdateZoomTo(zoom);
  }

  /// Converts this object to something serializable in JSON.
  Object toJson();

  g.CameraUpdate toGoogle();
  h.CameraUpdate toHuawei();
}

/// Defines a camera move to a new position.
class CameraUpdateNewCameraPosition extends CameraUpdate {
  /// Creates a camera move.
  const CameraUpdateNewCameraPosition(this.cameraPosition) : super._();

  /// The new camera position.
  final CameraPosition cameraPosition;
  @override
  Object toJson() => <Object>['newCameraPosition', cameraPosition.toMap()];

  @override
  g.CameraUpdate toGoogle() {
    return g.CameraUpdate.newCameraPosition(cameraPosition.toGoogle());
  }

  @override
  h.CameraUpdate toHuawei() {
    return h.CameraUpdate.newCameraPosition(cameraPosition.toHuawei());
  }
}

/// Defines a camera move to a latitude and longitude.
class CameraUpdateNewLatLng extends CameraUpdate {
  /// Creates a camera move to latitude and longitude.
  const CameraUpdateNewLatLng(this.latLng) : super._();

  /// New latitude and longitude of the camera..
  final LatLng latLng;
  @override
  Object toJson() => <Object>['newLatLng', latLng.toJson()];

  @override
  g.CameraUpdate toGoogle() {
    return g.CameraUpdate.newLatLng(latLng.toGoogle());
  }

  @override
  h.CameraUpdate toHuawei() {
    return h.CameraUpdate.newLatLng(latLng.toHuawei());
  }
}

/// Defines a camera move to a new bounding latitude and longitude range.
class CameraUpdateNewLatLngBounds extends CameraUpdate {
  /// Creates a camera move to a bounding range.
  const CameraUpdateNewLatLngBounds(this.bounds, this.padding) : super._();

  /// The northeast and southwest bounding coordinates.
  final LatLngBounds bounds;

  /// The amount of padding by which the view is inset.
  final double padding;
  @override
  Object toJson() => <Object>['newLatLngBounds', bounds.toJson(), padding];

  @override
  g.CameraUpdate toGoogle() {
    return g.CameraUpdate.newLatLngBounds(bounds.toGoogle(), padding);
  }

  @override
  h.CameraUpdate toHuawei() {
    return h.CameraUpdate.newLatLngBounds(bounds.toHuawei(), padding);
  }
}

/// Defines a camera move to new coordinates with a zoom level.
class CameraUpdateNewLatLngZoom extends CameraUpdate {
  /// Creates a camera move with coordinates and zoom level.
  const CameraUpdateNewLatLngZoom(this.latLng, this.zoom) : super._();

  /// New coordinates of the camera.
  final LatLng latLng;

  /// New zoom level of the camera.
  final double zoom;
  @override
  Object toJson() => <Object>['newLatLngZoom', latLng.toJson(), zoom];

  @override
  g.CameraUpdate toGoogle() {
    return g.CameraUpdate.newLatLngZoom(latLng.toGoogle(), zoom);
  }

  @override
  h.CameraUpdate toHuawei() {
    return h.CameraUpdate.newLatLngZoom(latLng.toHuawei(), zoom);
  }
}

/// Defines a camera scroll by a certain delta.
class CameraUpdateScrollBy extends CameraUpdate {
  /// Creates a camera scroll.
  const CameraUpdateScrollBy(this.dx, this.dy) : super._();

  /// Scroll delta x.
  final double dx;

  /// Scroll delta y.
  final double dy;
  @override
  Object toJson() => <Object>['scrollBy', dx, dy];

  @override
  g.CameraUpdate toGoogle() {
    return g.CameraUpdate.scrollBy(dx, dy);
  }

  @override
  h.CameraUpdate toHuawei() {
    return h.CameraUpdate.scrollBy(dx, dy);
  }
}

/// Defines a relative camera zoom.
class CameraUpdateZoomBy extends CameraUpdate {
  /// Creates a relative camera zoom.
  const CameraUpdateZoomBy(this.amount, [this.focus]) : super._();

  /// Change in camera zoom amount.
  final double amount;

  /// Optional point around which the zoom is focused.
  final Offset? focus;
  @override
  Object toJson() => (focus == null)
      ? <Object>['zoomBy', amount]
      : <Object>[
          'zoomBy',
          amount,
          <double>[focus!.dx, focus!.dy]
        ];

  @override
  g.CameraUpdate toGoogle() {
    return g.CameraUpdate.zoomBy(amount, focus);
  }

  @override
  h.CameraUpdate toHuawei() {
    return h.CameraUpdate.zoomBy(amount, focus);
  }
}

/// Defines a camera zoom in.
class CameraUpdateZoomIn extends CameraUpdate {
  /// Zooms in the camera.
  const CameraUpdateZoomIn() : super._();
  @override
  Object toJson() => <Object>['zoomIn'];

  @override
  g.CameraUpdate toGoogle() {
    return g.CameraUpdate.zoomIn();
  }

  @override
  h.CameraUpdate toHuawei() {
    return h.CameraUpdate.zoomIn();
  }
}

/// Defines a camera zoom out.
class CameraUpdateZoomOut extends CameraUpdate {
  /// Zooms out the camera.
  const CameraUpdateZoomOut() : super._();
  @override
  Object toJson() => <Object>['zoomOut'];

  @override
  g.CameraUpdate toGoogle() {
    return g.CameraUpdate.zoomOut();
  }

  @override
  h.CameraUpdate toHuawei() {
    return h.CameraUpdate.zoomOut();
  }
}

/// Defines a camera zoom to an absolute zoom.
class CameraUpdateZoomTo extends CameraUpdate {
  /// Creates a zoom to an absolute zoom level.
  const CameraUpdateZoomTo(this.zoom) : super._();

  /// New zoom level of the camera.
  final double zoom;
  @override
  Object toJson() => <Object>['zoomTo', zoom];

  @override
  g.CameraUpdate toGoogle() {
    return g.CameraUpdate.zoomTo(zoom);
  }

  @override
  h.CameraUpdate toHuawei() {
    return h.CameraUpdate.zoomTo(zoom);
  }
}
