// lib/screens/group_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod

// Import the provider we defined
import '../providers.dart';
// Still need dummy data for currentUser until auth is implemented
import '../data/dummy_data.dart';
import '../models/models.dart';
import 'main_screen.dart'; // Import MainScreen for navigation
import 'add_group_screen.dart'; // Import the new screen
import '../widgets/group_list/group_list_item.dart'; // Import the list item widget

// Change StatefulWidget to ConsumerStatefulWidget
class GroupListScreen extends ConsumerStatefulWidget {
  const GroupListScreen({super.key});

  @override
  // Change State to ConsumerState
  ConsumerState<GroupListScreen> createState() => _GroupListScreenState();
}

// Change State to ConsumerState
class _GroupListScreenState extends ConsumerState<GroupListScreen> {
  // Keep currentUser for now, ideally this would also come from a provider
  // In a real app, get this via ref.watch(currentUserProvider) or similar
  final User currentUser = userMe;

  // --- Navigation Logic ---
  void _navigateToGroup(PaymentGroup group) {
     // Navigate to MainScreen, passing the groupId
     Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(groupId: group.id),
      ),
    );
    // No .then() block needed - Riverpod handles state updates
  }

  // --- MODIFIED: Navigate to Add Group Screen ---
  void _addGroup() {
    // Navigate to the AddGroupScreen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddGroupScreen()),
    );
  }

  // --- Placeholder Actions --- (remain the same for now)
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
   void _onSettings() {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Placeholder: Options/Settings Action'))
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- Use ref.watch to get the group list from the provider ---
    // This automatically rebuilds the widget when the provider's state changes.
    final List<PaymentGroup> groupsToShow = ref.watch(groupServiceProvider);

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Groups'),
        // Use the _addGroup method for the action button
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add New Group',
            onPressed: _addGroup, // Navigate to AddGroupScreen
          ),
        ],
      ),
      body: Column(
          children: [
              // AD Placeholder
              Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  margin: const EdgeInsets.only(bottom: 8.0, left: 16.0, right: 16.0, top: 8.0),
                  decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                      child: Text(
                          'AD Placeholder',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSecondaryContainer),
                      ),
                  ),
              ),
              // --- Group List ---
              Expanded(
                  child: groupsToShow.isEmpty
                    ? Center( // Show message if list is empty
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            'No groups yet.\nTap the + icon to create one!',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                          ),
                        )
                      )
                    : ListView.builder( // Build list if not empty
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      itemCount: groupsToShow.length,
                      itemBuilder: (context, index) {
                          // Get group data directly from the watched list
                          final group = groupsToShow[index];
                          // Use the styled GroupListItem
                          return GroupListItem(
                            group: group,
                            currentUser: currentUser, // Pass currentUser
                            // Pass the navigation callback with the specific group object
                            onTap: () => _navigateToGroup(group),
                          );
                      },
                  ),
              ),
          ],
      ),
       floatingActionButton: FloatingActionButton(
        onPressed: _addGroup, // FAB also navigates to AddGroupScreen
        tooltip: 'Add Group',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomAppBar(
         shape: const AutomaticNotchedShape(
             RoundedRectangleBorder(),
             StadiumBorder(side: BorderSide())),
         padding: const EdgeInsets.symmetric(horizontal: 10.0),
         child: Row(
           mainAxisAlignment: MainAxisAlignment.spaceAround,
           children: <Widget>[
              IconButton(icon: const Icon(Icons.sync), onPressed: _onSync, tooltip: 'Sync'),
              IconButton(icon: const Icon(Icons.filter_list), onPressed: _onFilter, tooltip: 'Filter'),
              IconButton(icon: const Icon(Icons.more_vert), onPressed: _onSettings, tooltip: 'Options'),
           ],
         ),
       ),
    );
  }
}