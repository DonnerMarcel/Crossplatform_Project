// In lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart'; // Needed for firstWhereOrNull if used

import '../models/models.dart';
import '../providers.dart';
import '../utils/constants.dart'; // Assuming constants are defined here
import '../utils/formatters.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final PaymentGroup group;

  const SettingsScreen({super.key, required this.group});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isEditingName = false;
  late TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveGroupName() {
    // Keep existing save logic
    final newName = _nameController.text.trim();
    if (_formKey.currentState!.validate()) { // Validate form before saving
        if (newName.isNotEmpty && newName != widget.group.name) {
            ref.read(groupServiceProvider.notifier).updateGroupName(widget.group.id, newName);
            ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group name updated.'), duration: Duration(seconds: 2))
            );
        }
        setState(() { _isEditingName = false; });
    }
  }

  void _cancelEditName() {
    // Keep existing cancel logic
    setState(() {
      _isEditingName = false;
      _nameController.text = widget.group.name; // Reset controller
    });
  }

  // --- NEW: Method to show confirmation and delete group ---
  Future<void> _confirmAndDeleteGroup() async {
     // Get the current group name safely before showing dialog
     final groupName = ref.read(groupServiceProvider.select(
        (groups) => groups.firstWhereOrNull((g) => g.id == widget.group.id)?.name
     )) ?? widget.group.name; // Fallback to initial name

     // Show confirmation dialog
     final bool? shouldDelete = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
           title: const Text('Delete Group?'),
           content: Text('Are you sure you want to permanently delete the group "$groupName"? This action cannot be undone.'),
           actions: <Widget>[
              TextButton(
                 child: const Text('Cancel'),
                 onPressed: () {
                    Navigator.of(dialogContext).pop(false); // Return false when cancelled
                 },
              ),
              TextButton(
                 style: TextButton.styleFrom(foregroundColor: Colors.red), // Destructive action style
                 child: const Text('Delete'),
                 onPressed: () {
                     Navigator.of(dialogContext).pop(true); // Return true when confirmed
                 },
              ),
           ],
        ),
     );

     // If the user confirmed deletion (and widget is still mounted)
     if (shouldDelete == true && mounted) {
        // Call the delete method from the provider
        ref.read(groupServiceProvider.notifier).deleteGroup(widget.group.id);

        // Show confirmation SnackBar (optional)
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Group "$groupName" deleted.'))
        );

        // Navigate back from the Settings screen (likely back to GroupListScreen)
        // Pop twice: once for the dialog (implicitly done), once for the settings screen
        Navigator.of(context).pop();
     }
  }
  // --- END NEW METHOD ---


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Watch the group state for updates (like name changes)
    final PaymentGroup currentGroup = ref.watch(groupServiceProvider.select(
        (groups) => groups.firstWhere(
              (g) => g.id == widget.group.id,
              // Provide the initial group data as orElse if it might be deleted while watched
              orElse: () => widget.group,
            )));

     // Sync controller if name changed externally and not currently editing
     if (!_isEditingName && _nameController.text != currentGroup.name) {
        // Use addPostFrameCallback to avoid calling setState during build
         WidgetsBinding.instance.addPostFrameCallback((_) {
             if(mounted) { // Check mounted before setting state after async gap
               _nameController.text = currentGroup.name;
             }
         });
     }


    return Form( // Keep Form for name validation
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- Group Name Setting (Editable) ---
            ListTile(
              leading: Icon(Icons.edit_note, color: theme.colorScheme.primary),
              title: const Text('Group Name'),
              subtitle: _isEditingName
                  ? TextFormField( // Keep TextFormField logic
                      controller: _nameController,
                      autofocus: true,
                      decoration: const InputDecoration( hintText: 'Enter new group name', isDense: true,),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) { return 'Name cannot be empty.'; }
                        return null;
                      },
                       onFieldSubmitted: (_) => _saveGroupName(), // Allow saving with Enter key
                    )
                  : Text( currentGroup.name, style: theme.textTheme.bodyLarge,),
              trailing: _isEditingName
                  ? Row( // Keep Save/Cancel buttons
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton( icon: const Icon(Icons.cancel_outlined), color: Colors.grey, tooltip: 'Cancel', onPressed: _cancelEditName,),
                        IconButton( icon: const Icon(Icons.save_alt_outlined), color: theme.colorScheme.primary, tooltip: 'Save Name', onPressed: _saveGroupName,),
                      ],
                    )
                  : IconButton( // Keep Edit button
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit Name',
                      onPressed: () { setState(() { _isEditingName = true; }); },
                    ),
            ),
            const Divider(),

            // --- Portion Cost Setting (Placeholder - Unchanged) ---
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Cost per Portion/Meal (Global)'),
              subtitle: Text(currencyFormatter.format(portionCostPerUser)), // Assuming portionCostPerUser defined in constants
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
              title: Text('Manage Members (${currentGroup.members.length})'),
              subtitle: const Text('Add/remove members for this group'),
              onTap: () {
                 ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Placeholder: Manage members for ${currentGroup.name}'))
                  );
              },
            ),
            const Divider(),

            // --- Delete Group Setting (MODIFIED onTap) ---
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Group'),
              textColor: Colors.red,
              iconColor: Colors.red,
              // Call the new confirmation method on tap
              onTap: _confirmAndDeleteGroup, // <-- CHANGED
            ),
            const Divider(),
          ],
       ),
    );
  }
}