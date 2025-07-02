import 'package:huawei_map/huawei_map.dart' as h;
import 'package:jc_service_wrapper/jc_service_wrapper.dart';
import 'package:jc_service_wrapper/src/widgets/map_location_picker/models/screen_coordinate.dart';

import 'camera_update.dart';
import 'lat_lng.dart';

class MapController{
  h.HuaweiMapController? _huaweiMapController;

  bool get controllerExisted {
    if(serviceType == ServiceType.HMS){
      return _huaweiMapController != null;
    }

    return false;
  }

  final ServiceType serviceType;

  MapController(this.serviceType);

  void setController(dynamic controller){
    if(serviceType == ServiceType.HMS){
      if(controller is h.HuaweiMapController) _huaweiMapController = controller;
    }
  }

  Future<ScreenCoordinate> getScreenCoordinate(LatLng latLng) async {
    if(serviceType == ServiceType.HMS){
      final screenCoordinate = await _huaweiMapController?.getScreenCoordinate(h.LatLng(
        latLng.latitude,
        latLng.longitude,
      ));
      if(screenCoordinate != null){
        return ScreenCoordinate(
            x: screenCoordinate.x,
            y: screenCoordinate.y
        );
      }
    }

    return const ScreenCoordinate(x:0, y:0);
  }

  Future<void> animateCamera(CameraUpdate cameraUpdate) async {
    if(serviceType == ServiceType.HMS){
      return _huaweiMapController?.animateCamera(cameraUpdate.toHuawei());
    }
  }

  Future<void> moveCamera(CameraUpdate cameraUpdate) async {
    if(serviceType == ServiceType.HMS){
      return _huaweiMapController?.moveCamera(cameraUpdate.toHuawei());
    }
  }

  Future<LatLng?> getLatLng(ScreenCoordinate screenCoordinate) async {
    if(serviceType == ServiceType.HMS){
      final latLng = await _huaweiMapController?.getLatLng(screenCoordinate.toHuawei());
      if(latLng != null) return LatLng(latLng.lat, latLng.lng);
    }

    return null;
  }

  Future<double?> getZoomLevel() async {
    if(serviceType == ServiceType.HMS){
      return _huaweiMapController?.getZoomLevel();
    }

    return null;
  }

  void dispose() {

  }
}