import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

// Change StatelessWidget to ConsumerStatefulWidget
class SettingsScreen extends ConsumerStatefulWidget {
  final PaymentGroup group;

  const SettingsScreen({super.key, required this.group});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

// Change State to ConsumerState
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

  // --- Method to handle saving the edited name ---
  void _saveGroupName() {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty && newName != widget.group.name) {
      ref.read(groupServiceProvider.notifier).updateGroupName(widget.group.id, newName);
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
     setState(() {
      _isEditingName = false;
      _nameController.text = widget.group.name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final PaymentGroup currentGroup = ref.watch(groupServiceProvider.select(
        (groups) => groups.firstWhere(
              (g) => g.id == widget.group.id,
              orElse: () => widget.group,
            )));
     if (!_isEditingName && _nameController.text != currentGroup.name) {
       _nameController.text = currentGroup.name;
     }


    return Form(
       key: _formKey,
       child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- Group Name Setting (Editable) ---
            ListTile(
              leading: Icon(Icons.edit_note, color: theme.colorScheme.primary),
              title: const Text('Group Name'),
              subtitle: _isEditingName
                  ? TextFormField(
                      controller: _nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Enter new group name',
                        isDense: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name cannot be empty.';
                        }
                        return null;
                      },
                       onFieldSubmitted: (_) => _saveGroupName(),
                    )
                  : Text(
                      currentGroup.name,
                      style: theme.textTheme.bodyLarge,
                     ),
              trailing: _isEditingName
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
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
                  : IconButton(
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

            // --- Portion Cost Setting (Placeholder) ---
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

            // --- Manage Members Setting (Placeholder) ---
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

            // --- Delete Group Setting (Placeholder) ---
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Group'),
              textColor: Colors.red,
              iconColor: Colors.red,
              onTap: () {
                  // TODO: Implement confirmation dialog
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