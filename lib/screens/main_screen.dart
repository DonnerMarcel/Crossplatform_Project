// In lib/screens/main_screen.dart (or wherever MainScreen is defined)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

// Ensure correct path for these imports
import '../providers.dart';
import '../models/models.dart';
import '../utils/formatters.dart';

// Import screen widgets
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'add_expense_screen.dart';
import 'data_details_screen.dart';

// Change StatefulWidget to ConsumerStatefulWidget
class MainScreen extends ConsumerStatefulWidget {
  final String groupId;

  const MainScreen({super.key, required this.groupId});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

// Change State to ConsumerState
class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0; // Start on Dashboard (index 0)

  @override
  void initState() {
    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
         _selectedIndex = index;
       });
  }

  // --- _navigateToAddExpense method (Unchanged from your version) ---
  void _navigateToAddExpense({String? preselectedPayerId}) async {
    final PaymentGroup? group = ref.read(groupServiceProvider.select(
        (groups) => groups.firstWhereOrNull((g) => g.id == widget.groupId)
    ));

    if (group == null) {
        ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Error: Group data not available.'))
        );
        return;
    }
    if (group.members.isEmpty && preselectedPayerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Cannot add expense: No members in the group.'))
        );
        return;
    }

    final result = await Navigator.push<Expense>(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          groupMembers: group.members,
          preselectedPayerId: preselectedPayerId,
          currencySymbol: currencyFormatter.currencySymbol,
        ),
      ),
    );

    if (result != null && mounted) {
      ref.read(groupServiceProvider.notifier).addExpenseToGroup(widget.groupId, result);
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
    final PaymentGroup? currentGroup = ref.watch(groupServiceProvider.select(
      (groups) => groups.firstWhereOrNull((g) => g.id == widget.groupId)
    ));

    // Handle null case: Group not found (Keep this)
    if (currentGroup == null) {
        return Scaffold(
          appBar: AppBar(
             title: const Text("Group Not Found"),
              leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
             ),
           ),
          body: const Center( child: Padding( padding: EdgeInsets.all(16.0), child: Text("This group may have been deleted...", textAlign: TextAlign.center),), ),
        );
    }

    // Define widget options list (now with 4 items)
    final List<Widget> widgetOptions = <Widget>[
        DashboardScreen(
          group: currentGroup,
          onAddExpenseRequested: _navigateToAddExpense,
        ), // Index 0
        HistoryScreen(group: currentGroup),             // Index 1
        DataDetailsScreen(group: currentGroup),        // Index 2
        SettingsScreen(group: currentGroup),           // Index 3
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
      body: IndexedStack( // Keep IndexedStack
        index: _selectedIndex,
        children: widgetOptions,
      ),
      // No FAB here anymore

      // --- MODIFIED: BottomAppBar with even spacing ---
      bottomNavigationBar: BottomAppBar(
        // shape: const CircularNotchedRectangle(), // Shape no longer needed
        // notchMargin: 6.0, // Notch margin no longer needed
        color: Theme.of(context).bottomAppBarTheme.color ?? Colors.white,
        elevation: Theme.of(context).bottomAppBarTheme.elevation ?? 2,
        child: Row(
          // Use spaceAround for even distribution of the 4 items
          mainAxisAlignment: MainAxisAlignment.spaceAround, // <-- CHANGED
          children: <Widget>[
            _buildNavItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', 0),
            _buildNavItem(Icons.history_outlined, Icons.history, 'History', 1),
            // const Spacer(flex: 1), // Spacer REMOVED
            _buildNavItem(Icons.pie_chart_outline, Icons.pie_chart, 'Data', 2),
            _buildNavItem(Icons.settings_outlined, Icons.settings, 'Settings', 3),
          ],
        ),
      ),
    );
  }

  // Helper method to build navigation items (Unchanged from your version)
   Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    final bool isSelected = _selectedIndex == index;
    final Color? itemColor = isSelected
        ? Theme.of(context).colorScheme.primary
        : Colors.grey[600];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0), // Keep padding if desired
      child: IconButton(
        icon: Icon(isSelected ? activeIcon : icon),
        color: itemColor,
        tooltip: label,
        onPressed: () => _onItemTapped(index),
      ),
    );
  }
}