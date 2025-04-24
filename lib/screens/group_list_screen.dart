// lib/screens/group_list_screen.dart
import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import '../models/models.dart';
import 'main_screen.dart';
import '../widgets/group_list/group_list_item.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  List<PaymentGroup> _groups = List.from(dummyGroups);
  final User currentUser = userMe;

  @override
  void initState() {
    super.initState();
  }

  void _navigateToGroup(PaymentGroup group) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(group: group),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        print("Returned from group, forcing rebuild (data source is static).");
      });
    }
  }

  void _addGroup() {
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
    final groupsToShow = _groups;
    final theme = Theme.of(context); // Get theme

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Groups'),
      ),
      body: Column( // Keep Column layout
          children: [
              // --- AD Placeholder MOVED and RESTYLED ---
              Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), // Reduced padding
                  // Margin only at the bottom to separate from list
                  margin: const EdgeInsets.only(bottom: 8.0, left: 16.0, right: 16.0, top: 8.0),
                  decoration: BoxDecoration( // Use decoration for rounded corners
                      color: theme.colorScheme.secondaryContainer.withOpacity(0.4), // More subtle color
                      borderRadius: BorderRadius.circular(12), // Rounded corners
                  ),
                  child: Center(
                      child: Text(
                          'AD Placeholder',
                          // Use themed text style
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSecondaryContainer),
                      ),
                  ),
              ),
              // --- Group List ---
              Expanded( // List takes remaining space
                  child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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