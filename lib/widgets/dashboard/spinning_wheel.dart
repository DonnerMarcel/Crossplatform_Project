import 'dart:math';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import '../../models/models.dart';
import 'spinning_wheel_painter.dart';

// Callback function type when spin completes
typedef SpinCompletionCallback = void Function(User selectedUser);

class SpinningWheel extends StatefulWidget {
  final List<User> users;
  final double totalGroupExpenses;
  final SpinCompletionCallback onSpinComplete;
  final Duration duration;
  final VoidCallback? onSpinStart;
  final bool autoSpin;
  final double size;

  const SpinningWheel({
    super.key,
    required this.users,
    required this.totalGroupExpenses,
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
        curve: Curves.decelerate,
      ),
    );

    // Initial calculation
    _calculateSegments();

    if (widget.autoSpin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
         if (mounted) { spin(); }
      });
    }
  }

  @override
  void didUpdateWidget(covariant SpinningWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool usersChanged = !ListEquality().equals(widget.users.map((u) => u.id).toList(), oldWidget.users.map((u) => u.id).toList()) ||
                        !ListEquality().equals(widget.users.map((u) => u.totalPaid).toList(), oldWidget.users.map((u) => u.totalPaid).toList());

    if (usersChanged) {
       print("SpinningWheel: User data changed, recalculating segments.");
      _calculateSegments();
    }
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (mounted) { setState(() { _isSpinning = false; }); }
      if (_selectedUser != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
           if (mounted) { widget.onSpinComplete(_selectedUser!); }
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- Calculate Segment Weights using the new Algorithm ---
  void _calculateSegments() {
    if (widget.users.isEmpty) {
      if(mounted){ setState(() => _segments = []); } else { _segments = []; }
      return;
    }

    final List<SegmentData> calculatedSegments = [];
    double calculatedTotalWeight = 0;
    final double hysteresis = 200.0;
    print("SpinningWheel: Using Hysteresis: $hysteresis");

    // 1. Find highest sum paid
    final double highestSum = widget.users.map((u) => u.totalPaid).reduce(max);
    print("SpinningWheel: Highest sum paid: $highestSum");

    // 2. Identify outliers (paid less than highest - hysteresis)
    final List<User> outliers = widget.users.where((user) {
      return user.totalPaid < (highestSum - hysteresis);
    }).toList();

    // 3. Determine participants for weight calculation
    final List<User> participants;
    if (outliers.isNotEmpty) {
      participants = outliers;
      print("SpinningWheel: Outliers detected: ${participants.map((u) => '${u.name} (${u.totalPaid.toStringAsFixed(2)})').toList()}");
    } else {
      participants = List.from(widget.users); // Use a copy
      print("SpinningWheel: No significant outliers, using all users.");
    }

    // Safety check if somehow participants list ends up empty
    if (participants.isEmpty) {
      print("SpinningWheel Warning: No participants selected after outlier check. Defaulting to all users.");
      participants.addAll(widget.users);
       if (participants.isEmpty) { // Still empty? (Only if widget.users was empty initially)
         if(mounted){ setState(() => _segments = []); } else { _segments = []; }
         return;
      }
    }

    // 4. Calculate Weights
    final double xMin = participants.map((u) => u.totalPaid).reduce(min);
    print("SpinningWheel: Minimum sum among participants (Xmin): $xMin");

    // d) Calculate Weight = Hysteresis - (Xu - Xmin) for each *original* user
    //    Only assign weight if the user is in the 'participants' list.
    for (final user in widget.users) {
      double weight = 0;
      // Check if this user is part of the group selected for calculation
      if (participants.any((p) => p.id == user.id)) {
        weight = max(0, hysteresis - (user.totalPaid - xMin)); // Ensure weight >= 0
      }

      calculatedSegments.add(SegmentData(
        user: user,
        weight: weight,
        color: user.profileColor ?? Colors.grey.shade300,
      ));
      calculatedTotalWeight += weight;
    }

    // Safety check: If total weight is 0 (e.g., one participant exactly at hysteresis boundary)
    // assign equal weight to all participants as fallback.
    if (calculatedTotalWeight <= 0 && participants.isNotEmpty) {
       print("SpinningWheel Warning: Calculated total weight is zero. Assigning equal weights to participants.");
       calculatedTotalWeight = 0; // Reset
       calculatedSegments.clear(); // Clear previous weights
       final double equalWeight = 10.0;
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

    // Update the state with the newly calculated segments
    if(mounted){
      setState(() { _segments = calculatedSegments; });
    } else {
      _segments = calculatedSegments;
    }
      print("SpinningWheel: Segments calculated. Total Weight: $calculatedTotalWeight");
    }


  // --- Select Winner Based on Weights --- (Logic remains the same)
  User? _selectWinner(double totalWeight) {
    if (widget.users.isEmpty || totalWeight <= 0 || _segments.isEmpty) return null;
    final randomValue = Random().nextDouble() * totalWeight;
    double cumulativeWeight = 0;
    for (final segment in _segments) {
      cumulativeWeight += segment.weight;
      if (randomValue <= cumulativeWeight) { return segment.user; }
    }
    print("SpinningWheel Warning: Winner selection fallback triggered.");
    return _segments.last.user;
  }

  // --- Calculate Target Angle for Winner --- (Logic remains the same)
  double _calculateTargetAngle(User winner, double totalWeight) {
     if (totalWeight <= 0 || _segments.isEmpty) return Random().nextDouble() * 2 * pi;
     double startAngle = 0;
     for (final segment in _segments) {
        final sweepAngle = (segment.weight / totalWeight) * 2 * pi;
        if (segment.user.id == winner.id) { return startAngle + sweepAngle / 2; }
        startAngle += sweepAngle;
     }
     print("SpinningWheel Warning: Target angle calculation fallback triggered.");
     return 0;
  }

  // --- Start the Spin Animation --- (Logic remains the same)
  void spin() {
    if (_isSpinning || widget.users.isEmpty || !mounted) return;
    widget.onSpinStart?.call();

    // Use the current segments state for weight calculation
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
    final rotations = 5 + Random().nextDouble() * 3;
    _finalAngle = rotations * 2 * pi + targetAngle;

    _controller.reset();
    _animation = Tween<double>(begin: 0, end: _finalAngle).animate(
      CurvedAnimation(parent: _controller, curve: Curves.decelerate),
    );
     if (mounted) { setState(() { _isSpinning = true; }); }
    _controller.forward();
  }


  // --- Build Method --- (Remains the same as the enhanced version)
  @override
  Widget build(BuildContext context) {
     if (_segments.isEmpty && widget.users.isNotEmpty) { // Show loading only if users exist but segments aren't ready
       return SizedBox(
         width: widget.size,
         height: widget.size,
         child: const Center(child: CircularProgressIndicator()),
       );
     }
     if (widget.users.isEmpty){ // Handle case where no users are passed in
        return SizedBox(
         width: widget.size,
         height: widget.size,
         child: const Center(child: Text("No users in group.", style: TextStyle(color: Colors.grey))),
       );
     }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Wheel
          AnimatedBuilder(
              animation: _animation,
              key: _painterKey,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: SpinningWheelPainter(
                    segments: _segments, // Use current segments state
                    totalWeight: _segments.fold(0.0, (sum, seg) => sum + seg.weight),
                  ),
                );
              }),
          // The Pointer/Arrow
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                 return Transform.rotate(
                  angle: _animation.value,
                  child: child,
                );
              },
              child: CustomPaint(
                  size: Size(widget.size * 0.15, widget.size * 0.4),
                  painter: _ArrowPainter(),
              ),
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

// --- Custom Painter for the Arrow --- (Remains the same)
class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black.withOpacity(0.75)
      ..style = PaintingStyle.fill;
    final Path path = Path();
    path.moveTo(size.width / 2, size.height);
    path.lineTo(0, size.height * 0.3);
    path.lineTo(size.width, size.height * 0.3);
    path.close();
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