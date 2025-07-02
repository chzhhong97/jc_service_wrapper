import 'dart:typed_data';
import 'package:google_maps_flutter/google_maps_flutter.dart' as g show BitmapDescriptor, BytesMapBitmap;
import 'package:huawei_map/huawei_map.dart' as h show BitmapDescriptor;

class BitmapDescriptor{
  final double hue;
  final Uint8List? bytes;
  final double? imagePixelRatio;
  final  double? width;
  final double? height;

  const BitmapDescriptor._({this.bytes, this.width, this.height, this.imagePixelRatio, this.hue = 0});

  factory BitmapDescriptor.bytes(Uint8List byteData, {double? width, double? height, double? imagePixelRatio}){
    return BitmapDescriptor._(
      bytes: byteData,
      width: width,
      height: height,
      imagePixelRatio: imagePixelRatio,
    );
  }

  static const BitmapDescriptor defaultMarker = BitmapDescriptor._();
  static BitmapDescriptor defaultMarkerWithHue(double hue) {
    return 0.0 <= hue && hue < 360.0
        ? BitmapDescriptor._(hue: hue)
        : defaultMarker;
  }

  g.BitmapDescriptor toGoogle(){
    if(bytes != null){
      return g.BitmapDescriptor.bytes(bytes!, width: width, height: height, imagePixelRatio: imagePixelRatio);
    }

    return 0.0 <= hue && hue < 360.0
        ? g.BitmapDescriptor.defaultMarkerWithHue(hue)
        : g.BitmapDescriptor.defaultMarker;
  }

  h.BitmapDescriptor toHuawei(){
    if(bytes != null){
      return h.BitmapDescriptor.fromBytes(bytes!);
    }

    return 0.0 <= hue && hue < 360.0
        ? h.BitmapDescriptor.defaultMarkerWithHue(hue)
        : h.BitmapDescriptor.defaultMarker;
  }
}