import 'dart:math' as math;

import 'package:flutter/material.dart';

class BiometricIcon extends StatelessWidget {
  const BiometricIcon({
    super.key,
    required this.type,
    this.size = 32,
    this.color = Colors.black,
    this.strokeWidth,
  });

  final BiometricIconType type;
  final double size;
  final Color color;
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _BiometricIconPainter(
          type: type,
          color: color,
          strokeWidth: strokeWidth ?? size * 0.055,
        ),
      ),
    );
  }
}

enum BiometricIconType { faceId, fingerprint }

class _BiometricIconPainter extends CustomPainter {
  const _BiometricIconPainter({
    required this.type,
    required this.color,
    required this.strokeWidth,
  });

  final BiometricIconType type;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    _drawCorners(canvas, size, paint);

    switch (type) {
      case BiometricIconType.faceId:
        _drawFaceId(canvas, size, paint);
      case BiometricIconType.fingerprint:
        _drawFingerprint(canvas, size, paint);
    }
  }

  void _drawCorners(Canvas canvas, Size size, Paint paint) {
    final inset = size.width * 0.08;
    final corner = size.width * 0.21;
    final arc = Rect.fromLTWH(inset, inset, corner, corner);

    canvas.drawArc(arc, math.pi, math.pi / 2, false, paint);
    canvas.drawArc(
      arc.shift(Offset(size.width - corner - inset * 2, 0)),
      -math.pi / 2,
      math.pi / 2,
      false,
      paint,
    );
    canvas.drawArc(
      arc.shift(Offset(0, size.height - corner - inset * 2)),
      math.pi / 2,
      math.pi / 2,
      false,
      paint,
    );
    canvas.drawArc(
      arc.shift(Offset(
        size.width - corner - inset * 2,
        size.height - corner - inset * 2,
      )),
      0,
      math.pi / 2,
      false,
      paint,
    );
  }

  void _drawFaceId(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;

    canvas.drawLine(
        Offset(w * 0.36, h * 0.35), Offset(w * 0.36, h * 0.43), paint);
    canvas.drawLine(
        Offset(w * 0.64, h * 0.35), Offset(w * 0.64, h * 0.43), paint);

    final nose = Path()
      ..moveTo(w * 0.50, h * 0.36)
      ..lineTo(w * 0.50, h * 0.55)
      ..quadraticBezierTo(w * 0.50, h * 0.61, w * 0.55, h * 0.61);
    canvas.drawPath(nose, paint);

    final smile = Path()
      ..moveTo(w * 0.34, h * 0.70)
      ..cubicTo(w * 0.42, h * 0.80, w * 0.58, h * 0.80, w * 0.66, h * 0.70);
    canvas.drawPath(smile, paint);
  }

  void _drawFingerprint(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.50, h * 0.57);

    final arcs = <({Rect rect, double start, double sweep})>[
      (
        rect:
            Rect.fromCenter(center: center, width: w * 0.64, height: h * 0.72),
        start: math.pi * 1.05,
        sweep: math.pi * 0.90,
      ),
      (
        rect:
            Rect.fromCenter(center: center, width: w * 0.52, height: h * 0.60),
        start: math.pi * 1.05,
        sweep: math.pi * 0.98,
      ),
      (
        rect:
            Rect.fromCenter(center: center, width: w * 0.40, height: h * 0.48),
        start: math.pi * 1.10,
        sweep: math.pi * 1.05,
      ),
      (
        rect:
            Rect.fromCenter(center: center, width: w * 0.28, height: h * 0.36),
        start: math.pi * 1.12,
        sweep: math.pi * 1.20,
      ),
    ];

    for (final arc in arcs) {
      canvas.drawArc(arc.rect, arc.start, arc.sweep, false, paint);
    }

    final inner = Path()
      ..moveTo(w * 0.50, h * 0.73)
      ..cubicTo(w * 0.59, h * 0.65, w * 0.59, h * 0.43, w * 0.50, h * 0.43)
      ..cubicTo(w * 0.39, h * 0.43, w * 0.39, h * 0.58, w * 0.43, h * 0.63)
      ..cubicTo(w * 0.46, h * 0.67, w * 0.43, h * 0.76, w * 0.35, h * 0.84);
    canvas.drawPath(inner, paint);

    final lower = Path()
      ..moveTo(w * 0.58, h * 0.82)
      ..cubicTo(w * 0.67, h * 0.69, w * 0.69, h * 0.49, w * 0.60, h * 0.35)
      ..cubicTo(w * 0.52, h * 0.23, w * 0.34, h * 0.25, w * 0.27, h * 0.38);
    canvas.drawPath(lower, paint);

    canvas.drawLine(
        Offset(w * 0.29, h * 0.55), Offset(w * 0.29, h * 0.64), paint);
    canvas.drawLine(
        Offset(w * 0.31, h * 0.75), Offset(w * 0.26, h * 0.83), paint);
  }

  @override
  bool shouldRepaint(covariant _BiometricIconPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
