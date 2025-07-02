import 'package:flutter/material.dart';

import 'delivery_info_window_shape.dart';

class MapInfoWindow extends StatefulWidget{

  final double nipHeight;
  final double nipWidth;
  final EdgeInsets margin;
  final Color color;
  final Radius radius;
  final double nipRadius;
  final EdgeInsets padding;
  final double elevation;
  final Color shadowColor;
  final double borderWidth;
  final Color borderColor;
  final Widget Function(BuildContext context) childBuilder;
  
  const MapInfoWindow({
    super.key,
    required this.childBuilder,
    this.nipHeight = 20,
    this.nipWidth = 20,
    this.margin = EdgeInsets.zero,
    this.color = Colors.white,
    this.radius = Radius.zero,
    this.nipRadius = 3,
    this.padding = EdgeInsets.zero,
    this.elevation = 5,
    this.shadowColor = Colors.black,
    this.borderWidth = 0,
    this.borderColor = Colors.transparent,
  });

  @override
  State<MapInfoWindow> createState() => _MapInfoWindowState();
}

class _MapInfoWindowState extends State<MapInfoWindow>{

  @override
  Widget build(BuildContext context) {
    BubbleClipper bubbleClipper = BubbleClipper(
        nipWidth: widget.nipWidth,
        nipHeight: widget.nipHeight,
        radius: widget.radius,
        nipRadius: widget.nipRadius,
        padding: widget.padding);

    return Container(
      margin: widget.margin,
      child: CustomPaint(
        painter: BubblePainter(
          color: widget.color,
          clipper: bubbleClipper,
          elevation: widget.elevation,
          borderColor: widget.borderColor,
          borderWidth: widget.borderWidth,
          shadowColor: widget.shadowColor,
        ),
        child: Padding(
          padding: bubbleClipper.edgeInsets,
          child: widget.childBuilder(context),
        ),
      ),
    );
  }

}