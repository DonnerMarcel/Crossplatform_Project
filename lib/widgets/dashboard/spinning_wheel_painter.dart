// lib/widgets/dashboard/spinning_wheel_painter.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/models.dart'; // Assuming models are here

// Defines data needed for each segment
class SegmentData {
  final User user;
  final double weight; // The calculated weight determining segment size
  final Color color;

  SegmentData({required this.user, required this.weight, required this.color});
}

class SpinningWheelPainter extends CustomPainter {
  final List<SegmentData> segments;
  final double totalWeight;

  SpinningWheelPainter({required this.segments, required this.totalWeight});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) * 0.9; // 90% of available radius
    final segmentPaint = Paint();
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    final textStyle = TextStyle(
      color: Colors.black87, // Or calculate contrast color
      fontSize: radius * 0.1, // Adjust font size relative to radius
      fontWeight: FontWeight.bold,
    );

    double startAngle = -pi / 2; // Start drawing from the top

    if (totalWeight <= 0) {
      // Handle case with no weights (e.g., draw empty circle or placeholder)
      segmentPaint.color = Colors.grey[300]!;
      segmentPaint.style = PaintingStyle.stroke;
      segmentPaint.strokeWidth = 2;
      canvas.drawCircle(center, radius, segmentPaint);
      textPainter.text = const TextSpan(text: "?", style: TextStyle(fontSize: 40, color: Colors.grey));
      textPainter.layout();
      textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));
      return;
    }

    for (final segment in segments) {
      final sweepAngle = (segment.weight / totalWeight) * 2 * pi;
      segmentPaint.color = segment.color;
      segmentPaint.style = PaintingStyle.fill;

      // Draw the segment arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true, // Use center
        segmentPaint,
      );

      // --- Draw Text (User Initials) ---
      // Calculate angle for the middle of the segment for text placement
      final textAngle = startAngle + sweepAngle / 2;
      // Calculate position slightly inwards from the outer edge
      final textRadius = radius * 0.75;
      final textX = center.dx + textRadius * cos(textAngle);
      final textY = center.dy + textRadius * sin(textAngle);
      final textOffset = Offset(textX, textY);

      textPainter.text = TextSpan(text: segment.user.initials, style: textStyle);
      textPainter.layout();

      // Rotate canvas to draw text upright relative to the segment center
      canvas.save();
      canvas.translate(textOffset.dx, textOffset.dy);
      // Rotate slightly more than angle to align baseline horizontally-ish
      canvas.rotate(textAngle + pi / 2);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();


      // --- Draw separator lines (optional) ---
      final linePaint = Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..strokeWidth = 1.5;
      final lineEndX = center.dx + radius * cos(startAngle);
      final lineEndY = center.dy + radius * sin(startAngle);
      canvas.drawLine(center, Offset(lineEndX, lineEndY), linePaint);


      startAngle += sweepAngle; // Move to the next segment's start angle
    }

     // Draw outer border (optional)
      final borderPaint = Paint()
        ..color = Colors.grey[400]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // Repaint if segments change (usually they won't after initial calculation)
    return oldDelegate is! SpinningWheelPainter || oldDelegate.segments != segments;
  }
}