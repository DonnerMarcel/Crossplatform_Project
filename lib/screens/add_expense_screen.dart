import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

class AddExpenseScreen extends StatefulWidget {
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
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
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
                print("Warning: Preselected payer ID (${widget.preselectedPayerId}) not found in group members.");

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

    // Function to show the date picker dialog
    Future<void> _pickDate(BuildContext context) async {
        final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime(2000),
            lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        // If a date was picked and it's different from the current one, update state
        if (picked != null && picked != _selectedDate) {
            setState(() {
                _selectedDate = picked;
            });
        }
    }

    // Function to validate the form and save the expense
    void _saveExpense() {
         // Validate the form fields
         if (_formKey.currentState!.validate()) {
            // Parse the amount, replacing comma with dot for decimal conversion
            final String amountString = _amountController.text.replaceAll(',', '.');
            final double? amount = double.tryParse(amountString);

            // Additional validation for amount (must be positive)
            if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid positive amount.')),
                );
                return;
            }

            // Check if a payer is selected (important if the group could be empty initially)
            if (_selectedPayer == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a payer.')),
                );
                return;
            }

            // Create a new Expense object
            final newExpense = Expense(
                // Generate a unique ID (simple approach using timestamp)
                id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
                description: _descriptionController.text.trim(),
                amount: amount,
                date: _selectedDate,
                payerId: _selectedPayer!.id,
            );

            Navigator.pop(context, newExpense);
        }
    }


  @override
  Widget build(BuildContext context) {
    // Define date format - could be moved to utils/formatters later
    final DateFormat dateFormatter = DateFormat('dd.MM.yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Expense'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // --- Description Input ---
               TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'e.g., Groceries, Dinner, Movie Tickets',
                        border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                            return 'Please enter a description.';
                        }
                        return null; // Return null if valid
                    },
                ),
                const SizedBox(height: 16.0),

              // --- Amount Input ---
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  hintText: '0.00',
                  // Use the currency symbol passed via the constructor
                  suffixText: widget.currencySymbol,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                 validator: (value) {
                    if (value == null || value.isEmpty) {
                        return 'Please enter an amount.';
                    }
                    // Check if parsing is possible (allows comma or dot)
                    final String amountString = value.replaceAll(',', '.');
                    final double? amount = double.tryParse(amountString);
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

               // --- Payer Selection Dropdown ---
               DropdownButtonFormField<User>(
                    value: _selectedPayer,
                    // Generate dropdown items from group members
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
                    isExpanded: true,
                ),
                const SizedBox(height: 16.0),

               // --- Date Selection ---
                ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(4),
                       side: BorderSide(color: Theme.of(context).colorScheme.outline)
                    ),
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Date'),
                    subtitle: Text(dateFormatter.format(_selectedDate)),
                    onTap: () => _pickDate(context),
                ),
                const SizedBox(height: 24.0),

               // --- Save Button ---
                ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save Expense'),
                    onPressed: _saveExpense,
                    style: ElevatedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}