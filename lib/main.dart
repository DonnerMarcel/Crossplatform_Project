// main.dart
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart'; // Make sure this is added
import 'models.dart';
import 'add_expense_screen.dart';

// --- Define Current User (Example) ---
// In a real app, this would come from login/auth state
final User currentUser = User(id: '1', name: 'Me', profileColor: Colors.deepPurple);

// --- Dummy Data for Groups ---
// Create some distinct users first
final userMe = currentUser;
final userMax = User(id: '2', name: 'Max', profileColor: Colors.amber);
final userKlaus = User(id: '3', name: 'Klaus Huber', profileColor: Colors.blue);
final userJohn = User(id: '4', name: 'John', profileColor: Colors.redAccent);
final userAnna = User(id: '5', name: 'Anna', profileColor: Colors.green);

// Create dummy groups with members and expenses
List<PaymentGroup> dummyGroups = [
  // Group 1: "WG Sonnenallee" - Me is potentially behind
  PaymentGroup(
    id: 'g1',
    name: 'WG Sonnenallee',
    members: [userMe, userMax, userAnna],
    expenses: [
      Expense(id: 'e101', amount: 50.0, date: DateTime(2025, 4, 1), description: 'Rent Contribution', payerId: userMax.id),
      Expense(id: 'e102', amount: 30.0, date: DateTime(2025, 4, 3), description: 'Groceries', payerId: userAnna.id),
      Expense(id: 'e103', amount: 15.0, date: DateTime(2025, 4, 5), description: 'Internet', payerId: userMe.id), // Me paid little
      Expense(id: 'e104', amount: 50.0, date: DateTime(2025, 4, 6), description: 'Rent Contribution', payerId: userMax.id),
    ],
  ),
  // Group 2: "Lunch Buddies" - Me seems okay/ahead
  PaymentGroup(
    id: 'g2',
    name: 'Lunch Buddies',
    members: [userMe, userJohn, userKlaus],
    expenses: [
      Expense(id: 'e201', amount: 62.55, date: DateTime(2025, 1, 23), description: 'Asian Restaurant', payerId: userMe.id), // Me paid
      Expense(id: 'e202', amount: 45.00, date: DateTime(2025, 1, 20), description: 'Pizza', payerId: userJohn.id),
      Expense(id: 'e203', amount: 88.45, date: DateTime(2025, 1, 15), description: 'Burger Joint', payerId: userMe.id), // Me paid again
    ],
  ),
   // Group 3: "Holiday Trip" - Empty expenses
  PaymentGroup(
    id: 'g3',
    name: 'Holiday Trip',
    members: [userMe, userMax, userJohn, userAnna],
    expenses: [], // No expenses yet
  ),
];
// --- End Dummy Data ---

// --- Settings & Formatting (Unchanged) ---
const double portionCostPerUser = 25.0;
final currencyFormatter = NumberFormat.currency(locale: 'de_DE', symbol: '€');

void main() {
  runApp(const FairFlipApp());
}

class FairFlipApp extends StatelessWidget {
  const FairFlipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FairFlip',
      theme: ThemeData( // Theme definition remains the same
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[100],
          elevation: 0,
          foregroundColor: Colors.black87,
        ),
        cardTheme: CardTheme(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        ),
        // BottomAppBar styling might be needed if different from BottomNavBar
        bottomAppBarTheme: BottomAppBarTheme(
             color: Colors.white, // Example color
             elevation: 2,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
           backgroundColor: Theme.of(context).colorScheme.primary,
           foregroundColor: Colors.white,
        ),
      ),
      // The NEW Home Screen
      home: const GroupListScreen(),
    );
  }
}

