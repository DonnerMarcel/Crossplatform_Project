// lib/screens/add_group_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart'; // Import for firstWhereOrNull

import '../models/models.dart';
import '../providers.dart'; // To access GroupDataService

class AddGroupScreen extends ConsumerStatefulWidget {
  const AddGroupScreen({super.key});

  @override
  ConsumerState<AddGroupScreen> createState() => _AddGroupScreenState();
}

class _AddGroupScreenState extends ConsumerState<AddGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final _newUserNameController = TextEditingController();

  // Local state to keep track of selected members
  final Set<User> _selectedMembers = {};
  // Local state to hold the list of all available users
  List<User> _availableUsers = [];
  // State to control visibility of the 'add new user' input
  bool _showAddUserField = false;

  @override
  void initState() {
    super.initState();
    // Load initial available users when the screen loads
    _availableUsers = ref.read(groupServiceProvider.notifier).getAllUsers();

    // Automatically select the current user (if available)
    // --- FIX: Declare currentUser as nullable (User?) ---
    // --- FIX: Use firstWhereOrNull for safer lookup ---
    final User? currentUser = _availableUsers.firstWhereOrNull(
        (user) => user.name == 'Me' // Assuming 'Me' is the name in dummy_data
        // No orElse needed with firstWhereOrNull, it returns null if not found
        );

    // Only add if currentUser was actually found
    if (currentUser != null) {
      _selectedMembers.add(currentUser);
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _newUserNameController.dispose();
    super.dispose();
  }

  // --- Method to add a newly created user ---
  void _addNewUser() {
    final newName = _newUserNameController.text.trim();
    if (newName.isNotEmpty) {
      // Check if user already exists (simple name check for now)
      bool exists = _availableUsers.any((user) => user.name.toLowerCase() == newName.toLowerCase());
      if (exists) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("User '$newName' already exists."))
         );
         return;
      }

      // Call the service to add the user
      final newUser = ref.read(groupServiceProvider.notifier).addUser(newName);

      // Update local state: add to available users and select them
      setState(() {
        // Ensure the list is updated before modifying selection
        _availableUsers = ref.read(groupServiceProvider.notifier).getAllUsers();
        _selectedMembers.add(newUser);
        _showAddUserField = false; // Hide input field
        _newUserNameController.clear(); // Clear the input field
      });
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text("User '${newUser.name}' added and selected."))
       );
    } else {
       // Hide field if name is empty and button is pressed again
       setState(() {
         _showAddUserField = false;
       });
    }
  }

  // --- Method to save the new group ---
  void _saveGroup() {
    if (_formKey.currentState!.validate()) {
      final groupName = _groupNameController.text.trim();
      if (_selectedMembers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one member.'))
        );
        return;
      }

      // Call the service to add the group
      ref.read(groupServiceProvider.notifier).addGroup(groupName, _selectedMembers.toList());

      // Navigate back to the previous screen
      Navigator.of(context).pop();
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text("Group '$groupName' created."))
       );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Fetch the latest user list in build in case it changed via _addNewUser
    // Note: This could be optimized if user list changes are rare during build
    _availableUsers = ref.watch(groupServiceProvider.notifier).getAllUsers();


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
              // --- Group Name Input ---
              Text('Group Name', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _groupNameController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Weekend Trip, Office Lunch',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a group name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // --- Member Selection ---
              Text('Select Members', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              // List of available users with checkboxes
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(maxHeight: 200), // Limit height
                child: ListView.builder(
                  shrinkWrap: true, // Important inside SingleChildScrollView
                  itemCount: _availableUsers.length,
                  itemBuilder: (context, index) {
                    final user = _availableUsers[index];
                    // Check selection based on the current _selectedMembers set
                    final bool isSelected = _selectedMembers.any((selected) => selected.id == user.id);

                    return CheckboxListTile(
                      secondary: CircleAvatar( // Show user avatar
                         backgroundColor: user.profileColor ?? theme.colorScheme.primaryContainer,
                         foregroundColor: theme.colorScheme.onPrimaryContainer,
                         radius: 16,
                         child: Text(user.initials, style: const TextStyle(fontSize: 12)),
                      ),
                      title: Text(user.name),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            // Add the actual user object from _availableUsers
                            _selectedMembers.add(user);
                          } else {
                             // Remove based on ID match
                            _selectedMembers.removeWhere((selected) => selected.id == user.id);
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading, // Checkbox on left
                      dense: true,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // --- Add New User Section ---
              if (!_showAddUserField) // Show button if field is hidden
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add New User'),
                  onPressed: () {
                    setState(() {
                      _showAddUserField = true;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                     foregroundColor: theme.colorScheme.secondary,
                     side: BorderSide(color: theme.colorScheme.secondary.withOpacity(0.5)),
                  ),
                ),

              if (_showAddUserField) // Show input field and buttons if requested
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text('New User Name', style: theme.textTheme.labelLarge),
                     const SizedBox(height: 4),
                     Row(
                       children: [
                         Expanded(
                           child: TextFormField(
                             controller: _newUserNameController,
                             autofocus: true,
                             decoration: const InputDecoration(
                               hintText: 'Enter name',
                               border: OutlineInputBorder(),
                               isDense: true,
                             ),
                             onFieldSubmitted: (_) => _addNewUser(), // Add on keyboard done
                           ),
                         ),
                         IconButton(
                           icon: const Icon(Icons.cancel_outlined),
                           color: Colors.grey,
                           tooltip: 'Cancel Add User',
                           onPressed: () {
                             setState(() {
                               _showAddUserField = false;
                               _newUserNameController.clear();
                             });
                           },
                         ),
                         IconButton(
                           icon: const Icon(Icons.add_circle_outline),
                           color: theme.colorScheme.primary,
                           tooltip: 'Add User',
                           onPressed: _addNewUser, // Call add user method
                         ),
                       ],
                     ),
                  ],
                ),


              const SizedBox(height: 32),

              // --- Create Group Button ---
              Center( // Center the button
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.group_add_outlined),
                  label: const Text('Create Group'),
                  onPressed: _saveGroup,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onPrimary,
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    textStyle: theme.textTheme.titleMedium,
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