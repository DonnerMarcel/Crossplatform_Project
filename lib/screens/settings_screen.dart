// In lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

import '../models/models.dart';
import '../providers.dart';
import '../utils/constants.dart';
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
      _nameController.text = widget.group.name;
    });
  }

  Future<void> _confirmAndDeleteGroup() async {
     final groupName = ref.read(groupServiceProvider.select(
        (groups) => groups.firstWhereOrNull((g) => g.id == widget.group.id)?.name
     )) ?? widget.group.name; // Fallback to initial name

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
                 style: TextButton.styleFrom(foregroundColor: Colors.red),
                 child: const Text('Delete'),
                 onPressed: () {
                     Navigator.of(dialogContext).pop(true); // Return true when confirmed
                 },
              ),
           ],
        ),
     );


     if (shouldDelete == true && mounted) {
        ref.read(groupServiceProvider.notifier).deleteGroup(widget.group.id);
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Group "$groupName" deleted.'))
        );

        Navigator.of(context).pop();
     }
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
         WidgetsBinding.instance.addPostFrameCallback((_) {
             if(mounted) {
               _nameController.text = currentGroup.name;
             }
         });
     }


    return Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            ListTile(
              leading: Icon(Icons.edit_note, color: theme.colorScheme.primary),
              title: const Text('Group Name'),
              subtitle: _isEditingName
                  ? TextFormField(
                      controller: _nameController,
                      autofocus: true,
                      decoration: const InputDecoration( hintText: 'Enter new group name', isDense: true,),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) { return 'Name cannot be empty.'; }
                        return null;
                      },
                       onFieldSubmitted: (_) => _saveGroupName(),
                    )
                  : Text( currentGroup.name, style: theme.textTheme.bodyLarge,),
              trailing: _isEditingName
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton( icon: const Icon(Icons.cancel_outlined), color: Colors.grey, tooltip: 'Cancel', onPressed: _cancelEditName,),
                        IconButton( icon: const Icon(Icons.save_alt_outlined), color: theme.colorScheme.primary, tooltip: 'Save Name', onPressed: _saveGroupName,),
                      ],
                    )
                  : IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit Name',
                      onPressed: () { setState(() { _isEditingName = true; }); },
                    ),
            ),
            const Divider(),

            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Group'),
              textColor: Colors.red,
              iconColor: Colors.red,
              onTap: _confirmAndDeleteGroup,
            ),
            const Divider(),
          ],
       ),
    );
  }
}