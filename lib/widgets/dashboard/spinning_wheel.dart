import 'dart:math';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import '../../models/models.dart'; // Assuming User model is here
import '../../utils/constants.dart';
import 'spinning_wheel_painter.dart';

// Callback function type when spin completes
typedef SpinCompletionCallback = void Function(User selectedUser);

class SpinningWheel extends StatefulWidget {
  final List<User> users;
  // final double totalGroupExpenses; // REMOVED
  final double averageExpenseAmount; // NEW: Average amount of a single expense item
  final SpinCompletionCallback onSpinComplete;
  final Duration duration;
  final VoidCallback? onSpinStart;
  final bool autoSpin;
  final double size;

  const SpinningWheel({
    super.key,
    required this.users,
    required this.averageExpenseAmount, // NEW
    required this.onSpinComplete,
    this.duration = const Duration(seconds: 4),
    this.onSpinStart,
    this.autoSpin = false,
    this.size = 250,
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
  // final GlobalKey _painterKey = GlobalKey(); // _painterKey is not used in the provided build method

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
        curve: Curves.decelerate,
      ),
    );

    _calculateSegments();

    if (widget.autoSpin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          spin();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant SpinningWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool usersChanged = !ListEquality().equals(
            widget.users.map((u) => u.id).toList(),
            oldWidget.users.map((u) => u.id).toList()) ||
        !ListEquality().equals(
            widget.users.map((u) => u.totalPaid ?? 0.0).toList(), // Handle null
            oldWidget.users.map((u) => u.totalPaid ?? 0.0).toList()); // Handle null

    // Also check if averageExpenseAmount changed, as it affects Hysteresis
    if (usersChanged || widget.averageExpenseAmount != oldWidget.averageExpenseAmount) {
      print("SpinningWheel: User data or averageExpenseAmount changed, recalculating segments.");
      _calculateSegments();
    }
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (mounted) {
        setState(() {
          _isSpinning = false;
        });
      }
      if (_selectedUser != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
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
    if (widget.users.isEmpty) {
      if (mounted) {
        setState(() => _segments = []);
      } else {
        _segments = [];
      }
      return;
    }

    final List<SegmentData> calculatedSegments = [];
    double calculatedTotalWeight = 0;

    // --- CORRECTED Hysteresis Calculation ---
    double baseHysteresisValue = widget.averageExpenseAmount > 0
        ? widget.averageExpenseAmount
        : 20; // defaultPortionCost from constants.dart
    double hysteresis = baseHysteresisValue * 2.0;

    // Ensure hysteresis has a sensible minimum value
    double minHysteresis = 10.0; // Absolute minimum
    if (widget.users.isNotEmpty) {
        // Example: 20% of default cost for one round per user, or 10, whichever is higher
        minHysteresis = max(minHysteresis, (20 * widget.users.length * 0.2));
    }
    hysteresis = max(hysteresis, minHysteresis);
    // --- END Hysteresis Calculation ---

    print("SpinningWheel: Using Hysteresis: $hysteresis (from avgExpense: ${widget.averageExpenseAmount}, defaultPortionCost: 20.00€)");

    // 1. Find highest sum paid (Xmax)
    final double highestSum = widget.users
        .map((u) => u.totalPaid ?? 0.0) // Handle null totalPaid
        .fold(0.0, max); // Use fold with initial value for empty list safety, though users.isEmpty is checked
    print("SpinningWheel: Highest sum paid (Xmax): $highestSum");

    // 2. Identify outliers
    final List<User> outliers = widget.users.where((user) {
      return (user.totalPaid ?? 0.0) < (highestSum - hysteresis);
    }).toList();

    // 3. Determine participants for weight calculation
    final List<User> participants;
    if (outliers.isNotEmpty) {
      participants = outliers;
      print("SpinningWheel: Outliers detected: ${participants.map((u) => '${u.name} (${(u.totalPaid ?? 0.0).toStringAsFixed(2)})').toList()}");
    } else {
      participants = List.from(widget.users);
      print("SpinningWheel: No significant outliers, using all users as participants.");
    }

    if (participants.isEmpty && widget.users.isNotEmpty) {
      // This case might happen if all users are clustered and hysteresis is very large,
      // making no one an "outlier" but also no one qualifying if some other condition failed.
      // Or if all users have paid exactly the same.
      // Fallback: if participants is empty but widget.users is not, use all users.
      print("SpinningWheel Warning: Participants list empty after outlier check, though users exist. Defaulting to all users.");
      participants.addAll(widget.users);
    }
    
    if (participants.isEmpty) { // If still empty (only if widget.users was initially empty)
        if (mounted) { setState(() => _segments = []); } else { _segments = []; }
        return;
    }


    // 4. Find Xmin among participants
    final double xMin = participants
        .map((u) => u.totalPaid ?? 0.0) // Handle null
        .fold(double.infinity, min); // Use fold for safety with empty list (though participants.isEmpty is checked)
    print("SpinningWheel: Minimum sum among participants (Xmin): $xMin");

    // 7. Calculate Weights
    for (final user in widget.users) {
      double weight = 0;
      if (participants.any((p) => p.id == user.id)) {
        weight = max(0, hysteresis - ((user.totalPaid ?? 0.0) - xMin));
      }
      calculatedSegments.add(SegmentData(
        user: user,
        weight: weight,
        color: user.profileColor ?? Colors.grey.shade300,
      ));
      calculatedTotalWeight += weight;
    }

    // Fallback if total weight is 0 (e.g., all participants have same weight-determining factors)
    if (calculatedTotalWeight <= 0 && participants.isNotEmpty) {
      print("SpinningWheel Warning: Calculated total weight is zero. Assigning equal weights to participants.");
      calculatedTotalWeight = 0;
      calculatedSegments.clear();
      final double equalWeight = 10.0; // Assign a nominal positive weight
      for (final user in widget.users) {
        double weight = 0;
        if (participants.any((p) => p.id == user.id)) {
          weight = equalWeight;
          calculatedTotalWeight += weight;
        }
        calculatedSegments.add(SegmentData(
          user: user,
          weight: weight,
          color: user.profileColor ?? Colors.grey.shade300,
        ));
      }
    }

    if (mounted) {
      setState(() {
        _segments = calculatedSegments;
      });
    } else {
      _segments = calculatedSegments;
    }
    print("SpinningWheel: Segments calculated. Total Weight: $calculatedTotalWeight. Segments count: ${_segments.length}");
  }

  User? _selectWinner(double totalWeight) {
    if (_segments.isEmpty || totalWeight <= 0) {
      // If no valid segments/weights, pick a random user from all available users
      if (widget.users.isNotEmpty) {
        print("SpinningWheel Warning: No valid weights for selection, picking random user.");
        return widget.users[Random().nextInt(widget.users.length)];
      }
      return null;
    }
    final randomValue = Random().nextDouble() * totalWeight;
    double cumulativeWeight = 0;
    for (final segment in _segments) {
      cumulativeWeight += segment.weight;
      if (randomValue <= cumulativeWeight) {
        return segment.user;
      }
    }
    // Fallback, should ideally not be reached if logic is correct and totalWeight > 0
    print("SpinningWheel Warning: Winner selection fallback triggered (end of loop).");
    return _segments.isNotEmpty ? _segments.last.user : (widget.users.isNotEmpty ? widget.users.first : null) ;
  }

  double _calculateTargetAngle(User winner, double totalWeight) {
    if (totalWeight <= 0 || _segments.isEmpty) {
      // If no weights, pick a random angle
      return Random().nextDouble() * 2 * pi;
    }
    double startAngle = 0;
    for (final segment in _segments) {
      final sweepAngle = (segment.weight / totalWeight) * 2 * pi;
      if (segment.user.id == winner.id) {
        // Target the middle of the winner's segment
        return startAngle + (sweepAngle / 2);
      }
      startAngle += sweepAngle;
    }
    // Fallback if winner not found in segments (should not happen if _selectWinner is correct)
    print("SpinningWheel Warning: Target angle calculation fallback triggered (winner not in segments).");
    return Random().nextDouble() * 2 * pi; // Random angle
  }

  void spin() {
    if (_isSpinning || !mounted) return;
     if (widget.users.isEmpty) {
      print("SpinningWheel: Cannot spin, no users.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No users in the group to spin for.'))
      );
      return;
    }
    // Ensure segments are calculated before spinning, especially if autoSpin is false and spin is called externally
    if (_segments.isEmpty && widget.users.isNotEmpty) {
        _calculateSegments(); // Attempt to calculate if empty
    }
    if (_segments.isEmpty) { // Still empty after trying
        print("SpinningWheel: Cannot spin, segments could not be calculated.");
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not determine participants for spinning.'))
        );
        return;
    }


    widget.onSpinStart?.call();

    final double currentTotalWeight = _segments.fold(0.0, (sum, seg) => sum + seg.weight);

    _selectedUser = _selectWinner(currentTotalWeight);
    if (_selectedUser == null) {
      print("SpinningWheel: Could not select a winner (currentTotalWeight: $currentTotalWeight).");
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error selecting a participant to pay.')));
      return;
    }

    final targetAngle = _calculateTargetAngle(_selectedUser!, currentTotalWeight);
    // Add more randomness to spins, ensure it always spins a noticeable amount
    final rotations = 5 + Random().nextInt(5); // 5 to 9 full rotations
    _finalAngle = (rotations * 2 * pi) + targetAngle;

    _controller.reset();
    // Ensure the animation always has a non-zero range if _finalAngle is 0
    _animation = Tween<double>(begin: 0, end: _finalAngle == 0 ? 0.001 : _finalAngle).animate(
      CurvedAnimation(parent: _controller, curve: Curves.decelerate),
    );
    if (mounted) {
      setState(() {
        _isSpinning = true;
      });
    }
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator if segments are not yet calculated but users are present
    if (_segments.isEmpty && widget.users.isNotEmpty && !_isSpinning) {
      // This might happen if _calculateSegments is slow or called asynchronously initially.
      // For now, it's called synchronously in initState and didUpdateWidget.
      // If it were async, a loading state would be more relevant here.
      // Given current sync logic, this state might be very brief or not hit often.
    }
    if (widget.users.isEmpty) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(
            child: Text("No users.", style: TextStyle(color: Colors.grey))),
      );
    }

    return GestureDetector( // Allow tapping the wheel to spin
      onTap: _isSpinning ? null : spin,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
                animation: _animation,
                // key: _painterKey, // Not used
                builder: (context, child) {
                  return Transform.rotate( // Rotate the painter directly
                    angle: _animation.value,
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: SpinningWheelPainter(
                        segments: _segments,
                        totalWeight: _segments.fold(0.0, (sum, seg) => sum + seg.weight),
                      ),
                    ),
                  );
                }),
            // The Pointer/Arrow (Static)
            IgnorePointer(
              child: CustomPaint(
                size: Size(widget.size * 0.1, widget.size * 0.15), // Adjusted size for a typical pointer
                painter: _ArrowPainter(), // Static pointer
              ),
            ),
            // Center pin
            IgnorePointer(
              child: Container(
                width: widget.size * 0.08,
                height: widget.size * 0.08,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Colors.grey[500]!, Colors.grey[800]!],
                    center: const Alignment(0.3, -0.3),
                  ),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        offset: Offset(1, 1))
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for the Arrow (Static Pointer)
class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black.withOpacity(0.85) // Slightly darker
      ..style = PaintingStyle.fill;

    final Path path = Path();
    // Pointing downwards from the top center
    path.moveTo(size.width / 2, 0); // Top center point of the arrow
    path.lineTo(0, size.height * 0.6); // Bottom-left point
    path.lineTo(size.width, size.height * 0.6); // Bottom-right point
    path.close();

    final Paint borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// SegmentData class (ensure it's defined, typically with SpinningWheelPainter)
// If not already defined with SpinningWheelPainter, add it here or import it.
/*
class SegmentData {
  final User user;
  final double weight;
  final Color color;

  SegmentData({required this.user, required this.weight, required this.color});
}
*/
