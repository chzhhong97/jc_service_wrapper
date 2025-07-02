import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jc_service_wrapper/jc_service_wrapper.dart';
import 'package:jc_service_wrapper/src/widgets/map_location_picker/animated_pin.dart';
import 'package:jc_service_wrapper/src/widgets/map_location_picker/custom_info_window.dart';
import 'package:jc_service_wrapper/src/widgets/map_location_picker/models/map_controller.dart';
import 'dart:ui' as ui;
import 'models/lat_lng.dart' as l;

class GoogleMapLocationPicker extends StatefulWidget {
  const GoogleMapLocationPicker(
      {required this.initialCameraPosition,
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
        this.clickedMarkerMoveCamera = true,
        super.key,
      });

  final LatLng initialCameraPosition;
  final LatLng? myLocation;
  final Function(GoogleMapController controller)? onMapCreated;
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
  final bool clickedMarkerMoveCamera;

  @override
  State<GoogleMapLocationPicker> createState() => _GoogleMapLocationPickerState();
}

class _GoogleMapLocationPickerState extends State<GoogleMapLocationPicker> {
  Completer<GoogleMapController> completer = Completer();
  CameraPosition? prevCameraPosition;
  LatLng currentPosition = const LatLng(0, 0);
  ValueNotifier<PinState> pinState = ValueNotifier(PinState.Idle);
  Set<Marker> markers = {};

  BitmapDescriptor? selected;
  BitmapDescriptor? unselected;
  Marker? selectedMarker;
  final CustomInfoWindowController _infoWindowController =
  CustomInfoWindowController();
  Map<LatLng, bool> _markersSelectedMap = {};

