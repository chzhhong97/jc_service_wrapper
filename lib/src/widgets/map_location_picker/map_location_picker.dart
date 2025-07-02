import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jc_service_wrapper/jc_service_wrapper.dart';
import 'package:jc_service_wrapper/src/widgets/map_location_picker/animated_pin.dart';
import 'package:jc_service_wrapper/src/widgets/map_location_picker/models/map_controller.dart';
import 'google_map_location_picker.dart';
import 'huawei_map_location_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as g show LatLng;
import 'package:huawei_map/huawei_map.dart' as h show LatLng;

import 'models/bitmap_descriptor.dart';
import 'models/camera_update.dart';
import 'models/lat_lng.dart';

class MapLocationPicker extends StatefulWidget {
  const MapLocationPicker({
    required this.initialCameraPosition,
    this.myLocation,
    this.onMapCreated,
    this.onCameraMove,
    this.onCameraIdle,
    this.onCameraMoveStarted,
    this.onPositionUpdate,
    this.pinBuilder,
    this.onBuildInfoWindow,
    this.selectInitialPosition = true,
    this.scrollGesturesEnabled = true,
    this.zoomGesturesEnabled = true,
    this.rotateGesturesEnabled = true,
    this.zoomControlsEnabled = true,
    this.disableCenterPin = false,
    this.autoZoomToMarkers = false,
    this.zoom = 0,
    this.markersSelectedMap = const {},
    this.selectedMarker,
    this.unselectedMarker,
    this.overridePixelRatio,
    this.infoWindowOffset = 25,
    this.overrideServiceType,
    this.clickedMarkerMoveCamera = true,
    super.key,
  });

