// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:collection/collection.dart'; // Import collection package for firstWhereOrNull

// Import providers and models
import '../providers.dart';
import '../models/models.dart';
import '../utils/formatters.dart';

// Import screen components
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'add_expense_screen.dart';

// Change StatefulWidget to ConsumerStatefulWidget
class MainScreen extends ConsumerStatefulWidget {
  // Accept groupId instead of the whole group object
  final String groupId;

  const MainScreen({super.key, required this.groupId});

  @override
  // Change State to ConsumerState
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

// Change State to ConsumerState
class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
       _selectedIndex = index;
     });
  }

  // --- Modified: Handle navigation and adding expense via Provider ---
  void _navigateToAddExpense({String? preselectedPayerId}) async {
    // Use ref.read to safely get the current state within this async method
    // --- FIX: Use firstWhereOrNull for safer nullable lookup ---
    final PaymentGroup? group = ref.read(groupServiceProvider.select(
       // Use firstWhereOrNull from package:collection
       (groups) => groups.firstWhereOrNull((g) => g.id == widget.groupId)
    ));

    // Check if group data is available
    if (group == null) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Error: Group data not available.'))
       );
       return;
    }
    // Check if there are members to pay
    if (group.members.isEmpty && preselectedPayerId == null) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Cannot add expense: No members in the group.'))
       );
       return;
    }

    // Navigate to AddExpenseScreen
    final result = await Navigator.push<Expense>(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          groupMembers: group.members, // Use members from fetched group
          preselectedPayerId: preselectedPayerId,
          currencySymbol: currencyFormatter.currencySymbol,
        ),
      ),
    );

    // If an expense was successfully created and returned
    if (result != null && mounted) {
      // Call the provider's method to add the expense to the central state
      ref.read(groupServiceProvider.notifier).addExpenseToGroup(widget.groupId, result);

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Expense "${result.description}" saved.'),
          duration: const Duration(seconds: 2),
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Use ref.watch to get the current group data ---
    // --- FIX: Use firstWhereOrNull for safer nullable lookup ---
    final PaymentGroup? currentGroup = ref.watch(groupServiceProvider.select(
      // Use firstWhereOrNull from package:collection
      (groups) => groups.firstWhereOrNull((g) => g.id == widget.groupId)
    ));

    // --- Handle null case: Group not found ---
    if (currentGroup == null) {
       return Scaffold(
         appBar: AppBar(
            title: const Text("Group Not Found"),
            leading: IconButton(
               icon: const Icon(Icons.arrow_back),
               onPressed: () => Navigator.of(context).pop(),
            ),
          ),
         body: const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "This group may have been deleted or is no longer available.",
                  textAlign: TextAlign.center,
                ),
              )
         ),
       );
    }

    // If group data is available, build the main UI:

    // Build widget options dynamically using the non-null currentGroup
    final List<Widget> widgetOptions = <Widget>[
        DashboardScreen(
          group: currentGroup, // Pass the non-null group
          onAddExpenseRequested: _navigateToAddExpense, // Pass the callback
        ),
        HistoryScreen(group: currentGroup), // Pass the non-null group
        SettingsScreen(group: currentGroup), // Pass the non-null group
      ];

    return Scaffold(
      appBar: AppBar(
        title: Text(currentGroup.name),
        leading: IconButton(
           icon: const Icon(Icons.arrow_back),
           tooltip: 'Back to My Groups',
           onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: (_selectedIndex >= 0 && _selectedIndex < widgetOptions.length)
               ? widgetOptions.elementAt(_selectedIndex)
               : const Center(child: Text("Invalid tab selected")),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        color: Theme.of(context).bottomAppBarTheme.color ?? Colors.white,
        elevation: Theme.of(context).bottomAppBarTheme.elevation ?? 2,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', 0),
            _buildNavItem(Icons.history_outlined, Icons.history, 'History', 1),
            _buildNavItem(Icons.settings_outlined, Icons.settings, 'Settings', 2),
          ],
        ),
      ),
    );
  }

  // Helper method to build navigation items
   Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    final bool isSelected = _selectedIndex == index;
    final Color? itemColor = isSelected
        ? Theme.of(context).colorScheme.primary
        : Colors.grey[600];

    return IconButton(
      icon: Icon(isSelected ? activeIcon : icon),
      color: itemColor,
      tooltip: label,
      onPressed: () => _onItemTapped(index),
    );
  }
}