  static Future getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))
        ?.buffer
        .asUint8List();
  }

  Future loadMarkerIcon() async {
    selected = await widget.selectedMarker?.call();
    unselected = await widget.unselectedMarker?.call();
  }

  void getMarker() async {
    markers = buildMarkers();
  }

  Future zoomToMarkers({bool firstTime = false}) async {
    if ((widget.myLocation == null &&
        selectedMarker == null &&
        widget.autoZoomToMarkers) || (firstTime && markers.isNotEmpty)) {
      final controller = await completer.future;
      final bounds = _bounds(markers);

      if (bounds != null) {
        await Future.delayed(const Duration(milliseconds: 100), () {
          controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 30));
        });

        //Delay before next camera animate
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  Set<Marker> buildMarkers() {
    Set<Marker> markers = {};
    final mSelected = selected ?? unselected;
    final mUnselected = unselected ?? selected;
    if(mSelected == null && mUnselected == null) {
      debugPrint('Please provide selectedMarkerBitmap and unselectedMarkerBitmap to show marker');
      return {};
    }

    if (_markersSelectedMap.isNotEmpty == true) {
      for (LatLng key in _markersSelectedMap.keys) {
        if (_markersSelectedMap.containsKey(key) == true) {
          Marker currentMarker = Marker(
              markerId: MarkerId("${key.latitude}, ${key.longitude}"),
              draggable: false,
              position: key,
              zIndex: _markersSelectedMap[key]! ? 1 : 0,
              icon: _markersSelectedMap[key]! ? mSelected! : mUnselected!,
              onTap: () {
                if(widget.clickedMarkerMoveCamera){
                  completer.future.then((c) => c.animateCamera(CameraUpdate.newLatLng(key)));
                }
                final infoWindow = widget.onBuildInfoWindow?.call(context, key);
                if (infoWindow != null) {
                  _infoWindowController.addInfoWindow?.call(infoWindow, l.LatLng(key.latitude, key.longitude));
                }

                setState(() {
                  _markersSelectedMap.updateAll((k, v) => false);
                  _markersSelectedMap[key] = true;
                  getMarker();
                });
              });

          if (_markersSelectedMap[key]! == true) {
            selectedMarker = currentMarker;
          }

          markers.add(currentMarker);
        }
      }
    }
    return markers;
  }

  @override
  void initState() {
    super.initState();
    _markersSelectedMap = Map.of(widget.markersSelectedMap);
    _updateCurrentPosition();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await loadMarkerIcon();
      getMarker();
      await zoomToMarkers(firstTime: true);
      _updateMyLocation(firstTime: true);
      if (mounted) setState(() {});
    });
  }

  @override
  Future didChangeDependencies() async {
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(covariant GoogleMapLocationPicker oldWidget) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      //_updateCurrentPosition();
      if (oldWidget.markersSelectedMap != widget.markersSelectedMap) {
        _markersSelectedMap = Map.of(widget.markersSelectedMap);
        _infoWindowController.hideInfoWindow?.call();
        await loadMarkerIcon();
        getMarker();
        await zoomToMarkers();
      }
      _updateMyLocation();
      if (mounted) setState(() {});
    });

    super.didUpdateWidget(oldWidget);
  }

  void _updateCurrentPosition() {
    currentPosition = widget.initialCameraPosition;
  }

  void _updateMyLocation({bool firstTime = false}) async {
    if ((widget.myLocation != null && widget.myLocation! != currentPosition) || (firstTime && widget.myLocation != null)) {
      if (_markersSelectedMap.isNotEmpty == true) {
        await zoomToFit();
      } else {
        final controller = await completer.future;
        prevCameraPosition = cameraPosition;
        await controller.animateCamera(CameraUpdate.newLatLngZoom(widget.myLocation!, widget.zoom));
      }

      currentPosition = widget.myLocation!;
      _onPositionUpdate(cameraPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: cameraPosition,
          zoomControlsEnabled: widget.zoomControlsEnabled,
          scrollGesturesEnabled: widget.scrollGesturesEnabled,
          zoomGesturesEnabled: widget.zoomGesturesEnabled,
          rotateGesturesEnabled: widget.rotateGesturesEnabled,
          myLocationButtonEnabled: false,
          myLocationEnabled: widget.disableCenterPin ? true : false,
          mapToolbarEnabled: false,
          markers: markers,
          onMapCreated: (controller) {
            completer.complete(controller);
            _infoWindowController.mapController = MapController(ServiceType.GMS)..setController(controller);

            if (widget.selectInitialPosition) {
              _onPositionUpdate(cameraPosition);
            }

            widget.onMapCreated?.call(controller);
          },
          onCameraIdle: () {
            if (pinState.value == PinState.Dragging) {
              _onPositionUpdate(cameraPosition);
            }
            pinState.value = PinState.Idle;
            widget.onCameraIdle?.call();
          },
          onCameraMoveStarted: () {
            widget.onCameraMoveStarted?.call();

            prevCameraPosition = cameraPosition;

            pinState.value = PinState.Dragging;
          },
          onCameraMove: (position) {
            currentPosition = position.target;
            _infoWindowController.onCameraMove?.call();
            widget.onCameraMove?.call(position);
          },
          onTap: (position) {
            _infoWindowController.hideInfoWindow?.call();
            setState(() {
              _markersSelectedMap.updateAll((k, v) => false);
              selectedMarker = null;
              getMarker();
            });
          },
          gestureRecognizers: {}..add(
              Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer())),
        ),
        CustomInfoWindow(
          controller: _infoWindowController,
          offset: widget.infoWindowOffset,
          overridePixelRatio: widget.overridePixelRatio,
        ),
        if (!widget.disableCenterPin) _buildPin(),
      ],
    );
  }

  Widget _buildPin() {
    return Center(
      child: ValueListenableBuilder(
        valueListenable: pinState,
        builder: (BuildContext context, PinState value, Widget? child) {
          if (widget.pinBuilder != null) {
            return widget.pinBuilder!(context, value);
          }

          return _defaultPinBuilder(context, value);
        },
      ),
    );
  }

  Future zoomToFit() async {
    // Calculate the bounds of the two markers
    if (widget.myLocation != null && selectedMarker != null) {
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          widget.myLocation!.latitude < selectedMarker!.position.latitude
              ? widget.myLocation!.latitude
              : selectedMarker!.position.latitude,
          widget.myLocation!.longitude < selectedMarker!.position.longitude
              ? widget.myLocation!.longitude
              : selectedMarker!.position.longitude,
        ),
        northeast: LatLng(
          widget.myLocation!.latitude > selectedMarker!.position.latitude
              ? widget.myLocation!.latitude
              : selectedMarker!.position.latitude,
          widget.myLocation!.longitude > selectedMarker!.position.longitude
              ? widget.myLocation!.longitude
              : selectedMarker!.position.longitude,
        ),
      );

      // Move camera to fit the bounds with padding
      final controller = await completer.future;

      await Future.delayed(const Duration(milliseconds: 100), () {
        controller.animateCamera(
          CameraUpdate.newLatLngBounds(
            bounds,
            50.0, // padding
          ),
        );
      });
    }
  }

  LatLngBounds? _bounds(Set<Marker> markers) {
    if (markers.isEmpty) return null;
    return _createBounds(markers.map((m) => m.position).toList());
  }

  LatLngBounds _createBounds(List<LatLng> positions) {
    final southwestLat = positions.map((p) => p.latitude).reduce(
            (value, element) => value < element ? value : element); // smallest
    final southwestLon = positions
        .map((p) => p.longitude)
        .reduce((value, element) => value < element ? value : element);
    final northeastLat = positions.map((p) => p.latitude).reduce(
            (value, element) => value > element ? value : element); // biggest
    final northeastLon = positions
        .map((p) => p.longitude)
        .reduce((value, element) => value > element ? value : element);
    return LatLngBounds(
        southwest: LatLng(southwestLat, southwestLon),
        northeast: LatLng(northeastLat, northeastLon));
  }

  Widget _defaultPinBuilder(BuildContext context, PinState state) {
    if (state == PinState.Preparing) {
      return Container();
    }

    Widget pin = const Icon(Icons.place, size: 36, color: Colors.red);

    if (state == PinState.Dragging) {
      //use animated
      pin = AnimatedPin(
        child: pin,
      );
    }

    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              pin,
              const SizedBox(height: 42,)
            ],
          ),
        ),
        Center(
          child: Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  CameraPosition get cameraPosition =>
      CameraPosition(target: currentPosition);

  void _onPositionUpdate(CameraPosition position) {
    if (prevCameraPosition != null) {
      if (prevCameraPosition!.target == position.target) {
        return;
      }
    }

    widget.onPositionUpdate?.call(position.target);
  }

  @override
  void dispose() {
    _infoWindowController.dispose();
    super.dispose();
  }
}