// --- NEW: Group List Screen (The Start Menu) ---
class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  // Use dummy data for now
  final List<PaymentGroup> _groups = dummyGroups;

  void _navigateToGroup(PaymentGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Navigate to the MainScreen, passing the selected group
        builder: (context) => MainScreen(group: group),
      ),
    );
  }

  void _addGroup() {
    // TODO: Implement logic to add a new group
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Placeholder: Add New Group'))
    );
  }

  void _onSync() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Placeholder: Sync Action'))
    );
  }
  void _onFilter() {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Placeholder: Filter Action'))
    );
  }
   void _onSettings() { // Renamed from _onOptions to avoid conflict potentially
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Placeholder: Options/Settings Action'))
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Groups'),
        // You could add actions here if needed
      ),
      body: Column(
          children: [
              // --- AD Placeholder ---
              Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  margin: const EdgeInsets.only(bottom: 8), // Add margin below AD
                  color: Colors.red[100], // Example AD background color
                  child: const Center(
                      child: Text(
                          'AD Placeholder',
                          style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                      ),
                  ),
              ),
              // --- Group List ---
              Expanded(
                  child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0), // Add horizontal padding
                      itemCount: _groups.length,
                      itemBuilder: (context, index) {
                          final group = _groups[index];
                          // Check if the current user is behind in this group
                          final bool userIsBehind = group.isUserBehind(currentUser.id);

                          return Card(
                              // Highlight card if user is behind
                              color: userIsBehind ? Colors.red[50] : null, // Light red highlight
                              // Use InkWell for tap effect and navigation
                              child: InkWell(
                                  onTap: () => _navigateToGroup(group),
                                  borderRadius: BorderRadius.circular(12), // Match card shape
                                  child: ListTile(
                                      // Display initials of first few members as an indicator
                                      leading: CircleAvatar(
                                         backgroundColor: userIsBehind ? Colors.red[100] : Theme.of(context).colorScheme.secondaryContainer,
                                         child: Text(
                                              // Show initials of first member or group letter
                                              group.members.isNotEmpty ? group.members.first.initials : group.name.substring(0,1),
                                              style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer, fontSize: 12),
                                          )
                                      ),
                                      title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      // Maybe show number of members or total expenses as subtitle
                                      subtitle: Text('${group.members.length} Members'),
                                      trailing: userIsBehind
                                          ? const Icon(Icons.warning_amber_rounded, color: Colors.red) // Warning icon if behind
                                          : const Icon(Icons.chevron_right), // Navigate icon
                                  ),
                              ),
                          );
                      },
                  ),
              ),
          ],
      ),
       floatingActionButton: FloatingActionButton(
        onPressed: _addGroup,
        tooltip: 'Add Group',
        child: const Icon(Icons.add),
      ),
      // Use BottomAppBar for the specific actions on this screen
      bottomNavigationBar: BottomAppBar(
         child: Row(
           mainAxisAlignment: MainAxisAlignment.spaceAround,
           children: <Widget>[
              IconButton(icon: const Icon(Icons.sync), onPressed: _onSync, tooltip: 'Sync'),
              IconButton(icon: const Icon(Icons.filter_list), onPressed: _onFilter, tooltip: 'Filter'),
              IconButton(icon: const Icon(Icons.more_vert), onPressed: _onSettings, tooltip: 'Options'), // Using 'more_vert' for Opt.
           ],
         ),
       ),
    );
  }
}


// --- MODIFIED: Main Screen (Handle adding expense) ---
class MainScreen extends StatefulWidget {
  final PaymentGroup group;

  const MainScreen({super.key, required this.group});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

// In main.dart

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late List<Widget> _widgetOptions;

  // Use a key to potentially force rebuilds of children if needed,
  // though modifying the list passed to them should often suffice.
  final GlobalKey _dashboardKey = GlobalKey();
  final GlobalKey _historyKey = GlobalKey();


  @override
  void initState() {
    super.initState();
    _updateWidgetOptions(); // Initialize options
  }

