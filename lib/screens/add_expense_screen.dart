import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/profile_image_cache_provider.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final List<User> groupMembers;
  final String? preselectedPayerId;
  final String currencySymbol;

  const AddExpenseScreen({
    super.key,
    required this.groupMembers,
    this.preselectedPayerId,
    required this.currencySymbol,
  });

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  User? _selectedPayer;
  DateTime _selectedDate = DateTime.now();
  late DateFormat _dateFormatter;

  @override
  void initState() {
    super.initState();
    _dateFormatter = DateFormat('dd.MM.yyyy');
    _updateDateText();

    if (widget.preselectedPayerId != null && widget.groupMembers.isNotEmpty) {
      try {
        _selectedPayer = widget.groupMembers.firstWhere(
              (member) => member.id == widget.preselectedPayerId,
        );
      } catch (e) {
        if (widget.groupMembers.isNotEmpty) {
          _selectedPayer = widget.groupMembers.first;
        }
      }
    } else if (widget.groupMembers.isNotEmpty) {
      _selectedPayer = widget.groupMembers.first;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _updateDateText() {
    _dateController.text = _dateFormatter.format(_selectedDate);
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _updateDateText();
      });
    }
  }

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      final amountString = _amountController.text.replaceAll(',', '.');
      final amount = double.tryParse(amountString);

      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid positive amount.')),
        );
        return;
      }

      if (_selectedPayer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a payer.')),
        );
        return;
      }

      final newExpense = Expense(
        id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
        description: _descriptionController.text.trim(),
        amount: amount,
        date: _selectedDate,
        payerId: _selectedPayer!.id,
      );

      Navigator.pop(context, newExpense);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct the errors above.')),
      );
    }
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    String? labelText,
    required IconData prefixIconData,
    String? suffixText,
    Color? prefixIconColor,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      filled: true,
      fillColor: Colors.black.withOpacity(0.04),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      prefixIcon: Icon(prefixIconData,
          color: prefixIconColor ?? theme.colorScheme.primary.withOpacity(0.8),
          size: 20),
      suffixText: suffixText,
      isDense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageCache = ref.watch(profileImageCacheProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Expense'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _descriptionController,
                decoration: _buildInputDecoration(
                  labelText: 'Description',
                  hintText: 'e.g., Groceries, Dinner',
                  prefixIconData: Icons.description_outlined,
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _amountController,
                decoration: _buildInputDecoration(
                  labelText: 'Amount',
                  hintText: '0.00',
                  prefixIconData: Icons.calculate_outlined,
                  suffixText: widget.currencySymbol,
                ),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount.';
                  }
                  final amountString = value.replaceAll(',', '.');
                  final amount = double.tryParse(amountString);
                  if (amount == null) {
                    return 'Please enter a valid number.';
                  }
                  if (amount <= 0) {
                    return 'Please enter a positive amount.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<User>(
                value: _selectedPayer,
                items: widget.groupMembers.map((User user) {
                  final imageUrl = imageCache[user.id];

                  return DropdownMenuItem<User>(
                    value: user,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: imageUrl == null
                              ? (user.profileColor ??
                              theme.colorScheme.primaryContainer)
                              : null,
                          foregroundColor: theme.colorScheme.onPrimaryContainer,
                          backgroundImage:
                          imageUrl != null ? NetworkImage(imageUrl) : null,
                          child: imageUrl == null
                              ? Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(fontSize: 10),
                          )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(user.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (User? newValue) {
                  setState(() {
                    _selectedPayer = newValue;
                  });
                },
                decoration: _buildInputDecoration(
                  labelText: 'Paid by',
                  hintText: 'Select who paid',
                  prefixIconData: Icons.person_outline,
                ),
                validator: (value) => value == null && widget.groupMembers.isNotEmpty
                    ? 'Please select who paid.'
                    : null,
                isExpanded: true,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: _buildInputDecoration(
                  labelText: 'Date',
                  hintText: 'Select date',
                  prefixIconData: Icons.calendar_today_outlined,
                ),
                onTap: () {
                  FocusScope.of(context).requestFocus(FocusNode());
                  _pickDate(context);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a date.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Save Expense'),
                onPressed: _saveExpense,
                style: ElevatedButton.styleFrom(
                  foregroundColor: theme.colorScheme.onPrimary,
                  backgroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle:
                  theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
