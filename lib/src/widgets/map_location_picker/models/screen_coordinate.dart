import 'package:flutter/foundation.dart' show immutable, objectRuntimeType;
import 'package:huawei_map/huawei_map.dart' as h show ScreenCoordinate;

@immutable
class ScreenCoordinate {
  const ScreenCoordinate({
    required this.x,
    required this.y,
  });

  final int x;

  final int y;

  Object toJson() {
    return <String, int>{
      'x': x,
      'y': y,
    };
  }

  @override
  String toString() => '${objectRuntimeType(this, 'ScreenCoordinate')}($x, $y)';

  @override
  bool operator ==(Object other) {
    return other is ScreenCoordinate && other.x == x && other.y == y;
  }
  @override
  int get hashCode => Object.hash(x, y);
  h.ScreenCoordinate toHuawei() {
    return h.ScreenCoordinate(
      x: x,
      y: y,
    );
  }
}