  // Helper function to build/update widget options
  void _updateWidgetOptions() {
      // Passing the potentially updated group data down
       _widgetOptions = <Widget>[
          // Use Keys to help Flutter identify widgets if needed after state change
         DashboardScreen(key: _dashboardKey, group: widget.group),
         HistoryScreen(key: _historyKey, expenses: widget.group.expenses, groupMembers: widget.group.members),
         SettingsScreen(group: widget.group),
       ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
// In _MainScreenState class within main.dart

  // --- MODIFIED: Navigation to Add Expense (with currencySymbol) ---
  void _navigateToAddExpense({String? preselectedPayerId}) async {
    // Navigate and wait for a result (the new Expense or null)
    final result = await Navigator.push<Expense>( // Expect an Expense object back
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          groupMembers: widget.group.members,
          preselectedPayerId: preselectedPayerId, // Pass preselected payer if available
          // --- THIS IS THE ADDED LINE ---
          currencySymbol: currencyFormatter.currencySymbol, // <-- PASS THE SYMBOL HERE
          // --- END OF ADDED LINE ---
        ),
      ),
    );

    // If an expense was returned (i.e., saved and popped)
    if (result != null && mounted) { // Check mounted for safety
      setState(() {
        // Add the new expense to the group's list
        // IMPORTANT: This modifies the list within the group object passed to MainScreen.
        // Child widgets using this list should rebuild.
        widget.group.expenses.add(result);
        // Sort expenses by date, newest first (optional)
        widget.group.expenses.sort((a, b) => b.date.compareTo(a.date));

        // Re-initialize widget options to pass updated data (might not be strictly necessary if children react correctly)
        // _updateWidgetOptions(); // Uncomment if direct list modification doesn't trigger rebuild in children reliably

         // Show confirmation
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Expense "${result.description}" saved.'))
         );
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Ensure widgetOptions are up-to-date if state changes externally (less likely here)
     // _updateWidgetOptions(); // Usually not needed in build unless state depends on context changes

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        leading: IconButton(
           icon: const Icon(Icons.arrow_back),
           onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      floatingActionButton: FloatingActionButton(
         // Call navigation without preselected payer from FAB
        onPressed: () => _navigateToAddExpense(),
        tooltip: 'Add Expense to ${widget.group.name}',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
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

  // Helper method to build navigation items (Unchanged from your snippet)
   Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    return IconButton(
      icon: Icon(_selectedIndex == index ? activeIcon : icon),
      color: _selectedIndex == index ? Theme.of(context).colorScheme.primary : Colors.grey[600],
      tooltip: label,
      onPressed: () => _onItemTapped(index),
    );
  }
}

// --- MODIFIED: Dashboard Screen (Trigger Add Expense after Spin) ---
class DashboardScreen extends StatefulWidget {
    final PaymentGroup group;
    // Use key if needed for state management between parent/child
    const DashboardScreen({super.key, required this.group});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
   late List<User> _users;
   late List<Expense> _expenses;
   User? _lastSelectedPayer;

   @override
  void initState() {
    super.initState();
    _updateStateFromWidget();
  }

   // Update local state when the input group changes (might happen if parent rebuilds)
   @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.group != oldWidget.group) {
      _updateStateFromWidget();
    }
  }

  void _updateStateFromWidget() {
     _users = widget.group.members;
     _expenses = widget.group.expenses;
     // Calculate totals to update User objects within the list
     widget.group.userTotals;
     _lastSelectedPayer = null; // Reset last payer when group context changes
  }


   // --- MODIFIED: Spin Wheel Logic (Navigate after dialog) ---
   void _spinWheel() {
     if (_users.isEmpty) return;
     final random = Random();
     final payerIndex = random.nextInt(_users.length);
     final selectedPayer = _users[payerIndex];

     setState(() {
       _lastSelectedPayer = selectedPayer;
     });

     showDialog<bool>( // Expect a boolean back indicating if details should be entered
       context: context,
       builder: (context) => AlertDialog(
         title: const Text('Spin Result'),
         content: Row(
           children: [
             CircleAvatar(
                backgroundColor: selectedPayer.profileColor ?? Colors.grey,
                child: Text(selectedPayer.initials, style: const TextStyle(color: Colors.white)),
             ),
             const SizedBox(width: 15),
             Expanded(child: Text('${selectedPayer.name} has been selected!')),
           ],
         ),
          actions: [
            TextButton(
              // Pop dialog and return true to indicate navigation
              onPressed: () => Navigator.pop(context, true),
              child: const Text('OK & Enter Details'),
            ),
            TextButton(
               // Pop dialog and return false
               onPressed: () => Navigator.pop(context, false),
               child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
             )
          ],
       ),
     ).then((shouldNavigate) {
        // This code runs AFTER the dialog is closed
        if (shouldNavigate == true && mounted) {
             // Find the MainScreenState to call its navigation method
             // This is a bit fragile; proper state management (Provider, Riverpod) is better
            final mainScreenState = context.findAncestorStateOfType<_MainScreenState>();
            mainScreenState?._navigateToAddExpense(preselectedPayerId: selectedPayer.id);
        }
     });
   }

   double get _totalGroupExpenses => widget.group.totalGroupExpenses;

   @override
   Widget build(BuildContext context) {
     // Ensure user totals are current before building cards
     widget.group.userTotals;

     // UI structure remains the same (ListView with Cards etc.)
     // ... (Existing ListView structure from previous answer) ...
      return ListView(
         padding: const EdgeInsets.all(16.0),
         children: [
           // --- Total Overview Card ---
           Card(
             child: Padding(
               padding: const EdgeInsets.all(16.0),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                     'Total Group Expenses',
                     style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black54),
                   ),
                   Text(
                     currencyFormatter.format(_totalGroupExpenses),
                     style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                   ),
                 ],
               ),
             ),
           ),
            const SizedBox(height: 16),

           // --- User Balances ---
            Text('User Balances', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (_users.isNotEmpty)
                 ..._users.map((user) => UserBalanceCard(user: user)).toList()
            else
                 const Text("No members in this group."),


             const SizedBox(height: 24),

            // --- Spin Button ---
            ElevatedButton.icon(
              icon: const Icon(Icons.casino_outlined),
              label: const Text('Who Pays This Time?'),
              onPressed: _spinWheel, // Triggers the modified spin logic
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

           // --- Last Expense ---
            Text('Last Expense', style: Theme.of(context).textTheme.titleLarge),
             if (_expenses.isNotEmpty)
                ExpenseCard(
                    // Sort expenses inline to get the latest by date
                    expense: _expenses.sorted((a, b) => b.date.compareTo(a.date)).first,
                    payer: widget.group.getUserById(_expenses.sorted((a, b) => b.date.compareTo(a.date)).first.payerId),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('No expenses recorded yet for this group.'),
                ),
         ],
       );
   }
}

