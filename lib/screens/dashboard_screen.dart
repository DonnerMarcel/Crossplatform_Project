import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:pie_chart/pie_chart.dart'; // PieChart is not used directly in this snippet

import '../models/models.dart';
import '../providers.dart';
import '../services/profile_image_cache_provider.dart';
import '../utils/formatters.dart';
import '../widgets/dashboard/user_balance_card.dart';
import '../widgets/history/expense_card.dart';
import '../widgets/dashboard/spinning_wheel_dialog.dart'; // Your updated dialog

typedef AddExpenseCallback = void Function({String? preselectedPayerId});

class DashboardScreen extends ConsumerStatefulWidget {
  final PaymentGroup group;
  final AddExpenseCallback onAddExpenseRequested;

  const DashboardScreen({
    super.key,
    required this.group,
    required this.onAddExpenseRequested,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  void _showResultDialog(User selectedUser) {
    final imageCache = ref.read(profileImageCacheProvider);
    final imageUrl = imageCache[selectedUser.id];

    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Spin Result'),
        content: Row(
          children: [
            CircleAvatar(
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
              backgroundColor: selectedUser.profileColor ?? Colors.grey[300],
              foregroundColor:
                  ThemeData.estimateBrightnessForColor(selectedUser.profileColor ?? Colors.grey[300]!) == Brightness.dark
                      ? Colors.white
                      : Colors.black,
              child: Text(selectedUser.name.isNotEmpty ? selectedUser.name.substring(0, 1) : "?", // Handle empty name
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 15),
            Expanded(child: Text('${selectedUser.name} has been selected to pay!')),
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
      if (shouldNavigate == true && mounted) {
        widget.onAddExpenseRequested(preselectedPayerId: selectedUser.id);
      }
    });
  }

  void _openSpinningWheelDialog() {
    if (widget.group.members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No members in group to spin.')),
      );
      return;
    }

    // --- NEW: Calculate averageExpenseAmount ---
    double averageExpense = 0.0;
    if (widget.group.expenses.isNotEmpty) {
      double totalExpensesSum = widget.group.expenses.fold(0.0, (prev, exp) => prev + exp.amount);
      averageExpense = totalExpensesSum / widget.group.expenses.length;
    }
    // --- END NEW ---

    showDialog(
      context: context,
      barrierDismissible: false, // User must interact with the result dialog
      builder: (dialogContext) => SpinningWheelDialog( // Pass dialogContext if needed inside, else use `context`
        users: widget.group.members,
        // totalGroupExpenses: widget.group.totalPaid, // REMOVED
        averageExpenseAmount: averageExpense, // NEW - Pass the calculated average
        onSpinComplete: _showResultDialog,
      ),
    );
  }

  // This getter is still used for displaying total group expenses, which is fine.
  double get _totalGroupExpensesDisplay => widget.group.expenses.fold(0.0, (sum, e) => sum + e.amount);


  // _createPieDataMap and _createPieColorList are not directly used in the provided build method snippet
  // but are kept here if they are used elsewhere or for future reference.
  // If they are truly unused, they can be removed.
  Map<String, double> _createPieDataMap() {
    // Calculate sum of actual expenses for the pie chart if that's the intent
    final double totalActualExpenses = widget.group.expenses.fold(0.0, (sum, e) => sum + e.amount);
    Map<String, double> dataMap = {};

    if (totalActualExpenses <= 0 && widget.group.members.isNotEmpty) {
      for (var user in widget.group.members) {
        dataMap[user.name] = 0.01; // Small value to render all members
      }
      return dataMap;
    }

    // This part depends on what the pie chart should represent.
    // If it's "who paid for what portion of expenses":
    Map<String, double> memberExpenseContribution = {};
    for (var member in widget.group.members) {
        memberExpenseContribution[member.name] = 0.0;
    }
    for (var expense in widget.group.expenses) {
        final payer = widget.group.members.firstWhereOrNull((m) => m.id == expense.payerId);
        if (payer != null) {
            memberExpenseContribution[payer.name] = (memberExpenseContribution[payer.name] ?? 0) + expense.amount;
        }
    }

    for (var user in widget.group.members) {
      final paidByMember = memberExpenseContribution[user.name] ?? 0.0;
      if (paidByMember > 0) {
        dataMap[user.name] = paidByMember;
      } else {
         // Ensure member is in map for color list consistency, even if they paid 0
        dataMap[user.name] = 0.01;
      }
    }
     if (dataMap.values.every((v) => v <= 0.01) && widget.group.members.isNotEmpty) {
        dataMap.clear(); // Clear previous 0.01 values if any
        for (var user in widget.group.members) {
            dataMap[user.name] = 0.01;
        }
    }
    return dataMap;
  }

  List<Color> _createPieColorList(ThemeData theme) {
    List<Color> colorList = [];
    int colorIndex = 0;
    final fallbackColors = [
      theme.colorScheme.primary, theme.colorScheme.secondary, theme.colorScheme.tertiary,
      Colors.orangeAccent, Colors.lightGreen, Colors.blueAccent, Colors.purple,
    ];
    // Ensure colors are assigned consistently with pieDataMap keys
    final pieDataMapKeys = _createPieDataMap().keys.toList();

    for (var userName in pieDataMapKeys) {
        final user = widget.group.members.firstWhereOrNull((member) => member.name == userName);
        if (user != null) {
            colorList.add(user.profileColor ?? fallbackColors[colorIndex % fallbackColors.length]);
        } else {
            colorList.add(fallbackColors[colorIndex % fallbackColors.length]);
        }
        colorIndex++;
    }
    if (colorList.isEmpty && widget.group.members.isNotEmpty) {
      colorList.add(fallbackColors[0]);
    }
    return colorList;
  }


  @override
  Widget build(BuildContext context) {
    // Watch the group for real-time updates from Riverpod
    // The 'widget.group' is the initial group data.
    // To get live updates, you'd typically watch a provider that gives you the group by ID.
    // For example: final currentGroup = ref.watch(groupByIdProvider(widget.group.id));
    // For simplicity, we'll use widget.group, assuming it's up-to-date or this screen
    // is rebuilt when the group data changes significantly.
    final PaymentGroup currentGroup = widget.group;

    final sortedExpenses = List<Expense>.from(currentGroup.expenses)
      ..sort((a, b) => b.date.compareTo(a.date));
    final Expense? latestExpense = sortedExpenses.firstOrNull;
    final theme = Theme.of(context);

    // final pieDataMap = _createPieDataMap(); // If pie chart is re-added
    // final pieColorList = _createPieColorList(theme); // If pie chart is re-added
    // final bool showChart = pieDataMap.isNotEmpty; // If pie chart is re-added

    final imageCache = ref.watch(profileImageCacheProvider);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Group Expenses', style: theme.textTheme.titleMedium?.copyWith(color: Colors.black54)),
                const SizedBox(height: 4),
                Text(currencyFormatter.format(_totalGroupExpensesDisplay), // Using the corrected getter
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // User totals with cached images (sync access)
        Text('User Balances (Total Paid)', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        if (widget.group.members.isNotEmpty)
          ...widget.group.members.map((user) {
            final imageUrl = imageCache[user.id];
            return UserBalanceCard(user: user, userImageUrl: imageUrl);
          }).toList()
        else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text("No members in this group."),
          ),
        const SizedBox(height: 28),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              flex: 5,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.casino_outlined),
                label: const Text('Spin Wheel!'),
                onPressed: _openSpinningWheelDialog,
                style: ElevatedButton.styleFrom(
                  foregroundColor: theme.colorScheme.onPrimary,
                  backgroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20), // Adjusted padding
                  textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), // Adjusted style
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_circle_outline), // Changed icon
                label: const Text('Add Manual'),
                onPressed: () => widget.onAddExpenseRequested(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(color: theme.colorScheme.primary, width: 1.5), // Adjusted border
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20), // Adjusted padding
                  textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), // Adjusted style
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Last Expense with cached image
        Text('Last Expense', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        if (latestExpense != null)
          Builder(builder: (context) {
            final payer = widget.group.members.firstWhere(
                  (user) => user.id == latestExpense.payerId,
              orElse: () => User(
                id: 'unknown_payer', // More specific ID
                name: 'Unknown Payer',
                profileColor: Colors.grey[400], // Slightly different color
              ),
            );
            final imageUrl = imageCache[payer.id];
            return ExpenseCard(expense: latestExpense, payer: payer, payerImageUrl: imageUrl);
          })
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
