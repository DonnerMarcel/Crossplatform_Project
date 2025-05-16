import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../providers.dart';

class AddGroupScreen extends ConsumerStatefulWidget {
  const AddGroupScreen({super.key});

  @override
  ConsumerState<AddGroupScreen> createState() => _AddGroupScreenState();
}

class _AddGroupScreenState extends ConsumerState<AddGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final _newUserNameController = TextEditingController();
  final _searchUserController = TextEditingController();

  final Set<User> _selectedMembers = {};
  List<User> _allAvailableUsers = [];
  List<User> _filteredAvailableUsers = [];
  String _searchQuery = '';
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _allAvailableUsers = ref.read(groupServiceProvider.notifier).getAllUsers();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initCurrentUser();
    });

    _searchUserController.addListener(() {
      setState(() {
        _searchQuery = _searchUserController.text;
        _updateFilteredUsers();
      });
    });
  }

  Future<void> _initCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId != null) {
      final user = _allAvailableUsers.firstWhereOrNull((u) => u.id == userId);
      if (user != null) {
        setState(() {
          _currentUser = user;
          _selectedMembers.add(user);
        });
      }
    }

    _updateFilteredUsers();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _newUserNameController.dispose();
    _searchUserController.dispose();
    super.dispose();
  }

  void _updateFilteredUsers() {
    _filteredAvailableUsers = _allAvailableUsers.where((user) {
      final isSelected = _selectedMembers.any((selected) => selected.id == user.id);
      final matchesSearch = user.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return !isSelected && matchesSearch;
    }).toList();
  }

  void _toggleUserSelection(User user) {
    setState(() {
      final isSelected = _selectedMembers.any((selected) => selected.id == user.id);
      if (isSelected) {
        _selectedMembers.removeWhere((selected) => selected.id == user.id);
      } else {
        _selectedMembers.add(user);
      }
      _updateFilteredUsers();
    });
  }

  void _removeSelectedUser(User user) {
    if (user.id == _currentUser?.id) return;
    setState(() {
      _selectedMembers.removeWhere((selected) => selected.id == user.id);
      _updateFilteredUsers();
    });
  }

  void _showAddUserDialog() {
    _newUserNameController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) {
        final dialogFormKey = GlobalKey<FormState>();
        return AlertDialog(
          title: const Text("Add New User"),
          content: Form(
            key: dialogFormKey,
            child: TextFormField(
              controller: _newUserNameController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Enter name',
                labelText: 'User Name',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name.';
                }
                bool exists = _allAvailableUsers.any(
                        (user) => user.name.toLowerCase() == value.trim().toLowerCase());
                if (exists) {
                  return "'${value.trim()}' already exists.";
                }
                return null;
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Cancel")),
            TextButton(
                onPressed: () {
                  if (dialogFormKey.currentState?.validate() ?? false) {
                    final newName = _newUserNameController.text.trim();
                    _addNewUserFromDialog(newName, dialogContext);
                  }
                },
                child: const Text("Add")),
          ],
        );
      },
    );
  }

  void _addNewUserFromDialog(String name, BuildContext dialogContext) {
    final newUser = ref.read(groupServiceProvider.notifier).addUser(name);

    setState(() {
      _allAvailableUsers = ref.read(groupServiceProvider.notifier).getAllUsers();
      _selectedMembers.add(newUser);
      _updateFilteredUsers();
    });

    Navigator.pop(dialogContext);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("User '${newUser.name}' added and selected.")));
  }

  void _saveGroup() {
    if (_formKey.currentState!.validate()) {
      final groupName = _groupNameController.text.trim();

      if (_selectedMembers.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select at least one other member.')));
        return;
      }

      ref.read(groupServiceProvider.notifier).addGroup(groupName, _selectedMembers.toList());

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Group '$groupName' created.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.04),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.group_work_outlined,
                              color: theme.colorScheme.primary),
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
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Selected Members (${_selectedMembers.length})',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 6),
                      _selectedMembers.isEmpty
                          ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          " Select users from the list below.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                          : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        child: Wrap(
                          spacing: 6.0,
                          runSpacing: 0.0,
                          children: _selectedMembers.map((user) {
                            return InputChip(
                              key: ValueKey(user.id),
                              label: Text(user.id == _currentUser?.id ? '${user.name} (You)' : user.name),
                              labelPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                              avatar: CircleAvatar(
                                radius: 12,
                                backgroundColor: user.profileColor ?? theme.colorScheme.primaryContainer,
                                foregroundColor: theme.colorScheme.onPrimaryContainer,
                                child: Text(user.name.substring(0, 1), style: const TextStyle(fontSize: 10)),
                              ),
                              onDeleted: user.id == _currentUser?.id ? null : () => _removeSelectedUser(user),
                              deleteIconColor: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                              backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(2.0),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('Available Users', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
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
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchUserController.clear();
                            },
                          )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 180),
                        decoration: BoxDecoration(
                          border:
                          Border.all(color: theme.dividerColor.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _filteredAvailableUsers.isEmpty
                            ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                  _searchQuery.isEmpty
                                      ? 'No other users available.'
                                      : 'No users match search.',
                                  style: const TextStyle(color: Colors.grey)),
                            ))
                            : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _filteredAvailableUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredAvailableUsers[index];

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: user.profileColor ??
                                    theme.colorScheme.primaryContainer,
                                foregroundColor:
                                theme.colorScheme.onPrimaryContainer,
                                radius: 16,
                                child: Text(user.name.substring(0, 1),
                                    style: const TextStyle(fontSize: 12)),
                              ),
                              title: Text(user.name),
                              trailing: IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                color: theme.colorScheme.primary,
                                tooltip: 'Add ${user.name}',
                                onPressed: () => _toggleUserSelection(user),
                              ),
                              dense: true,
                              onTap: () => _toggleUserSelection(user),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton.icon(
                          icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                          label: const Text('Add New User Manually'),
                          onPressed: _showAddUserDialog,
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.group_add_outlined),
                  label: const Text('Create Group'),
                  onPressed: _saveGroup,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onPrimary,
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
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
