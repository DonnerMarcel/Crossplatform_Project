import 'package:flutter/material.dart';
import 'package:flutter_application_2/data/dummy_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

import '../providers.dart';
import '../models/models.dart';
import '../utils/formatters.dart';

// Import screen widgets
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'add_expense_screen.dart';
import 'data_details_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  final String groupId;

  const MainScreen({super.key, required this.groupId});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

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
      ref.read(groupServiceProvider.notifier).addExpenseToGroup(groupId: widget.groupId, newExpense: result);
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
      body: IndexedStack(
        index: _selectedIndex,
        children: widgetOptions,
      ),
      // No FAB here anymore


      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).bottomAppBarTheme.color ?? Colors.white,
        elevation: Theme.of(context).bottomAppBarTheme.elevation ?? 2,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', 0),
            _buildVerticalDivider(),
            _buildNavItem(Icons.history_outlined, Icons.history, 'History', 1),
            _buildVerticalDivider(),
            _buildNavItem(Icons.pie_chart_outline, Icons.pie_chart, 'Data', 2),
            _buildVerticalDivider(),
            _buildNavItem(Icons.settings_outlined, Icons.settings, 'Settings', 3),
          ],
        ),
      ),
    );
  }
  Widget _buildVerticalDivider() {
    return const SizedBox(
      height: 24,
      child: VerticalDivider(
        color: Colors.grey,
        thickness: 0.5,
        width: 20,
      ),
    );
  }

   Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    final bool isSelected = _selectedIndex == index;
    final Color? itemColor = isSelected
        ? Theme.of(context).colorScheme.primary
        : Colors.grey[600];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: IconButton(
        icon: Icon(isSelected ? activeIcon : icon),
        color: itemColor,
        tooltip: label,
        onPressed: () => _onItemTapped(index),
      ),
    );
  }
}