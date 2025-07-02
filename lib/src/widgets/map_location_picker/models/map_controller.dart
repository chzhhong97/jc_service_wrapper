import 'package:google_maps_flutter/google_maps_flutter.dart' as g;
import 'package:jc_service_wrapper/jc_service_wrapper.dart';
import 'package:jc_service_wrapper/src/widgets/map_location_picker/models/screen_coordinate.dart';

import 'camera_update.dart';
import 'lat_lng.dart';

class MapController{
  g.GoogleMapController? _googleMapController;

  bool get controllerExisted {
    if(serviceType == ServiceType.GMS || serviceType == ServiceType.WEB){
      return _googleMapController != null;
    }

    return false;
  }

  final ServiceType serviceType;

  MapController(this.serviceType);

  void setController(dynamic controller){
    if(serviceType == ServiceType.GMS || serviceType == ServiceType.WEB){
      if(controller is g.GoogleMapController) _googleMapController = controller;
    }
  }

  Future<ScreenCoordinate> getScreenCoordinate(LatLng latLng) async {
    if(serviceType == ServiceType.GMS || serviceType == ServiceType.WEB){
      final screenCoordinate = await _googleMapController?.getScreenCoordinate(g.LatLng(
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
    if(serviceType == ServiceType.GMS || serviceType == ServiceType.WEB){
      return _googleMapController?.animateCamera(cameraUpdate.toGoogle());
    }
  }

  Future<void> moveCamera(CameraUpdate cameraUpdate) async {
    if(serviceType == ServiceType.GMS || serviceType == ServiceType.WEB){
      return _googleMapController?.moveCamera(cameraUpdate.toGoogle());
    }
  }

  Future<LatLng?> getLatLng(ScreenCoordinate screenCoordinate) async {
    if(serviceType == ServiceType.GMS || serviceType == ServiceType.WEB){
      final latLng = await _googleMapController?.getLatLng(screenCoordinate.toGoogle());
      if(latLng != null) return LatLng(latLng.latitude, latLng.longitude);
    }

    return null;
  }

  Future<double?> getZoomLevel() async {
    if(serviceType == ServiceType.GMS || serviceType == ServiceType.WEB){
      return _googleMapController?.getZoomLevel();
    }

    return null;
  }

  void dispose() {
    _googleMapController?.dispose();
  }
}