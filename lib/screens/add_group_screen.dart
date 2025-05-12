import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

// Assuming correct paths
import '../models/models.dart';
import '../providers.dart';
import '../data/dummy_data.dart'; // Needed for userMe initialization example

class AddGroupScreen extends ConsumerStatefulWidget {
  const AddGroupScreen({super.key});

  @override
  ConsumerState<AddGroupScreen> createState() => _AddGroupScreenState();
}

class _AddGroupScreenState extends ConsumerState<AddGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final _newUserNameController = TextEditingController(); // For dialog
  final _searchUserController = TextEditingController();

  // Use Set for efficient add/remove/lookup of selected members
  final Set<User> _selectedMembers = {};
  // Keep the full list and the filtered list separate
  List<User> _allAvailableUsers = [];
  List<User> _filteredAvailableUsers = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Initial fetch of all users
    _allAvailableUsers = ref.read(groupServiceProvider.notifier).getAllUsers();
    // Add 'Me' user initially by default
      final User? currentUser = _allAvailableUsers.firstWhereOrNull(
        (user) => user.id == userMe.id // Use ID for reliable comparison
      );
      if (currentUser != null) {
        _selectedMembers.add(currentUser);
      }
      // Initially, the filtered list is the full list minus already selected
      _updateFilteredUsers();

      // Add listener for search
      _searchUserController.addListener(() {
        setState(() {
          _searchQuery = _searchUserController.text;
          _updateFilteredUsers();
        });
      });
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _newUserNameController.dispose();
    _searchUserController.dispose();
    super.dispose();
  }

  void _updateFilteredUsers() {
      // Filter based on search query and exclude already selected members
    _filteredAvailableUsers = _allAvailableUsers.where((user) {
       final isSelected = _selectedMembers.any((selected) => selected.id == user.id);
       final matchesSearch = user.name.toLowerCase().contains(_searchQuery.toLowerCase());
       return !isSelected && matchesSearch; // Show if not selected AND matches search
    }).toList();
  }

  // --- Toggle User Selection ---
  void _toggleUserSelection(User user) {
    setState(() {
       final isSelected = _selectedMembers.any((selected) => selected.id == user.id);
       if (isSelected) {
         _selectedMembers.removeWhere((selected) => selected.id == user.id);
       } else {
         _selectedMembers.add(user);
       }
        // Update filtered list after selection change
        _updateFilteredUsers();
    });
  }

    // --- Method to remove user from selected Chips ---
    void _removeSelectedUser(User user) {
       setState(() {
            _selectedMembers.removeWhere((selected) => selected.id == user.id);
             // Update filtered list as this user is now available again
            _updateFilteredUsers();
       });
    }


  // --- MODIFIED: Show Dialog to Add New User ---
  void _showAddUserDialog() {
      _newUserNameController.clear(); // Clear previous input
    showDialog(
        context: context,
        builder: (dialogContext) {
          // Use a local GlobalKey for the dialog form if more complex validation is needed
          final dialogFormKey = GlobalKey<FormState>();
          return AlertDialog(
            title: const Text("Add New User"),
            content: Form( // Wrap content in Form for validation
             key: dialogFormKey,
             child: TextFormField(
                controller: _newUserNameController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Enter name',
                  labelText: 'User Name',
                ),
                validator: (value) { // Basic validation within dialog
                   if (value == null || value.trim().isEmpty) {
                     return 'Please enter a name.';
                   }
                    // Check if user already exists (case-insensitive)
                    bool exists = _allAvailableUsers.any((user) => user.name.toLowerCase() == value.trim().toLowerCase());
                    if (exists) {
                         return "'${value.trim()}' already exists.";
                    }
                   return null;
                },
                 autovalidateMode: AutovalidateMode.onUserInteraction, // Validate as user types
              ),
            ),
            actions: [
                 TextButton(
                     onPressed: () => Navigator.pop(dialogContext),
                     child: const Text("Cancel")
                 ),
                 TextButton(
                     onPressed: () {
                         // Validate the dialog form before processing
                         if (dialogFormKey.currentState?.validate() ?? false) {
                             final newName = _newUserNameController.text.trim();
                             _addNewUserFromDialog(newName, dialogContext);
                         }
                     },
                     child: const Text("Add")
                 ),
            ],
          );
        });
  }

  // --- Logic to add user (called from dialog) ---
  void _addNewUserFromDialog(String name, BuildContext dialogContext) {
      // Call the service to add the user
      final newUser = ref.read(groupServiceProvider.notifier).addUser(name);

      // Update local state
      setState(() {
        _allAvailableUsers = ref.read(groupServiceProvider.notifier).getAllUsers(); // Refresh full list
        _selectedMembers.add(newUser); // Add and select the new user
        _updateFilteredUsers(); // Update filtered list
      });

       Navigator.pop(dialogContext); // Close the dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User '${newUser.name}' added and selected."))
      );
  }

  // --- Method to save the new group ---
  void _saveGroup() {
    if (_formKey.currentState!.validate()) {
       final groupName = _groupNameController.text.trim();
       // Ensure current user is always included if logic requires
       // final User? currentUser = _allAvailableUsers.firstWhereOrNull((user) => user.id == userMe.id);
       // if (currentUser != null && !_selectedMembers.any((u) => u.id == currentUser.id)) {
       //     _selectedMembers.add(currentUser);
       // }

       if (_selectedMembers.length < 2) { // Usually groups need at least 2 members
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Please select at least one other member.'))
         );
         return;
       }

       ref.read(groupServiceProvider.notifier).addGroup(groupName, _selectedMembers.toList());

       Navigator.of(context).pop(); // Go back after successful creation
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text("Group '$groupName' created."))
       );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Watch might be better if user list changes elsewhere, but read is fine if static
    // _allAvailableUsers = ref.watch(groupServiceProvider.notifier).getAllUsers(); // Alternative

    return Scaffold(
       appBar: AppBar(
         title: const Text('Create New Group'),
       ),
       body: SingleChildScrollView(
         padding: const EdgeInsets.all(16.0),
         child: Form(
           key: _formKey,
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               // --- Group Name Card ---
               Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text('Group Name', style: theme.textTheme.titleMedium),
                         const SizedBox(height: 12),
                         TextFormField(
                           controller: _groupNameController,
                           decoration: InputDecoration(
                             hintText: 'e.g., Weekend Trip, Office Lunch',
                             // Modern Input Style
                             filled: true,
                             fillColor: Colors.black.withOpacity(0.04),
                             border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none, // No border when filled
                             ),
                             prefixIcon: Icon(Icons.group_work_outlined, color: theme.colorScheme.primary),
                           ),
                           validator: (value) {
                             if (value == null || value.trim().isEmpty) {
                               return 'Please enter a group name.';
                             }
                             return null;
                           },
                         ),
                       ],
                    ),
                  ),
               ),
               const SizedBox(height: 24),

                // --- MODIFIED: Selected Members Section (More Compact) ---
                Text('Selected Members (${_selectedMembers.length})', style: theme.textTheme.titleMedium),
                const SizedBox(height: 6), // Reduced vertical space
                _selectedMembers.isEmpty
                    ? const Padding( // Added padding for consistent vertical space when empty
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          " Select users from the list below.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : Container( // Using Container for more control, optionally add border/background
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), // Reduced padding
                        // Optional: Add subtle background or border if needed
                        // decoration: BoxDecoration(
                        //    color: theme.colorScheme.secondaryContainer.withOpacity(0.05),
                        //    border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
                        //    borderRadius: BorderRadius.circular(8),
                        // ),
                        child: Wrap(
                          spacing: 6.0, // Horizontal gap between chips
                          runSpacing: 0.0, // Vertical gap between lines of chips (set to 0 for compactness)
                          children: _selectedMembers.map((user) {
                            return InputChip(
                              key: ValueKey(user.id), // Important for stateful updates
                              label: Text(user.name),
                              labelPadding: const EdgeInsets.symmetric(horizontal: 4.0), // Reduced label padding
                              avatar: CircleAvatar(
                                radius: 12, // Smaller avatar
                                backgroundColor: user.profileColor ?? theme.colorScheme.primaryContainer,
                                foregroundColor: theme.colorScheme.onPrimaryContainer,
                                child: Text(user.name.substring(0, 1), style: const TextStyle(fontSize: 10)), // Smaller font
                              ),
                              onDeleted: () => _removeSelectedUser(user),
                              deleteIconColor: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                              // Optional: Use a slightly different background for the chip itself
                              backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                              // Using compact density is good
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(2.0), // Reduced padding inside the chip
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Reduce tap area slightly
                            );
                          }).toList(),
                        ),
                      ),
                const SizedBox(height: 20), // Adjusted space before next section


               // --- Available Members Card ---
                 Card(
                   elevation: 1,
                   child: Padding(
                     padding: const EdgeInsets.all(16.0),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                           Text('Available Users', style: theme.textTheme.titleMedium),
                           const SizedBox(height: 8),
                           // --- Search Field ---
                           TextField(
                             controller: _searchUserController,
                             decoration: InputDecoration(
                               hintText: 'Search users...',
                               prefixIcon: const Icon(Icons.search, size: 20),
                               isDense: true,
                               filled: true,
                               fillColor: Colors.black.withOpacity(0.04),
                               border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                               ),
                               // Clear button
                               suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                     icon: const Icon(Icons.clear, size: 20),
                                     onPressed: () {
                                        _searchUserController.clear();
                                        // Trigger filter update via listener
                                     },
                                   )
                                  : null,
                             ),
                           ),
                           const SizedBox(height: 8),
                           // --- List of Available Users ---
                           Container(
                             // Use constraints or Expanded if needed, but ListView often handles this
                             constraints: const BoxConstraints(maxHeight: 180), // Limit height and make scrollable
                             decoration: BoxDecoration(
                                border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                                borderRadius: BorderRadius.circular(8),
                             ),
                             child: _filteredAvailableUsers.isEmpty
                               ? Center(child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(_searchQuery.isEmpty ? 'No other users available.' : 'No users match search.', style: const TextStyle(color: Colors.grey)),
                                  ))
                               : ListView.builder(
                                   shrinkWrap: true,
                                   itemCount: _filteredAvailableUsers.length,
                                   itemBuilder: (context, index) {
                                     final user = _filteredAvailableUsers[index];
                                     // Cannot select the current user again if already selected (handled by filter)
                                     // final bool isSelected = _selectedMembers.any((selected) => selected.id == user.id);

                                     return ListTile(
                                       leading: CircleAvatar(
                                          backgroundColor: user.profileColor ?? theme.colorScheme.primaryContainer,
                                          foregroundColor: theme.colorScheme.onPrimaryContainer,
                                          radius: 16,
                                          child: Text(user.name.substring(0, 1), style: const TextStyle(fontSize: 12)),
                                       ),
                                       title: Text(user.name),
                                       // Add button instead of checkbox
                                       trailing: IconButton(
                                          icon: const Icon(Icons.add_circle_outline),
                                          color: theme.colorScheme.primary,
                                          tooltip: 'Add ${user.name}',
                                          onPressed: () => _toggleUserSelection(user),
                                       ),
                                       dense: true,
                                       onTap: () => _toggleUserSelection(user), // Allow tapping whole row
                                     );
                                   },
                                 ),
                           ),
                           const SizedBox(height: 16),
                           // --- Add New User Button (triggers dialog) ---
                            Center(
                              child: TextButton.icon( // Use TextButton for less emphasis
                                icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                                label: const Text('Add New User Manually'),
                                onPressed: _showAddUserDialog, // Show dialog
                                style: TextButton.styleFrom(
                                   foregroundColor: theme.colorScheme.secondary,
                                ),
                              ),
                            ),
                       ],
                     ),
                   ),
                 ),

               const SizedBox(height: 32),

               // --- Create Group Button ---
               SizedBox( // Wrap in SizedBox to allow full width
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.group_add_outlined),
                    label: const Text('Create Group'),
                    onPressed: _saveGroup,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onPrimary,
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16), // Generous padding
                      textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), // Bolder text
                    ),
                  ),
               ),
             ],
           ),
         ),
       ),
    );
  }
}