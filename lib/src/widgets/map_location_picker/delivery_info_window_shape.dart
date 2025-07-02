import 'dart:math';
import 'package:flutter/material.dart';

//ShapeBorder
class DeliveryInfoWindowShape extends ShapeBorder {
  final double bottomPadding;
  final double nipHeight;
  double nipWidth;
  double nipRadius;
  final double borderRadius;

  DeliveryInfoWindowShape({this.bottomPadding = 0, this.nipHeight = 10, this.nipWidth = 20, this.borderRadius = 0, this.nipRadius = 0});

  @override
  EdgeInsetsGeometry get dimensions =>
      EdgeInsets.only(bottom: bottomPadding);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    var sameWidth = false;
    if(nipWidth >= rect.width){
      nipWidth = rect.width;
      sameWidth = true;
    }
    
    if((nipRadius*2) >= nipWidth){
      nipRadius = nipWidth/2;
    }
    /*var radiusX = borderRadius;
    var radiusY = borderRadius;
    final maxRadiusX = rect.width/2;
    final maxRadiusY = rect.height/2;
    
    if(radiusX > maxRadiusX){
      radiusY *= maxRadiusX/radiusX;
      radiusX = maxRadiusX;
    }
    if(radiusY > maxRadiusY){
      radiusX *= maxRadiusY / radiusY;
      radiusY = maxRadiusY;
    }*/
    
    rect =
        Rect.fromPoints(rect.topLeft, rect.bottomRight - Offset(0, nipHeight));

    double startPointX = rect.bottomCenter.dx - nipWidth/2;
    if(sameWidth) {
      startPointX = rect.left + borderRadius;
    }
    double endPointX = rect.bottomCenter.dx + nipWidth/2;
    if(sameWidth) {
      endPointX = rect.right - borderRadius;
    }
    
    var path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)))
      //..addRRect(RRect.fromLTRBR(rect.left, rect.top, rect.right, rect.bottom, Radius.circular(borderRadius)))
      ..moveTo(startPointX, rect.bottomCenter.dy);

    if(nipRadius == 0){
      path
        ..lineTo(rect.bottomCenter.dx, rect.bottomCenter.dy+nipHeight)
        ..lineTo(endPointX, rect.bottomCenter.dy);
      //path.lineTo(cx, 0 + 100);
    }
    else{
      var interP1 = LineInterCircle.intersectionPoint(Point(startPointX, rect.bottomCenter.dy), Point(rect.bottomCenter.dx, rect.bottomCenter.dy+nipHeight), nipRadius);
      var interP2 = LineInterCircle.intersectionPoint(Point(endPointX, rect.bottomCenter.dy), Point(rect.bottomCenter.dx, rect.bottomCenter.dy+nipHeight), nipRadius);
      path
        ..lineTo(interP1.x.toDouble(), interP1.y.toDouble())
        ..arcToPoint(
          Offset(interP2.x.toDouble(), interP2.y.toDouble()),
          radius: Radius.circular(nipRadius),
          clockwise: false
      )
        ..lineTo(endPointX, rect.bottomCenter.dy);
      /*path
        .cubicTo(rect.bottomCenter.dx - nipRadius, rect.bottomCenter.dy+nipHeight,
            rect.bottomCenter.dx + nipRadius, rect.bottomCenter.dy+nipHeight,
            endPointX, rect.bottomCenter.dy);*/
      //path.quadraticBezierTo(rect.bottomCenter.dx, rect.bottomCenter.dy+nipHeight, endPointX, rect.bottomCenter.dy);
    }


    path.close();

    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}

/*Widget DeliveryInfoWindow({
  double nipHeight = 10,
  double nipWidth = 15,
  EdgeInsets margin = EdgeInsets.zero,
  Color color = Colors.blue,
  Radius radius = Radius.zero,
  double nipRadius = 0,
  EdgeInsets padding = EdgeInsets.zero,
  double elevation = 0,
  Color shadowColor = Colors.black,
  double borderWidth = 0,
  Color borderColor = Colors.transparent,
  required Widget child,
}){
  BubbleClipper _bubbleClipper = BubbleClipper(
      nipWidth: nipWidth,
      nipHeight: nipHeight,
      radius: radius,
      nipRadius: nipRadius,
    padding: padding
  );
  return Container(
    margin: margin,
    child: CustomPaint(
      painter: BubblePainter(
          color: color,
          clipper: _bubbleClipper,
        elevation: elevation,
        borderColor: borderColor,
        borderWidth: borderWidth,
        shadowColor: shadowColor
      ),
      child: Container(
        padding: _bubbleClipper.edgeInsets,
        child: child,
      ),
    ),
  );
}*/

