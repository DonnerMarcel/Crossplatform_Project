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
  bool _didDataChange = false; // Flag to track if data changed

  @override
  void initState() {
    super.initState();
    _updateWidgetOptions(); // Initialize the list of tab widgets
  }

  // Helper function to build/update the list of widgets for the tabs
  void _updateWidgetOptions() {
       _widgetOptions = <Widget>[
         // Pass the group data AND the callback function down to DashboardScreen
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
    final result = await Navigator.push<Expense>(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          groupMembers: widget.group.members,
          preselectedPayerId: preselectedPayerId,
          currencySymbol: currencyFormatter.currencySymbol,
        ),
      ),
    );

    if (result != null && mounted) {
      _didDataChange = true; // Set flag: Data has potentially changed
      setState(() {
        widget.group.expenses.add(result);
        widget.group.expenses.sort((a, b) => b.date.compareTo(a.date));
        // Rebuild widgets to reflect change immediately within MainScreen tabs
        _updateWidgetOptions();
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Expense "${result.description}" saved.'),
             duration: const Duration(seconds: 2),
            )
         );
      });
    }
    // NOTE: No explicit pop here, the pop happens either in AddExpenseScreen
    // or when the user presses the back button (_goBack).
  }

  // --- ADDED: Method for handling the back button press ---
  void _goBack() {
    // Pop the screen and return the value of _didDataChange.
    // This signals to GroupListScreen whether a refresh might be needed.
    Navigator.of(context).pop(_didDataChange);
  }


  @override
  Widget build(BuildContext context) {
    // WillPopScope can intercept the system back button press
    // to ensure our _goBack logic (returning the flag) is used.
    return WillPopScope(
      onWillPop: () async {
        // When system back button is pressed, call our _goBack logic
        _goBack();
        // Return false to prevent the default system back navigation,
        // as _goBack already handled it.
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.group.name),
          // Use the modified back button logic for the AppBar back arrow
          leading: IconButton(
             icon: const Icon(Icons.arrow_back),
             tooltip: 'Back to My Groups',
             onPressed: _goBack, // Use the new method
          ),
        ),
        body: Center(
          child: (_selectedIndex >= 0 && _selectedIndex < _widgetOptions.length)
                 ? _widgetOptions.elementAt(_selectedIndex)
                 : const Center(child: Text("Invalid tab selected")), // Fallback
        ),
        floatingActionButton: FloatingActionButton(
          // FAB press triggers adding expense, _goBack handles returning signal later
          onPressed: () => _navigateToAddExpense(),
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