// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod

// Import models, providers, constants, formatters
import '../models/models.dart';
import '../providers.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

// Change StatelessWidget to ConsumerStatefulWidget
class SettingsScreen extends ConsumerStatefulWidget {
  // Still receives the group object from MainScreen
  // (MainScreen currently fetches it via provider and passes it down)
  final PaymentGroup group;

  const SettingsScreen({super.key, required this.group});

  @override
  // Change State to ConsumerState
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

// Change State to ConsumerState
class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // State variables for editing
  bool _isEditingName = false;
  late TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>(); // For optional validation

  @override
  void initState() {
    super.initState();
    // Initialize the controller with the current group name
    _nameController = TextEditingController(text: widget.group.name);
  }

  @override
  void dispose() {
    // Dispose the controller when the widget is removed
    _nameController.dispose();
    super.dispose();
  }

  // --- Method to handle saving the edited name ---
  void _saveGroupName() {
    // Optional: Validate the form if needed
    // if (!_formKey.currentState!.validate()) {
    //   return;
    // }
    final newName = _nameController.text.trim();
    // Check if name actually changed
    if (newName.isNotEmpty && newName != widget.group.name) {
      // Use ref.read to call the method on the notifier (GroupDataService)
      ref.read(groupServiceProvider.notifier).updateGroupName(widget.group.id, newName);
      // Show feedback (optional)
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Group name updated.'), duration: Duration(seconds: 2))
       );
    }
     // Exit editing mode
     setState(() {
      _isEditingName = false;
    });
  }

  // --- Method to cancel editing ---
  void _cancelEditName() {
     // Exit editing mode without saving
     setState(() {
      _isEditingName = false;
      // Optional: Reset controller text if user typed something
      _nameController.text = widget.group.name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // --- Watch the provider to get the latest group data ---
    // This ensures the displayed name updates if changed elsewhere potentially
    // Note: We select the specific group again here. If MainScreen already
    // watches and passes the updated group object, this might be redundant,
    // but it's safer if SettingsScreen could theoretically outlive MainScreen's state.
    final PaymentGroup currentGroup = ref.watch(groupServiceProvider.select(
        (groups) => groups.firstWhere(
              (g) => g.id == widget.group.id,
              orElse: () => widget.group, // Fallback to initially passed group if somehow not found
            )));
    // Update controller text if group name changed externally (less likely here but good practice)
     if (!_isEditingName && _nameController.text != currentGroup.name) {
       _nameController.text = currentGroup.name;
     }


    return Form( // Wrap list in Form if using validation
       key: _formKey,
       child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- MODIFIED: Group Name Setting (Editable) ---
            ListTile(
              leading: Icon(Icons.edit_note, color: theme.colorScheme.primary),
              title: const Text('Group Name'),
              // Display either Text or TextFormField based on editing state
              subtitle: _isEditingName
                  ? TextFormField(
                      controller: _nameController,
                      autofocus: true, // Focus the field when editing starts
                      decoration: const InputDecoration(
                        hintText: 'Enter new group name',
                        isDense: true, // Make field less tall
                      ),
                      validator: (value) { // Optional validation
                        if (value == null || value.trim().isEmpty) {
                          return 'Name cannot be empty.';
                        }
                        return null;
                      },
                       onFieldSubmitted: (_) => _saveGroupName(), // Save on keyboard done action
                    )
                  : Text(
                      currentGroup.name, // Display current name from watched state
                      style: theme.textTheme.bodyLarge,
                     ),
              // Display Edit or Save/Cancel buttons based on editing state
              trailing: _isEditingName
                  ? Row( // Use Row for multiple icons
                      mainAxisSize: MainAxisSize.min, // Prevent Row from taking full width
                      children: [
                        IconButton(
                          icon: const Icon(Icons.cancel_outlined),
                          color: Colors.grey,
                          tooltip: 'Cancel',
                          onPressed: _cancelEditName,
                        ),
                        IconButton(
                          icon: const Icon(Icons.save_alt_outlined),
                          color: theme.colorScheme.primary,
                          tooltip: 'Save Name',
                          onPressed: _saveGroupName,
                        ),
                      ],
                    )
                  : IconButton( // Single Edit button
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit Name',
                      onPressed: () {
                        setState(() {
                          _isEditingName = true;
                        });
                      },
                    ),
            ),
            const Divider(),

            // --- Portion Cost Setting (Placeholder - Unchanged) ---
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Cost per Portion/Meal (Global)'),
              subtitle: Text(currencyFormatter.format(portionCostPerUser)),
              onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Placeholder: Change global portion cost action'))
                  );
              },
            ),
            const Divider(),

            // --- Manage Members Setting (Placeholder - Unchanged) ---
            ListTile(
              leading: const Icon(Icons.people_outline),
              // Use member count from currentGroup state
              title: Text('Manage Members (${currentGroup.members.length})'),
              subtitle: const Text('Add/remove members for this group'),
              onTap: () {
                 ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Placeholder: Manage members for ${currentGroup.name}'))
                  );
              },
            ),
            const Divider(),

            // --- Delete Group Setting (Placeholder - Unchanged) ---
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Group'),
              textColor: Colors.red,
              iconColor: Colors.red,
              onTap: () {
                  // TODO: Implement confirmation dialog
                  // Example call: ref.read(groupServiceProvider.notifier).deleteGroup(currentGroup.id);
                  // Need to handle navigation after deletion (e.g., pop back to list)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Placeholder: Delete group ${currentGroup.name} action'))
                  );
              },
            ),
            const Divider(),
          ],
       ),
    );
  }
}