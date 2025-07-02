import 'dart:async';

import 'package:animated_widgets/widgets/scale_animated.dart';
import 'package:flutter/material.dart';
import 'package:jc_widgets/src/measure_size.dart';

import 'models/lat_lng.dart';
import 'models/map_controller.dart';
import 'models/screen_coordinate.dart';

class CustomInfoWindowController {
  /// Add custom [Widget] and [Marker]'s [LatLng] to [CustomInfoWindow] and make it visible.
  Function(Widget, LatLng)? addInfoWindow;

  /// Notifies [CustomInfoWindow] to redraw as per change in position.
  VoidCallback? onCameraMove;

  /// Hides [CustomInfoWindow].
  VoidCallback? hideInfoWindow;

  /// Holds [GoogleMapController] for calculating [CustomInfoWindow] position.
  MapController? mapController;

  void dispose() {
    addInfoWindow = null;
    onCameraMove = null;
    hideInfoWindow = null;
    mapController = null;
  }
}

class CustomInfoWindow extends StatefulWidget {
  final CustomInfoWindowController controller;

  final double offset;
  final bool hidePrevious;
  final Duration duration;
  final double? overridePixelRatio;

  const CustomInfoWindow({super.key,
    required this.controller,
    this.offset = 50,
    this.hidePrevious = true,
    this.duration = const Duration(milliseconds: 300),
    this.overridePixelRatio,
  })  : assert(offset >= 0);

  @override
  State<CustomInfoWindow> createState() => _CustomInfoWindowStateNew();
}

class _CustomInfoWindowStateNew extends State<CustomInfoWindow> {
  bool _showNow = false;
  bool _hide = false;
  double _leftMargin = 0;
  double _topMargin = 0;
  Widget? _child;
  LatLng? _latLng;
  int finishedCount = 0;
  Size _childSize = Size.zero;
  OverlayEntry? _overlayEntry;
  final List<double> _scaleValues = const [0.0, 1.2, 1.0];

  @override
  void initState() {
    super.initState();
    widget.controller.addInfoWindow = _addInfoWindow;
    widget.controller.onCameraMove = _onCameraMove;
    widget.controller.hideInfoWindow = _hideInfoWindow;
  }

  void _updateInfoWindow() async {
    if (_latLng == null ||
        _child == null ||
        widget.controller.mapController == null||
        widget.controller.mapController?.controllerExisted != true) {
      return;
    }
    ScreenCoordinate screenCoordinate = await widget
        .controller.mapController!
        .getScreenCoordinate(_latLng!);
    double devicePixelRatio = widget.overridePixelRatio ?? MediaQuery.of(context).devicePixelRatio;

    double left =
        (screenCoordinate.x.toDouble() / devicePixelRatio) - (_childSize.width / 2);
    double top = (screenCoordinate.y.toDouble() / devicePixelRatio) -
        (widget.offset + _childSize.height);

    setState(() {
      _hide = false;
      _showNow = true;
      _leftMargin = left;
      _topMargin = top;
    });
  }

  Future<Size> _calculateChildSize() async {
    if(_child == null) return Size.zero;

    Completer<Size> completer = Completer();

    if(_overlayEntry != null){
      _overlayEntry?.remove();
      _overlayEntry = null;
    }

    _overlayEntry = OverlayEntry(
        builder: (context) => Stack(
          children: [
            Opacity(
              opacity: 0,
              child: MeasureSize(
                onChange: (Size value) {

                  _overlayEntry?.remove();
                  _overlayEntry = null;

                  completer.complete(value);
                },
                child: _child!,
              ),
            )
          ],
        )
    );

    /*SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      if(_overlayEntry != null) Overlay.of(context).insert(_overlayEntry!);
    });*/

    /*WidgetsBinding.instance.addPostFrameCallback((d){
      if(_overlayEntry != null) Overlay.of(context).insert(_overlayEntry!);
    });*/
    _checkContextAndInsertOverlay();

    return completer.future;
  }

  void _checkContextAndInsertOverlay() async {
    if(context.mounted){
      if(_overlayEntry != null) Overlay.of(context).insert(_overlayEntry!);
    }
    else{
      await Future.delayed(const Duration(milliseconds: 20));
      _checkContextAndInsertOverlay();
    }
  }

  void _addInfoWindow(Widget child, LatLng latLng) async {

    if(widget.hidePrevious && latLng != _latLng){
      _hideInfoWindow();
      await Future.delayed(widget.duration);
    }

    _child = child;
    _latLng = latLng;
    _childSize = await _calculateChildSize();
    _updateInfoWindow();
  }

  void _onCameraMove() {
    if (_hide || !_showNow) return;
    _updateInfoWindow();
  }

  void _hideInfoWindow() {
    if(_showNow){
      setState(() {
        _showNow = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      left: _leftMargin,
      top: _topMargin,
      duration: const Duration(milliseconds: 100),
      child: Visibility(
        visible: (_hide == true ||
            (_leftMargin == 0 && _topMargin == 0) ||
            _child == null ||
            _latLng == null)
            ? false
            : true,
        child: ScaleAnimatedWidget(
          enabled: _showNow,
          duration: widget.duration,
          values: _scaleValues,
          animationFinished: (done){
            if(done == _hide) {
              finishedCount++;
            } else {
              finishedCount = 0;
            }
            if(finishedCount >= _scaleValues.length) {
              setState(() => _hide = true);
            }
          },
          child: Container(
            alignment: Alignment.bottomCenter,
            height: _childSize.height,
            width: _childSize.width,
            child: _child,
          ),
        ),
    ));
  }
}