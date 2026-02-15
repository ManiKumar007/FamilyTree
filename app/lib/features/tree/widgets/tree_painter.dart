import 'package:flutter/material.dart';

/// Custom painter that draws family tree connection lines:
/// - Horizontal lines for spouse connections
/// - Vertical lines from parents to children
/// - Horizontal brackets connecting siblings
class TreeLinePainter extends CustomPainter {
  final List<ConnectionLine> lines;

  TreeLinePainter({required this.lines});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final line in lines) {
      if (line.type == LineType.straight) {
        canvas.drawLine(line.start, line.end, paint);
      } else if (line.type == LineType.elbow) {
        // Draw an elbow connector (vertical down, then horizontal)
        final midY = (line.start.dy + line.end.dy) / 2;
        final path = Path()
          ..moveTo(line.start.dx, line.start.dy)
          ..lineTo(line.start.dx, midY)
          ..lineTo(line.end.dx, midY)
          ..lineTo(line.end.dx, line.end.dy);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant TreeLinePainter oldDelegate) {
    return lines != oldDelegate.lines;
  }
}

enum LineType { straight, elbow }

class ConnectionLine {
  final Offset start;
  final Offset end;
  final LineType type;

  const ConnectionLine({
    required this.start,
    required this.end,
    this.type = LineType.straight,
  });
}
