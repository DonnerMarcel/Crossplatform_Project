// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'dart:math'; // For Random number generation in _spinWheel
import 'package:collection/collection.dart'; // For '.sorted()' method on lists

// Corrected Imports based on the provided structure:
import '../models/models.dart';                     // OK: ../models/models.dart
import '../utils/formatters.dart';                  // OK: ../utils/formatters.dart
import '../widgets/dashboard/user_balance_card.dart'; // OK: ../widgets/dashboard/user_balance_card.dart
import '../widgets/history/expense_card.dart';      // CORRECTED: ../widgets/history/expense_card.dart

// Define a type for the callback function for better readability
typedef AddExpenseCallback = void Function({String? preselectedPayerId});


class DashboardScreen extends StatefulWidget {
  final PaymentGroup group;
  // ADD THIS: Callback function parameter
  final AddExpenseCallback onAddExpenseRequested;

  const DashboardScreen({
    super.key,
    required this.group,
    required this.onAddExpenseRequested, // Make it required
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
   // Local state derived from the passed group
   late List<User> _users;
   late List<Expense> _expenses;
   User? _lastSelectedPayer; // Keep track of the last spin result

   @override
  void initState() {
    super.initState();
    _updateStateFromWidget();
  }

   @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.group != oldWidget.group) {
      _updateStateFromWidget();
    }
     // Call userTotals here as well in case internal expense list changed
     // without the group object itself changing reference.
     widget.group.userTotals;
     // If only expenses change, we need to update the local _expenses copy
     if (!ListEquality().equals(widget.group.expenses, _expenses)) {
       setState(() {
         _expenses = widget.group.expenses;
       });
     }
  }

  // Helper to update the local state variables from the widget's group property
  void _updateStateFromWidget() {
     _users = widget.group.members;
     _expenses = widget.group.expenses;
     // Calculate totals (updates user.totalPaid)
     widget.group.userTotals;
     _lastSelectedPayer = null;
  }


   // --- Spin Wheel Logic (Modified to use Callback) ---
   void _spinWheel() {
     if (_users.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('No members in the group to select from.'))
         );
       return;
     }
     final random = Random();
     final payerIndex = random.nextInt(_users.length);
     final selectedPayer = _users[payerIndex];

     // Update the UI to show who was selected immediately
     setState(() {
       _lastSelectedPayer = selectedPayer;
     });

     // Show a dialog confirming the selection and asking to proceed
     showDialog<bool>(
       context: context,
       barrierDismissible: false,
       builder: (dialogContext) => AlertDialog(
         title: const Text('Spin Result'),
         content: Row(
           children: [
             CircleAvatar(
                backgroundColor: selectedPayer.profileColor ?? Colors.grey[300],
                child: Text(selectedPayer.initials, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
             ),
             const SizedBox(width: 15),
             Expanded(child: Text('${selectedPayer.name} has been selected to pay!')),
           ],
         ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('OK & Enter Details'),
            ),
          ],
       ),
     ).then((shouldNavigate) {
        // This code runs AFTER the dialog is closed
        if (shouldNavigate == true && mounted) {
             // *** CHANGE HERE: Call the callback passed from the parent (MainScreen) ***
             widget.onAddExpenseRequested(preselectedPayerId: selectedPayer.id);
        }
     });
   }

   // Getter for total group expenses for cleaner access in build method
   double get _totalGroupExpenses => widget.group.totalGroupExpenses;

   @override
   Widget build(BuildContext context) {
     // Ensure user totals are current before building cards.
     // This calculation happens in didUpdateWidget or initState now.
     // widget.group.userTotals; // Might be redundant here unless state updates are missed

     // Use the local _expenses list which is updated in didUpdateWidget
     final currentExpenses = _expenses;

     return ListView(
         padding: const EdgeInsets.all(16.0),
         children: [
           // --- Total Overview Card ---
           Card(
             elevation: 2,
             child: Padding(
               padding: const EdgeInsets.all(16.0),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                     'Total Group Expenses',
                     style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black54),
                   ),
                   const SizedBox(height: 4),
                   Text(
                     currencyFormatter.format(_totalGroupExpenses),
                     style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                   ),
                 ],
               ),
             ),
           ),
            const SizedBox(height: 20),

           // --- User Balances Section ---
            Text(
                'User Balances (Total Paid in Group)',
                style: Theme.of(context).textTheme.titleLarge
            ),
            const SizedBox(height: 8),
            if (widget.group.members.isNotEmpty)
                 // Map each user using the latest user data from widget.group.members
                 // UserBalanceCard receives the user object which had its totalPaid updated
                 // by the userTotals getter called earlier.
                 ...widget.group.members.map((user) => UserBalanceCard(
                       user: user
                     )).toList()
            else
                 const Padding(
                   padding: EdgeInsets.symmetric(vertical: 8.0),
                   child: Text("No members in this group."),
                 ),


             const SizedBox(height: 24),

            // --- Spin Button ---
            ElevatedButton.icon(
              icon: const Icon(Icons.casino_outlined),
              label: const Text('Who Pays Next?'),
              onPressed: _spinWheel,
              style: ElevatedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
            ),
              if (_lastSelectedPayer != null)
               Padding(
                 padding: const EdgeInsets.only(top: 12.0),
                 child: Text(
                   'Last selected: ${_lastSelectedPayer!.name}',
                   textAlign: TextAlign.center,
                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
               ),

            const SizedBox(height: 24),

           // --- Last Expense Section ---
            Text(
                'Last Expense',
                style: Theme.of(context).textTheme.titleLarge
            ),
            const SizedBox(height: 8),
             if (currentExpenses.isNotEmpty)
                ExpenseCard(
                    // Sort and get latest expense
                    expense: currentExpenses.sorted((a, b) => b.date.compareTo(a.date)).first,
                    // Find the payer User object
                    payer: widget.group.getUserById(currentExpenses.sorted((a, b) => b.date.compareTo(a.date)).first.payerId),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('No expenses recorded yet for this group.'),
                ),
            const SizedBox(height: 16),
         ],
       );
   }
}