// lib/screens/group_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod

// Import the provider we defined
import '../providers.dart';
// Still need dummy data for currentUser until auth is implemented
import '../data/dummy_data.dart';
import '../models/models.dart';
import 'main_screen.dart'; // Import MainScreen for navigation
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
  final User currentUser = userMe;

  // initState is no longer needed to initialize _groups

  // --- Navigation Logic ---
  void _navigateToGroup(PaymentGroup group) {
     // --- CHANGE HERE: Pass groupId instead of the group object ---
     Navigator.push(
      context,
      MaterialPageRoute(
        // Pass only the ID to MainScreen
        builder: (context) => MainScreen(groupId: group.id),
      ),
    );
    // No .then() block needed - Riverpod handles state updates
  }

  // --- Placeholder Actions --- (remain the same)
  void _addGroup() {
    // TODO: Implement adding a group via the GroupDataService
    // Example: ref.read(groupServiceProvider.notifier).addGroup("New Group", [currentUser]);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Placeholder: Add New Group Action'))
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
   void _onSettings() {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Placeholder: Options/Settings Action'))
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- Use ref.watch to get the group list from the provider ---
    final List<PaymentGroup> groupsToShow = ref.watch(groupServiceProvider);

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Group (Placeholder)',
            onPressed: _addGroup,
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
                    ? Center(
                        child: Text(
                          'No groups yet. Tap + to add one!',
                          style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
                          )
                      )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      itemCount: groupsToShow.length,
                      itemBuilder: (context, index) {
                          final group = groupsToShow[index];
                          // Use the styled GroupListItem
                          return GroupListItem(
                            group: group,
                            currentUser: currentUser,
                            // Pass the callback with the specific group object
                            onTap: () => _navigateToGroup(group),
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