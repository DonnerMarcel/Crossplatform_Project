// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/formatters.dart'; // Assuming formatters are moved here
import 'dashboard_screen.dart';   // Import DashboardScreen
import 'history_screen.dart';     // Import HistoryScreen
import 'settings_screen.dart';    // Import SettingsScreen
import 'add_expense_screen.dart'; // Import AddExpenseScreen

class MainScreen extends StatefulWidget {
  final PaymentGroup group;

  const MainScreen({super.key, required this.group});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Index for the selected tab
  late List<Widget> _widgetOptions; // List of widgets for the tabs

  @override
  void initState() {
    super.initState();
    _updateWidgetOptions(); // Initialize the list of tab widgets
  }

  // Helper function to build/update the list of widgets for the tabs
  void _updateWidgetOptions() {
       _widgetOptions = <Widget>[
         // *** CHANGE IS HERE: Pass the callback function ***
         DashboardScreen(
           group: widget.group,
           onAddExpenseRequested: _navigateToAddExpense, // Pass the method here!
         ),
         HistoryScreen(group: widget.group),
         SettingsScreen(group: widget.group),
       ];
  }

  // Handles tapping on the bottom navigation bar items
  void _onItemTapped(int index) {
    // Check if the index is valid before updating state
    if (index >= 0 && index < _widgetOptions.length) {
       setState(() {
         _selectedIndex = index;
       });
    }
  }

  // Handles navigation to the Add Expense Screen
  // This method is now passed as a callback to DashboardScreen
  void _navigateToAddExpense({String? preselectedPayerId}) async {
    // Navigate and wait for a result (the new Expense or null)
    final result = await Navigator.push<Expense>( // Expect an Expense object back
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          groupMembers: widget.group.members,
          preselectedPayerId: preselectedPayerId, // Pass preselected payer if available
          currencySymbol: currencyFormatter.currencySymbol, // Use formatter
        ),
      ),
    );

    // If an expense was returned (i.e., saved and popped back)
    if (result != null && mounted) { // Check mounted for safety after async gap
      setState(() {
        // Add the new expense to the group's list IN MEMORY.
        widget.group.expenses.add(result);
        // Sort expenses by date, newest first
        widget.group.expenses.sort((a, b) => b.date.compareTo(a.date));

        // Re-initialize widget options to ensure child widgets get the updated group data
        // This forces the children (like DashboardScreen) to rebuild with the new expense list.
        _updateWidgetOptions();

         // Show a confirmation message
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Expense "${result.description}" saved.'),
             duration: const Duration(seconds: 2),
            )
         );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name), // Display the group name
        leading: IconButton( // Back button
           icon: const Icon(Icons.arrow_back),
           tooltip: 'Back to My Groups',
           onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        // Display the widget corresponding to the selected tab index
        // Add safety check for index range
        child: (_selectedIndex >= 0 && _selectedIndex < _widgetOptions.length)
               ? _widgetOptions.elementAt(_selectedIndex)
               : const Center(child: Text("Invalid tab selected")), // Fallback
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddExpense(), // FAB calls the method directly
        tooltip: 'Add Expense to ${widget.group.name}',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
            const SizedBox(width: 40), // Spacer for FAB
            _buildNavItem(Icons.settings_outlined, Icons.settings, 'Settings', 2),
          ],
        ),
      ),
    );
  }

  // Helper method to build individual navigation items for the BottomAppBar
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