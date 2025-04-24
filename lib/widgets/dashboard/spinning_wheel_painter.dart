
// lib/widgets/dashboard/spinning_wheel_painter.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/models.dart';

// Defines data needed for each segment
class SegmentData {
  final User user;
  final double weight;
  final Color color;

  SegmentData({required this.user, required this.weight, required this.color});
}

class SpinningWheelPainter extends CustomPainter {
  final List<SegmentData> segments;
  final double totalWeight;

  SpinningWheelPainter({required this.segments, required this.totalWeight});

  // Helper to determine text color based on background luminance
  Color getTextColor(Color backgroundColor) {
    // Calculate luminance (0.0 black to 1.0 white)
    double luminance = backgroundColor.computeLuminance();
    // Use white text on dark backgrounds, black text on light backgrounds
    return luminance > 0.4 ? Colors.black87 : Colors.white;
  }


  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) * 0.95; // Use slightly more radius
    final segmentPaint = Paint();
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );


    double startAngle = -pi / 2; // Start from top

    if (totalWeight <= 0 || segments.isEmpty) {
      // Draw placeholder if no segments/weight
      segmentPaint.color = Colors.grey[200]!;
      segmentPaint.style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, segmentPaint);
       segmentPaint.color = Colors.grey[400]!;
       segmentPaint.style = PaintingStyle.stroke;
       segmentPaint.strokeWidth = 1;
       canvas.drawCircle(center, radius, segmentPaint);
      textPainter.text = TextSpan(text: "?", style: TextStyle(fontSize: size.width * 0.2, color: Colors.grey[500]));
      textPainter.layout();
      textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));
      return;
    }

    // --- Draw Segments and Text ---
    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final sweepAngle = (segment.weight / totalWeight) * 2 * pi;
      final endAngle = startAngle + sweepAngle;

      // Base segment color
      segmentPaint.color = segment.color;
      segmentPaint.style = PaintingStyle.fill;

      // --- Optional: Add Gradient for depth ---
       Rect rect = Rect.fromCircle(center: center, radius: radius);
       final Gradient gradient = RadialGradient(
         center: Alignment.center, // Center the gradient
         radius: 0.8, // Adjust radius effect
         colors: [
           segment.color.withOpacity(0.85), // Lighter inner color
           segment.color, // Original outer color
         ],
         stops: const [0.0, 1.0], // Gradient stops
       );
       segmentPaint.shader = gradient.createShader(rect);


      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        true, // Use center
        segmentPaint,
      );
       segmentPaint.shader = null; // Clear shader for next elements

      // --- Draw Text (User Initials) ---
      final textColor = getTextColor(segment.color); // Get contrast color
      final textStyle = TextStyle(
        color: textColor,
        fontSize: radius * 0.12, // Slightly larger text
        fontWeight: FontWeight.bold,
        shadows: const [ // Add subtle shadow for better readability
           Shadow(color: Colors.black26, blurRadius: 2, offset: Offset(1,1))
        ]
      );

      final textAngle = startAngle + sweepAngle / 2;
      final textRadius = radius * 0.7; // Position text slightly more inwards
      final textX = center.dx + textRadius * cos(textAngle);
      final textY = center.dy + textRadius * sin(textAngle);
      final textOffset = Offset(textX, textY);

      textPainter.text = TextSpan(text: segment.user.initials, style: textStyle);
      textPainter.layout();

      canvas.save();
      canvas.translate(textOffset.dx, textOffset.dy);
      canvas.rotate(textAngle + pi / 2); // Rotate text to be upright
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();

      startAngle = endAngle; // Move to next segment
    }

    // --- Draw Separator Lines ---
    startAngle = -pi / 2; // Reset start angle for lines
    final linePaint = Paint()
        ..color = Colors.white.withOpacity(0.6) // Brighter lines
        ..strokeWidth = 1.0 // Thinner lines
        ..style = PaintingStyle.stroke;

    for (int i = 0; i < segments.length; i++) {
       final segment = segments[i];
       final sweepAngle = (segment.weight / totalWeight) * 2 * pi;
       final lineAngle = startAngle + sweepAngle;

       // Only draw line if sweepAngle is not the full circle (i.e., more than one segment)
       if (segments.length > 1) {
          final lineEndX = center.dx + radius * cos(lineAngle);
          final lineEndY = center.dy + radius * sin(lineAngle);
          canvas.drawLine(center, Offset(lineEndX, lineEndY), linePaint);
       }
       startAngle += sweepAngle;
    }

    // --- Draw Outer Border ---
     final borderPaint = Paint()
       ..color = Colors.grey.withOpacity(0.5)
       ..style = PaintingStyle.stroke
       ..strokeWidth = 3; // Slightly thicker border
     canvas.drawCircle(center, radius, borderPaint);

  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // Repaint if segments or totalWeight change
     if (oldDelegate is SpinningWheelPainter) {
      return oldDelegate.segments != segments || oldDelegate.totalWeight != totalWeight;
    }
    return true;
  }
}