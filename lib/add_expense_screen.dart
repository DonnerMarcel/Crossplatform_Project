// lib/add_expense_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models.dart';

class AddExpenseScreen extends StatefulWidget {
  final List<User> groupMembers;
  final String? preselectedPayerId;
  final String currencySymbol; // <-- ADD THIS PARAMETER

  const AddExpenseScreen({
    super.key,
    required this.groupMembers,
    this.preselectedPayerId,
    required this.currencySymbol, // <-- MAKE IT REQUIRED
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  // ... (initState, dispose, _pickDate, _saveExpense remain the same) ...
    final _formKey = GlobalKey<FormState>();
    final _descriptionController = TextEditingController();
    final _amountController = TextEditingController();
    User? _selectedPayer;
    DateTime _selectedDate = DateTime.now();

    @override
    void initState() {
        super.initState();
        if (widget.preselectedPayerId != null && widget.groupMembers.isNotEmpty) {
        try {
            _selectedPayer = widget.groupMembers.firstWhere(
            (member) => member.id == widget.preselectedPayerId,
            );
        } catch (e) {
            print("Preselected payer ID not found in group members.");
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
        super.dispose();
    }

    Future<void> _pickDate(BuildContext context) async {
        final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null && picked != _selectedDate) {
        setState(() {
            _selectedDate = picked;
        });
        }
    }

    void _saveExpense() {
         if (_formKey.currentState!.validate()) {
            final String amountString = _amountController.text.replaceAll(',', '.');
            final double? amount = double.tryParse(amountString);

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
                description: _descriptionController.text,
                amount: amount,
                date: _selectedDate,
                payerId: _selectedPayer!.id,
            );
            Navigator.pop(context, newExpense);
        }
    }


  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormatter = DateFormat('dd.MM.yyyy');

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
              // --- Description Input (Unchanged) ---
               TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'e.g., Groceries, Dinner, Movie Tickets',
                    border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description.';
                    }
                    return null;
                    },
                ),
                const SizedBox(height: 16.0),

              // --- Amount Input (Use passed symbol) ---
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  hintText: '0.00',
                  // Use the symbol passed via the constructor
                  suffixText: widget.currencySymbol, // <-- USE THE WIDGET PROPERTY
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                 validator: (value) {
                    if (value == null || value.isEmpty) {
                        return 'Please enter an amount.';
                    }
                    final String amountString = value.replaceAll(',', '.');
                    final double? amount = double.tryParse(amountString);
                    if (amount == null || amount <= 0) {
                        return 'Please enter a valid positive amount.';
                    }
                    return null;
                    },
              ),
              const SizedBox(height: 16.0),

               // --- Payer Selection (Unchanged) ---
               DropdownButtonFormField<User>(
                    value: _selectedPayer,
                    items: widget.groupMembers.map((User user) {
                    return DropdownMenuItem<User>(
                        value: user,
                        child: Text(user.name),
                    );
                    }).toList(),
                    onChanged: (User? newValue) {
                    setState(() {
                        _selectedPayer = newValue;
                    });
                    },
                    decoration: const InputDecoration(
                    labelText: 'Paid by',
                    border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null && widget.groupMembers.isNotEmpty
                        ? 'Please select who paid.'
                        : null,
                ),
                const SizedBox(height: 16.0),

               // --- Date Selection (Unchanged) ---
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date'),
                    subtitle: Text(dateFormatter.format(_selectedDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _pickDate(context),
                    shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(color: Colors.grey[600]!)
                    ),
                    tileColor: Colors.white,
                ),
                const SizedBox(height: 24.0),

               // --- Save Button (Unchanged) ---
                ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save Expense'),
                    onPressed: _saveExpense,
                    style: ElevatedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}