// --- MODIFIED: UserBalanceCard (Unchanged logic, but context is now group) ---
class UserBalanceCard extends StatelessWidget {
  final User user; // Receives User with updated totalPaid for the group

  const UserBalanceCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
           backgroundColor: user.profileColor ?? Theme.of(context).colorScheme.primaryContainer,
           foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
           child: Text(user.initials, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(
           // Display amount paid within this group context
           currencyFormatter.format(user.totalPaid),
           style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)
        ),
      ),
    );
  }
}

// --- MODIFIED: ExpenseCard (Now needs Payer User Object passed separately) ---
class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final User? payer; // Pass the actual User object for the payer

  const ExpenseCard({super.key, required this.expense, required this.payer});

  @override
  Widget build(BuildContext context) {
     return Card(
       child: ListTile(
          leading: const Icon(Icons.receipt_long_outlined, color: Colors.grey),
          title: Text(expense.description, style: const TextStyle(fontWeight: FontWeight.bold)),
          // Use the passed payer object's name
          subtitle: Text('Paid by ${payer?.name ?? "Unknown"} on ${formatDate(expense.date)}'),
          trailing: Text(
             currencyFormatter.format(expense.amount),
             style: const TextStyle(fontWeight: FontWeight.bold)
          ),
       ),
     );
  }
}


// --- MODIFIED: History Screen (Receives expenses and members) ---
class HistoryScreen extends StatelessWidget {
    final List<Expense> expenses;
    final List<User> groupMembers; // Needed to find payer names

   const HistoryScreen({super.key, required this.expenses, required this.groupMembers});

    // Helper to find user by ID within the group members
    User? _findUserById(String id) {
        try {
           return groupMembers.firstWhere((user) => user.id == id);
       } catch (e) {
           return null; // Not found
       }
    }

  @override
  Widget build(BuildContext context) {
     // No Scaffold/AppBar here, it's provided by MainScreen
    return expenses.isEmpty
          ? const Center(child: Text('No expenses recorded yet for this group.'))
          : ListView.builder(
              padding: const EdgeInsets.all(10.0),
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final expense = expenses[index];
                final payerUser = _findUserById(expense.payerId); // Find the payer
                 return ExpenseCard(expense: expense, payer: payerUser); // Pass payer object
              },
            );
  }
}

// --- MODIFIED: Settings Screen (Placeholder, receives group) ---
class SettingsScreen extends StatelessWidget {
    final PaymentGroup group;
   const SettingsScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
     // No Scaffold/AppBar here, it's provided by MainScreen
     return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
              ListTile( // Example: Show group name setting (read-only for now)
                leading: const Icon(Icons.edit_note),
                title: const Text('Group Name'),
                subtitle: Text(group.name),
                onTap: () {
                   ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Placeholder: Edit group name'))
                    );
                },
             ),
             const Divider(),
             ListTile(
                leading: const Icon(Icons.attach_money),
                title: const Text('Cost per Portion/Meal (Global)'), // This might be global?
                subtitle: Text(currencyFormatter.format(portionCostPerUser)),
                onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Placeholder: Change global portion cost'))
                    );
                },
             ),
             const Divider(),
             ListTile(
                leading: const Icon(Icons.people_outline),
                title: Text('Manage Members (${group.members.length})'),
                subtitle: const Text('Add/remove members for this group'),
                onTap: () {
                   ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Placeholder: Manage members for ${group.name}'))
                    );
                },
             ),
             const Divider(),
             ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete Group'),
                textColor: Colors.red,
                iconColor: Colors.red,
                onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Placeholder: Delete group ${group.name}'))
                    );
                },
             ),
              // Add more group-specific settings here...
          ],
       );
  }
}