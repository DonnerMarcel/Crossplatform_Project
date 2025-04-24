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
  final Duration duration; // How long the spin should take
  final VoidCallback? onSpinStart; // Optional callback when spin starts

  const SpinningWheel({
    super.key,
    required this.users,
    required this.totalGroupExpenses,
    required this.onSpinComplete,
    this.duration = const Duration(seconds: 4), // Default duration
    this.onSpinStart,
  });

  @override
  State<SpinningWheel> createState() => _SpinningWheelState();
}

class _SpinningWheelState extends State<SpinningWheel>
    with SingleTickerProviderStateMixin { // Need TickerProvider for AnimationController
  late AnimationController _controller;
  late Animation<double> _animation;
  // Store calculated segments and selected user
  List<SegmentData> _segments = [];
  User? _selectedUser;
  double _finalAngle = 0.0; // The target angle the arrow should point to
  bool _isSpinning = false;

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
        curve: Curves.easeOutCubic, // Adjust curve for desired effect
      ),
    );

    _calculateSegments(); // Calculate segments initially
  }

   // Recalculate segments if the input users or expenses change
   @override
  void didUpdateWidget(covariant SpinningWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.users != oldWidget.users || widget.totalGroupExpenses != oldWidget.totalGroupExpenses) {
      _calculateSegments();
    }
  }


  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _isSpinning = false; // Stop spinning state
      });
      if (_selectedUser != null) {
        widget.onSpinComplete(_selectedUser!); // Callback with the result
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- Calculate Segment Weights and Data ---
  void _calculateSegments() {
    if (widget.users.isEmpty) {
       if(mounted){ // Check if widget is still in the tree
         setState(() => _segments = []);
       } else {
         _segments = [];
       }
      return;
    }

    final List<SegmentData> calculatedSegments = [];
    double totalWeight = 0;
    final double fairShare = widget.totalGroupExpenses > 0 && widget.users.isNotEmpty
        ? widget.totalGroupExpenses / widget.users.length
        : 0;
    const double epsilon = 1.0; // Small base weight to ensure everyone has a chance

    for (final user in widget.users) {
      // Weight based on how much user is behind, plus epsilon
      final double amountBehind = max(0, fairShare - user.totalPaid);
      final double weight = amountBehind + epsilon;
      totalWeight += weight;

      calculatedSegments.add(SegmentData(
        user: user,
        weight: weight,
        // Use user's profile color or a default
        color: user.profileColor ?? Colors.grey.shade300,
      ));
    }

    // Handle case where totalWeight is zero (everyone paid >= fair share)
    if (totalWeight <= epsilon * widget.users.length) {
      print("SpinningWheel: All users paid fair share or more. Using equal weights.");
      totalWeight = 0; // Reset for recalculation
      // Assign equal weight to everyone
      for (int i = 0; i < calculatedSegments.length; i++) {
         final equalWeight = 10.0; // Arbitrary equal weight
         calculatedSegments[i] = SegmentData(
            user: calculatedSegments[i].user,
            weight: equalWeight,
            color: calculatedSegments[i].color,
         );
         totalWeight += equalWeight;
      }
    }

    if(mounted){ // Check if widget is still in the tree
      setState(() {
        _segments = calculatedSegments;
      });
    } else {
       _segments = calculatedSegments;
    }
  }

  // --- Select Winner Based on Weights ---
  User? _selectWinner(double totalWeight) {
    if (widget.users.isEmpty || totalWeight <= 0 || _segments.isEmpty) return null;

    final randomValue = Random().nextDouble() * totalWeight;
    double cumulativeWeight = 0;

    // Use the current _segments state
    for (final segment in _segments) {
      cumulativeWeight += segment.weight;
      if (randomValue <= cumulativeWeight) {
        return segment.user;
      }
    }
    // Fallback (shouldn't happen with correct logic)
    print("SpinningWheel Warning: Winner selection fallback triggered.");
    return _segments.last.user;
  }

  // --- Calculate Target Angle for Winner ---
  double _calculateTargetAngle(User winner, double totalWeight) {
     if (totalWeight <= 0 || _segments.isEmpty) return Random().nextDouble() * 2 * pi; // Random angle if no weights

     double startAngle = 0; // Relative start angle
     // Use the current _segments state
     for (final segment in _segments) {
        final sweepAngle = (segment.weight / totalWeight) * 2 * pi;
        if (segment.user.id == winner.id) {
          // Target the middle of the segment
          return startAngle + sweepAngle / 2;
        }
        startAngle += sweepAngle;
     }
     print("SpinningWheel Warning: Target angle calculation fallback triggered.");
     return 0; // Fallback
  }

  // --- Start the Spin Animation ---
  void spin() {
    if (_isSpinning || widget.users.isEmpty) return; // Prevent re-spin while spinning

    widget.onSpinStart?.call(); // Notify spin start

    // Ensure segments are up-to-date (already handled by didUpdateWidget/initState)
    final double currentTotalWeight = _segments.fold(0.0, (sum, seg) => sum + seg.weight);

    if (currentTotalWeight <= 0) {
       print("SpinningWheel: Cannot spin, total weight is zero or segments empty.");
       // Optionally show a message to the user
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

    // Calculate final angle: multiple rotations + target angle
    final rotations = 5 + Random().nextDouble() * 2; // 5-7 rotations
    // Adjust angle slightly to avoid landing exactly on lines? (Optional)
    // final slightOffset = (Random().nextDouble() - 0.5) * 0.05; // Small random offset
    _finalAngle = rotations * 2 * pi + targetAngle; // + slightOffset;

    // Reset controller and start animation
    _controller.reset();
    // Use the calculated final angle
    _animation = Tween<double>(begin: 0, end: _finalAngle).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
    if(mounted){
      setState(() {
        _isSpinning = true; // Set spinning state
      });
    }
    _controller.forward();
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 250, // Adjust size as needed
          height: 250,
          child: Stack( // Use Stack to overlay arrow on wheel
            alignment: Alignment.center,
            children: [
              // The Wheel itself
              AnimatedBuilder(
                  animation: _animation, // Listen to animation for rotation if needed
                  builder: (context, child) {
                    // Wheel painter doesn't need to react to animation value itself
                    return CustomPaint(
                      size: Size.infinite,
                      painter: SpinningWheelPainter(
                        segments: _segments, // Use current segments state
                        totalWeight: _segments.fold(0.0, (sum, seg) => sum + seg.weight),
                      ),
                    );
                  }),

              // The Spinning Arrow/Pointer
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                   return Transform.rotate(
                    angle: _animation.value, // Rotate based on animation value
                    child: child,
                  );
                },
                child: Icon(
                  Icons.arrow_right_alt,
                  size: 50,
                  color: Colors.black.withOpacity(0.8),
                   shadows: const [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(1,1))],
                ),
              ),

              // Center pin (optional)
              Container(
                 width: 15,
                 height: 15,
                 decoration: BoxDecoration(
                    color: Colors.grey[700],
                    shape: BoxShape.circle,
                    // --- FIX: Use BoxShadow here ---
                    boxShadow: const [
                       BoxShadow(
                         color: Colors.black45,
                         blurRadius: 3,
                         offset: Offset(1,1) // BoxShadow needs offset
                       )
                    ],
                 ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // The Spin Button
        ElevatedButton.icon(
          icon: const Icon(Icons.casino_outlined),
          label: Text(_isSpinning ? 'Spinning...' : 'Who Pays Next?'),
          onPressed: _isSpinning ? null : spin,
          style: ElevatedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            backgroundColor: Theme.of(context).colorScheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
            textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
          ),
        ),
         // Display last selected payer (optional)
         if (!_isSpinning && _selectedUser != null)
           Padding(
             padding: const EdgeInsets.only(top: 12.0),
             child: Text(
               'Landed on: ${_selectedUser!.name}',
               textAlign: TextAlign.center,
               style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
           ),
      ],
    );
  }
}