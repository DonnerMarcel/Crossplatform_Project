// lib/widgets/dashboard/spinning_wheel.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import 'spinning_wheel_painter.dart'; // Import the painter

// Callback function type when spin completes
typedef SpinCompletionCallback = void Function(User selectedUser);

class SpinningWheel extends StatefulWidget {
  final List<User> users;
  final double totalGroupExpenses;
  final SpinCompletionCallback onSpinComplete;
  final Duration duration;
  final VoidCallback? onSpinStart;
  final bool autoSpin; // New flag to start spin automatically
  final double size; // Allow customizing size

  const SpinningWheel({
    super.key,
    required this.users,
    required this.totalGroupExpenses,
    required this.onSpinComplete,
    this.duration = const Duration(seconds: 4),
    this.onSpinStart,
    this.autoSpin = false, // Default to false
    this.size = 250, // Default size
  });

  @override
  State<SpinningWheel> createState() => _SpinningWheelState();
}

class _SpinningWheelState extends State<SpinningWheel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  List<SegmentData> _segments = [];
  User? _selectedUser;
  double _finalAngle = 0.0;
  bool _isSpinning = false;
  // Key to potentially force painter redraw if needed
  final GlobalKey _painterKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addStatusListener(_onAnimationStatusChanged);

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.decelerate, // Use a decelerating curve
      ),
    );

    _calculateSegments();

    // Auto spin if requested
    if (widget.autoSpin) {
      // Use addPostFrameCallback to ensure the first frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
         if (mounted) { // Ensure widget is still mounted
           spin();
         }
      });
    }
  }

  @override
  void didUpdateWidget(covariant SpinningWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recalculate segments if input data changes
    if (widget.users != oldWidget.users || widget.totalGroupExpenses != oldWidget.totalGroupExpenses) {
      _calculateSegments();
    }
    // Update animation duration if it changes
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
  }


  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (mounted) { // Check mounted before calling setState
          setState(() {
            _isSpinning = false;
          });
      }
      if (_selectedUser != null) {
        // Add a slight delay before calling callback to let user see result
        Future.delayed(const Duration(milliseconds: 500), () {
           if (mounted) { // Check again before calling callback
              widget.onSpinComplete(_selectedUser!);
           }
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _calculateSegments() {
    // ... (Calculation logic remains the same as before) ...
    if (widget.users.isEmpty) {
       if(mounted){ setState(() => _segments = []); } else { _segments = []; }
      return;
    }
    final List<SegmentData> calculatedSegments = [];
    double totalWeight = 0;
    final double fairShare = widget.totalGroupExpenses > 0 && widget.users.isNotEmpty
        ? widget.totalGroupExpenses / widget.users.length : 0;
    const double epsilon = 1.0;
    for (final user in widget.users) {
      final double amountBehind = max(0, fairShare - user.totalPaid);
      final double weight = amountBehind + epsilon;
      totalWeight += weight;
      calculatedSegments.add(SegmentData(
        user: user, weight: weight,
        color: user.profileColor ?? Colors.grey.shade300,
      ));
    }
    if (totalWeight <= epsilon * widget.users.length) {
      totalWeight = 0;
      for (int i = 0; i < calculatedSegments.length; i++) {
         final equalWeight = 10.0;
         calculatedSegments[i] = SegmentData(
            user: calculatedSegments[i].user, weight: equalWeight, color: calculatedSegments[i].color,
         );
         totalWeight += equalWeight;
      }
    }
    if(mounted){ setState(() { _segments = calculatedSegments; });
    } else { _segments = calculatedSegments; }
  }

  User? _selectWinner(double totalWeight) {
    // ... (Selection logic remains the same as before) ...
     if (widget.users.isEmpty || totalWeight <= 0 || _segments.isEmpty) return null;
    final randomValue = Random().nextDouble() * totalWeight;
    double cumulativeWeight = 0;
    for (final segment in _segments) {
      cumulativeWeight += segment.weight;
      if (randomValue <= cumulativeWeight) { return segment.user; }
    }
    return _segments.last.user;
  }

  double _calculateTargetAngle(User winner, double totalWeight) {
    // ... (Angle calculation remains the same as before) ...
      if (totalWeight <= 0 || _segments.isEmpty) return Random().nextDouble() * 2 * pi;
     double startAngle = 0;
     for (final segment in _segments) {
        final sweepAngle = (segment.weight / totalWeight) * 2 * pi;
        if (segment.user.id == winner.id) { return startAngle + sweepAngle / 2; }
        startAngle += sweepAngle;
     }
     return 0;
  }

  void spin() {
    if (_isSpinning || widget.users.isEmpty || !mounted) return;

    widget.onSpinStart?.call();

    final double currentTotalWeight = _segments.fold(0.0, (sum, seg) => sum + seg.weight);
    if (currentTotalWeight <= 0) {
       print("SpinningWheel: Cannot spin, total weight is zero or segments empty.");
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot determine weights for spinning.'))
       );
       return;
    }

    _selectedUser = _selectWinner(currentTotalWeight);
    if (_selectedUser == null) {
       print("SpinningWheel: Could not select a winner.");
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error selecting a participant.'))
       );
       return;
    }

    final targetAngle = _calculateTargetAngle(_selectedUser!, currentTotalWeight);
    final rotations = 5 + Random().nextDouble() * 3; // 5-8 rotations
    _finalAngle = rotations * 2 * pi + targetAngle;

    _controller.reset();
    _animation = Tween<double>(begin: 0, end: _finalAngle).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.decelerate, // Use decelerate curve
      ),
    );
     if (mounted) { // Check mounted before setState
        setState(() { _isSpinning = true; });
     }
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    // If segments haven't been calculated yet, show a placeholder
     if (_segments.isEmpty) {
       return SizedBox(
         width: widget.size,
         height: widget.size,
         child: const Center(child: CircularProgressIndicator()), // Or a placeholder message
       );
     }

    return SizedBox( // Constrain the size of the widget
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Wheel
          AnimatedBuilder(
              animation: _animation,
              key: _painterKey, // Assign key
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: SpinningWheelPainter( // Pass data to painter
                    segments: _segments,
                    totalWeight: _segments.fold(0.0, (sum, seg) => sum + seg.weight),
                  ),
                );
              }),

          // The Pointer/Arrow (Larger and styled)
          IgnorePointer( // Make pointer non-interactive
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                 return Transform.rotate(
                  angle: _animation.value,
                  child: child,
                );
              },
              child: CustomPaint( // Use CustomPaint for a nicer arrow
                  size: Size(widget.size * 0.15, widget.size * 0.4), // Adjust arrow size relative to wheel
                  painter: _ArrowPainter(),
              ),
              // --- Alternative: Icon based arrow ---
              // child: Transform.rotate(
              //   angle: pi / 2, // Point upwards initially if using play_arrow
              //   child: Icon(
              //     Icons.play_arrow, // A different icon shape
              //     size: widget.size * 0.25, // Larger size
              //     color: Colors.black.withOpacity(0.7),
              //     shadows: const [
              //       Shadow(color: Colors.black38, blurRadius: 5, offset: Offset(2, 2))
              //     ],
              //   ),
              // ),
            ),
          ),

          // Center pin (slightly styled)
          IgnorePointer(
            child: Container(
               width: widget.size * 0.08, // Relative size
               height: widget.size * 0.08,
               decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Colors.grey[500]!, Colors.grey[800]!],
                    center: Alignment(0.3, -0.3),
                  ),
                  shape: BoxShape.circle,
                  boxShadow: const [
                     BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(1,1))
                  ],
               ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Custom Painter for the Arrow ---
class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black.withOpacity(0.75)
      ..style = PaintingStyle.fill;

    final Path path = Path();
    // Simple triangle arrow shape pointing downwards from the center
    path.moveTo(size.width / 2, size.height); // Tip of the arrow at the bottom center
    path.lineTo(0, size.height * 0.3); // Top-left corner
    path.lineTo(size.width, size.height * 0.3); // Top-right corner
    path.close();

    // Add a subtle border or highlight (optional)
    final Paint borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}