class BubblePainter extends CustomPainter {
  final CustomClipper<Path> clipper;
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final double elevation;
  final Color shadowColor;
  final Paint _fillPaint;
  final Paint? _strokePaint;
  
  BubblePainter({
    required this.clipper,
    this.color = Colors.white,
    this.borderColor = Colors.transparent,
    this.borderWidth = 0,
    this.elevation = 0,
    this.shadowColor = Colors.black54,
  }) : _fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill,
    _strokePaint = borderWidth == 0 || borderColor == Colors.transparent
      ? null
        :(Paint()
          ..color = borderColor
          ..strokeWidth = borderWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
    );
  
  @override
  void paint(Canvas canvas, Size size) {
    final clip = clipper.getClip(size);
    
    if(elevation != 0.0){
      canvas.drawShadow(clip, shadowColor, elevation, false);
    }
    
    canvas.drawPath(clip, _fillPaint);
    
    if(_strokePaint != null){
      canvas.drawPath(clip, _strokePaint);
    }
    
    canvas.drawPath(clip, _fillPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class BubbleClipper extends CustomClipper<Path>{
  final Radius radius;
  double nipWidth;
  final double nipHeight;
  double nipRadius;
  EdgeInsets padding;

  double _startOffset = 0; // Offsets of the bubble
  double _endOffset = 0;
  double _nipCX = 0; // The center of the circle
  double _nipCY = 0;
  double _nipPX = 0; // The point of contact of the nip with the circle
  double _nipPY = 0;


  BubbleClipper({
    this.radius = Radius.zero,
    this.nipWidth = 10,
    this.nipHeight = 20,
    this.nipRadius = 0,
    this.padding = EdgeInsets.zero,
  }):assert(nipRadius>=0), 
        assert(nipRadius <= nipWidth/2 && nipRadius <= nipHeight/2),
  super(){
    _startOffset = _endOffset = nipHeight;
    
    final k = nipWidth / 2 / nipHeight;
    final a = atan(k);

    _nipCX = sqrt(nipRadius * nipRadius * (1 + 1 / k / k));
    final nipStickOffset = (_nipCX - nipRadius).floorToDouble();

    _nipCX -= nipStickOffset;
    _nipCY = 0;
    _nipPX = _nipCX - nipRadius * sin(a);
    _nipPY = _nipCY + nipRadius * cos(a);
    _startOffset -= nipStickOffset;
    _endOffset -= nipStickOffset;
  }
  
  EdgeInsets get edgeInsets => EdgeInsets.only(
    top:padding.top,
    bottom: padding.bottom + _startOffset,
    left: padding.left,
    right: padding.right
  );
  
  @override
  Path getClip(Size size) {
    
    var radiusX = radius.x;
    var radiusY = radius.y;
    final maxRadiusX = size.width/2;
    final maxRadiusY = size.height/2;
    
    if(radiusX > maxRadiusX){
      radiusY *= maxRadiusX/radiusX;
      radiusX = maxRadiusX;
    }
    if(radiusY > maxRadiusY){
      radiusX *= maxRadiusY / radiusY;
      radiusY = maxRadiusY;
    }
    
    double middle = size.width/2;
    double middleNip = nipWidth/2;

    final cx = size.width / 2;
    final nipHalf = nipWidth / 2;  
    
    double bottom = size.height-_startOffset;
    
    var path = Path()
      ..addRRect(RRect.fromLTRBR(0,0,size.width, bottom, radius));
    //..addRRect(RRect.fromLTRBR(rect.left, rect.top, rect.right, rect.bottom, Radius.circular(borderRadius)))
    
    path
      ..moveTo(cx-nipHalf, bottom)
      ..lineTo(cx-nipHalf, bottom - radiusY)
      ..lineTo(cx+nipHalf, bottom - radiusY)
      ..lineTo(cx+nipHalf, bottom);
    
    if(nipRadius == 0){
      path.lineTo(cx, size.height);
      //path.lineTo(cx, 0 + 100);
    }
    else{
      /*var interP1 = LineInterCircle.intersectionPoint(Point(startPointX, size.height), Point(middle, size.height+nipHeight), nipRadius);
      var interP2 = LineInterCircle.intersectionPoint(Point(endPointX, size.height), Point(middle, size.height+nipHeight), nipRadius);
      path
        ..lineTo(interP1.x.toDouble(), interP1.y.toDouble())
        ..arcToPoint(
            Offset(interP2.x.toDouble(), interP2.y.toDouble()),
            radius: Radius.circular(nipRadius),
            clockwise: false
        )
        ..lineTo(endPointX, size.height);*/
      path
        ..lineTo(cx+_nipPX, size.height - _nipPY)
          ..arcToPoint(
            Offset(cx-_nipPX, size.height - _nipPY),
            radius: Radius.circular(nipRadius),
          );
    }


    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
  
  
}

class Line {
  ///y = kx + c
  static double normalLine(x, {k = 0, c = 0}) {
    return k * x + c;
  }

  ///Calculate the param K in y = kx +c
  static double paramK(Point p1, Point p2) {
    if (p1.x == p2.x) return 0;
    return (p2.y - p1.y) / (p2.x - p1.x);
  }

  ///Calculate the param C in y = kx +c
  static double paramC(Point p1, Point p2) {
    return p1.y - paramK(p1, p2) * p1.x;
  }
}

/// start point p1, end point p2,p2 is center of the circle,r is its radius.
class LineInterCircle {
  /// start point p1, end point p2,p2 is center of the circle,r is its radius.
  /// param a: y = kx +c intersect with circle,which has the center with point2 and radius R .
  /// when derive to x2+ ax +b = 0 equation. the param a is here.
  static double paramA(Point p1, Point p2) {
    return (2 * Line.paramK(p1, p2) * Line.paramC(p1, p2) -
        2 * Line.paramK(p1, p2) * p2.y -
        2 * p2.x) /
        (Line.paramK(p1, p2) * Line.paramK(p1, p2) + 1);
  }

  /// start point p1, end point p2,p2 is center of the circle,r is its radius.
  /// param b: y = kx +c intersect with circle,which has the center with point2 and radius R .
  /// when derive to x2+ ax +b = 0 equation. the param b is here.
  static double paramB(Point p1, Point p2, double r) {
    return (p2.x * p2.x -
        r * r +
        (Line.paramC(p1, p2) - p2.y) * (Line.paramC(p1, p2) - p2.y)) /
        (Line.paramK(p1, p2) * Line.paramK(p1, p2) + 1);
  }

  ///the circle has the intersection or not
  static bool isIntersection(Point p1, Point p2, double r) {
    var delta = sqrt(paramA(p1, p2) * paramA(p1, p2) - 4 * paramB(p1, p2, r));
    return delta >= 0.0;
  }

  ///the x coordinate whether or not is between two point we give.
  static bool _betweenPoint(x, Point p1, Point p2) {
    if (p1.x > p2.x) {
      return x > p2.x && x < p1.x;
    } else {
      return x > p1.x && x < p2.x;
    }
  }

  static Point _equalX(Point p1, Point p2, double r) {
    if (p1.y > p2.y) {
      return Point(p2.x, p2.y + r);
    } else if (p1.y < p2.y) {
      return Point(p2.x, p2.y - r);
    } else {
      return p2;
    }
  }

  static Point _equalY(Point p1, Point p2, double r) {
    if (p1.x > p2.x) {
      return Point(p2.x + r, p2.y);
    } else if (p1.x < p2.x) {
      return Point(p2.x - r, p2.y);
    } else {
      return p2;
    }
  }

  ///intersection point
  static Point intersectionPoint(Point p1, Point p2, double r) {
    if (p1.x == p2.x) return _equalX(p1, p2, r);
    if (p1.y == p2.y) return _equalY(p1, p2, r);
    var delta = sqrt(paramA(p1, p2) * paramA(p1, p2) - 4 * paramB(p1, p2, r));
    if (delta < 0.0) {
      //when no intersection, i will return the center of the circ  le.
      return p2;
    }
    var a_2 = -paramA(p1, p2) / 2.0;
    var x1 = a_2 + delta / 2;
    if (_betweenPoint(x1, p1, p2)) {
      var y1 = Line.paramK(p1, p2) * x1 + Line.paramC(p1, p2);
      return Point(x1, y1);
    }
    var x2 = a_2 - delta / 2;
    var y2 = Line.paramK(p1, p2) * x2 + Line.paramC(p1, p2);
    return Point(x2, y2);
  }
}