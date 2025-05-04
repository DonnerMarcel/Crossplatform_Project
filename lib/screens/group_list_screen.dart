import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Assuming these imports are correct for your project structure
import '../providers.dart';
import '../data/dummy_data.dart'; // Make sure userMe is defined here or fetched via provider
import '../models/models.dart';
import 'main_screen.dart'; // Import MainScreen for navigation
import 'add_group_screen.dart'; // Import the new screen
import '../widgets/group_list/group_list_item.dart'; // Import the list item widget

// Change StatefulWidget to ConsumerStatefulWidget
class GroupListScreen extends ConsumerStatefulWidget {
  const GroupListScreen({super.key});

  @override
  ConsumerState<GroupListScreen> createState() => _GroupListScreenState();
}

// Change State to ConsumerState
class _GroupListScreenState extends ConsumerState<GroupListScreen> {
  // Assuming userMe is defined globally or fetched via provider
  final User currentUser = userMe;

  // --- Navigation Logic ---
  void _navigateToGroup(PaymentGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(groupId: group.id),
      ),
    );
  }

  // --- MODIFIED: Navigate to Add Group Screen ---
  void _addGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddGroupScreen()),
    );
  }

  // --- Placeholder Actions --- (remain the same for now)
  void _onSync() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Placeholder: Sync Action')));
  }

  void _onFilter() {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Placeholder: Filter Action')));
  }

  void _onSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Placeholder: Options/Settings Action')));
  }

  @override
  Widget build(BuildContext context) {
    final List<PaymentGroup> groupsToShow = ref.watch(groupServiceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      // No AppBar
      body: SafeArea( // <--- SafeArea ADDED HERE
        child: Column( // <--- Column is now child of SafeArea
          children: [
            // --- AD Placeholder ---
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              margin: const EdgeInsets.only(
                  bottom: 8.0, left: 16.0, right: 16.0 /*, top: 0 */), // Note: Top margin might be adjusted/removed
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'AD Placeholder',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSecondaryContainer),
                ),
              ),
            ),
            // --- Group List ---
            Expanded(
              child: groupsToShow.isEmpty
                  ? Center(
                      child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'No groups yet.\nTap the + icon to create one!',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      itemCount: groupsToShow.length,
                      itemBuilder: (context, index) {
                        final group = groupsToShow[index];

                        return GroupListItem(
                          group: group,
                          currentUser: currentUser,
                          onTap: () => _navigateToGroup(group),
                        );
                      },
                    ),
            ),
          ],
        ),
      ), // <--- End of SafeArea
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addGroup,
        tooltip: 'Create a new group',
        icon: const Icon(Icons.add),
        label: const Text('Add Group'),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
                icon: const Icon(Icons.sync),
                onPressed: _onSync,
                tooltip: 'Sync'),
            IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _onFilter,
                tooltip: 'Filter'),
            // SizedBox needed for spacing with centerDocked FAB
            // Adjust width if needed
            // const SizedBox(width: 40),
            IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: _onSettings,
                tooltip: 'Options'),
          ],
        ),
      ),
    );
  }
}

// Ensure userMe is defined (e.g., from dummy_data.dart or via provider)
// Example if using dummy data directly:
// final User userMe = User(id: '1', name: 'Me', profileColor: Colors.deepPurple);