  final LatLng initialCameraPosition;
  final LatLng? myLocation;
  final Function(MapController controller)? onMapCreated;
  final Function()? onCameraIdle;
  final Function()? onCameraMoveStarted;
  final Function(CameraPosition position)? onCameraMove;
  final Function(LatLng position)? onPositionUpdate;
  final Widget Function(BuildContext context, PinState state)? pinBuilder;
  final Widget? Function(BuildContext context, LatLng coordinate)?
      onBuildInfoWindow;
  final bool selectInitialPosition;
  final bool zoomControlsEnabled;
  final bool scrollGesturesEnabled;
  final bool zoomGesturesEnabled;
  final bool rotateGesturesEnabled;
  final bool disableCenterPin;
  final bool autoZoomToMarkers;
  final double zoom;
  final Map<LatLng, bool> markersSelectedMap;
  final FutureOr<BitmapDescriptor?> Function()? selectedMarker;
  final FutureOr<BitmapDescriptor?> Function()? unselectedMarker;
  final double? overridePixelRatio;
  final double infoWindowOffset;
  final ServiceType? overrideServiceType;
  final bool clickedMarkerMoveCamera;

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {

  final Map<g.LatLng, bool> googleMarkers = {};
  final Map<h.LatLng, bool> huaweiMarkers = {};

  late ServiceType serviceType = widget.overrideServiceType ?? ServiceWrapper().serviceType;
  late MapController mapController = MapController(serviceType);

  @override
  void initState() {
    _updateMarkers();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant MapLocationPicker oldWidget) {
    if(widget.overrideServiceType != null && serviceType != widget.overrideServiceType){
      serviceType = widget.overrideServiceType ?? ServiceWrapper().serviceType;
      mapController = MapController(serviceType);
      if(mounted){
        setState(() {});
      }
    }

    if(widget.markersSelectedMap != oldWidget.markersSelectedMap){
      _updateMarkers();
    }

    super.didUpdateWidget(oldWidget);
  }

  void _updateMarkers(){
    if(serviceType == ServiceType.GMS || serviceType == ServiceType.WEB){
      widget.markersSelectedMap.forEach((k, v) {
        try {
          googleMarkers[k.toGoogle()] = v;
        } catch (e) {}
      });
    }
    else if(serviceType == ServiceType.HMS){
      widget.markersSelectedMap.forEach((k, v) {
        try {
          huaweiMarkers[k.toHuawei()] = v;
        } catch (e) {}
      });
    }

    if(mounted){
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if(!ServiceWrapper().isInit && widget.overrideServiceType == null){
      return Center(
        child: Text(
          'Initialize ServiceWrapper before using this widget',
        ),
      );
    }

    final serviceType = widget.overrideServiceType ?? ServiceWrapper().serviceType;
    final MapController mapController = MapController(serviceType);
    switch (serviceType) {
      case ServiceType.GMS:
      case ServiceType.WEB:
        return GoogleMapLocationPicker(
          initialCameraPosition: widget.initialCameraPosition.toGoogle(),
          myLocation: widget.myLocation?.toGoogle(),
          onMapCreated: (controller) {
            mapController.setController(controller);
            widget.onMapCreated?.call(mapController);
          },
          onCameraMove: (c) {
            widget.onCameraMove?.call(CameraPosition.fromGoogle(c));
          },
          onCameraIdle: widget.onCameraIdle,
          onCameraMoveStarted: widget.onCameraMoveStarted,
          onPositionUpdate: (latLng) {
            widget.onPositionUpdate?.call(LatLng.fromGoogle(latLng));
          },
          pinBuilder: widget.pinBuilder,
          onBuildInfoWindow: (context, latLng) {
            return widget.onBuildInfoWindow?.call(context, LatLng.fromGoogle(latLng));
          },
          selectInitialPosition: widget.selectInitialPosition,
          scrollGesturesEnabled: widget.scrollGesturesEnabled,
          zoomGesturesEnabled: widget.zoomGesturesEnabled,
          rotateGesturesEnabled: widget.rotateGesturesEnabled,
          zoomControlsEnabled: widget.zoomControlsEnabled,
          disableCenterPin: widget.disableCenterPin,
          autoZoomToMarkers: widget.autoZoomToMarkers,
          zoom: widget.zoom,
          markersSelectedMap: googleMarkers,
          selectedMarker: () async {
            final bit = await widget.selectedMarker?.call();
            return bit?.toGoogle();
          },
          unselectedMarker: () async {
            final bit = await widget.unselectedMarker?.call();
            return bit?.toGoogle();
          },
          overridePixelRatio: widget.overridePixelRatio,
          infoWindowOffset: widget.infoWindowOffset,
          clickedMarkerMoveCamera: widget.clickedMarkerMoveCamera,
        );
      case ServiceType.HMS:
        return HuaweiMapLocationPicker(
          initialCameraPosition: widget.initialCameraPosition.toHuawei(),
          myLocation: widget.myLocation?.toHuawei(),
          onMapCreated: (controller) {
            mapController.setController(controller);
            widget.onMapCreated?.call(mapController);
          },
          onCameraMove: (c) {
            widget.onCameraMove?.call(CameraPosition.fromHuawei(c));
          },
          onCameraIdle: widget.onCameraIdle,
          onCameraMoveStarted: widget.onCameraMoveStarted,
          onPositionUpdate: (latLng) {
            widget.onPositionUpdate?.call(LatLng.fromHuawei(latLng));
          },
          pinBuilder: widget.pinBuilder,
          onBuildInfoWindow: (context, latLng) {
            return widget.onBuildInfoWindow?.call(context, LatLng.fromHuawei(latLng));
          },
          selectInitialPosition: widget.selectInitialPosition,
          scrollGesturesEnabled: widget.scrollGesturesEnabled,
          zoomGesturesEnabled: widget.zoomGesturesEnabled,
          rotateGesturesEnabled: widget.rotateGesturesEnabled,
          zoomControlsEnabled: widget.zoomControlsEnabled,
          disableCenterPin: widget.disableCenterPin,
          autoZoomToMarkers: widget.autoZoomToMarkers,
          zoom: widget.zoom,
          markersSelectedMap: huaweiMarkers,
          selectedMarker: () async {
            final bit = await widget.selectedMarker?.call();
            return bit?.toHuawei();
          },
          unselectedMarker: () async {
            final bit = await widget.unselectedMarker?.call();
            return bit?.toHuawei();
          },
          overridePixelRatio: widget.overridePixelRatio,
          infoWindowOffset: widget.infoWindowOffset,
          clickedMarkerMoveCamera: widget.clickedMarkerMoveCamera,
        );
      default:
    }

    return Center(
      child: Text(
        'Currently device does not support Google and Huawei',
      ),
    );
  }
}
