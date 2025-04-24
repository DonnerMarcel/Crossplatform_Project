// lib/screens/group_list_screen.dart
import 'package:flutter/material.dart';
import '../data/dummy_data.dart'; // Import the dummy data
import '../models/models.dart';   // Import the data models
import 'main_screen.dart';       // Import the screen to navigate to (will be created)

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  // Use the dummy data imported from dummy_data.dart
  // In a real app, this would fetch data from a database or API
  final List<PaymentGroup> _groups = dummyGroups;

  // Navigate to the MainScreen for the selected group
  void _navigateToGroup(PaymentGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Navigate to MainScreen, passing the selected group
        // MainScreen will be defined in 'main_screen.dart'
        builder: (context) => MainScreen(group: group),
      ),
      // We might want to handle potential updates returned from MainScreen later
      // .then((_) {
      //   // Optional: Refresh the list if needed after returning
      //   setState(() {});
      // });
    );
  }

  // Placeholder action for adding a new group
  void _addGroup() {
    // TODO: Implement logic to add a new group (e.g., show a dialog or new screen)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Placeholder: Add New Group Action'))
    );
  }

  // Placeholder action for sync button
  void _onSync() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Placeholder: Sync Action'))
    );
  }

  // Placeholder action for filter button
  void _onFilter() {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Placeholder: Filter Action'))
    );
  }

  // Placeholder action for settings/options button
   void _onSettings() {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Placeholder: Options/Settings Action'))
    );
  }


  @override
  Widget build(BuildContext context) {
    // Get the current user from dummy data to check if they are behind
    final User currentUser = userMe; // Assuming userMe is the current user from dummy_data

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Groups'),
        // You could add actions like search here later
        // actions: [ IconButton(icon: Icon(Icons.search), onPressed: () {}) ],
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
                                      // Display initials of first few members or group letter
                                      leading: CircleAvatar(
                                         backgroundColor: userIsBehind
                                             ? Colors.red[100] // Use a different color for avatar if behind
                                             : Theme.of(context).colorScheme.secondaryContainer,
                                         child: Text(
                                              // Show initials of first member or group letter if no members
                                              group.members.isNotEmpty
                                                  ? group.members.first.initials // Get initials from User model
                                                  : group.name.isNotEmpty ? group.name.substring(0,1).toUpperCase() : '?',
                                              style: TextStyle(
                                                  color: userIsBehind
                                                      ? Colors.red[800] // Darker text color for highlighted avatar
                                                      : Theme.of(context).colorScheme.onSecondaryContainer,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold),
                                          ),
                                      ),
                                      title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      // Show number of members as subtitle
                                      subtitle: Text('${group.members.length} Member${group.members.length == 1 ? "" : "s"}'),
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
         shape: const AutomaticNotchedShape( // Standard shape for FAB notch if desired
             RoundedRectangleBorder(),
             StadiumBorder(side: BorderSide())),
         padding: const EdgeInsets.symmetric(horizontal: 10.0), // Add padding if needed
         // Use theme color for consistency
         color: Theme.of(context).bottomAppBarTheme.color ?? Colors.white,
         elevation: Theme.of(context).bottomAppBarTheme.elevation ?? 2,
         child: Row(
           mainAxisAlignment: MainAxisAlignment.spaceAround,
           children: <Widget>[
              IconButton(icon: const Icon(Icons.sync), onPressed: _onSync, tooltip: 'Sync'),
              IconButton(icon: const Icon(Icons.filter_list), onPressed: _onFilter, tooltip: 'Filter'),
              // Optional: Add a spacer if you want more separation from FAB area
              // const SizedBox(width: 40),
              IconButton(icon: const Icon(Icons.more_vert), onPressed: _onSettings, tooltip: 'Options'), // Using 'more_vert' for Opt.
           ],
         ),
       ),
       // Optional: If you want the FAB docked into the BottomAppBar
       // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}