import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart'; // Assuming correct path

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
  final _dateController = TextEditingController(); // Controller for Date field
  User? _selectedPayer;
  DateTime _selectedDate = DateTime.now();
  late DateFormat _dateFormatter; // Use instance variable for formatter

  @override
  void initState() {
    super.initState();
    _dateFormatter = DateFormat('dd.MM.yyyy'); // Initialize formatter
    _updateDateText(); // Set initial date text

    // Preselect Payer logic
    if (widget.preselectedPayerId != null && widget.groupMembers.isNotEmpty) {
      try {
        _selectedPayer = widget.groupMembers.firstWhere(
          (member) => member.id == widget.preselectedPayerId,
        );
      } catch (e) {
        print(
            "Warning: Preselected payer ID (${widget.preselectedPayerId}) not found in group members.");
        // Fallback to the first member if preselected not found
        if (widget.groupMembers.isNotEmpty) {
          _selectedPayer = widget.groupMembers.first;
        }
      }
    } else if (widget.groupMembers.isNotEmpty) {
      // Fallback to the first member if no preselection
      _selectedPayer = widget.groupMembers.first;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _dateController.dispose(); // Dispose the new controller
    super.dispose();
  }

  void _updateDateText() {
    _dateController.text = _dateFormatter.format(_selectedDate);
  }

  // Function to show the date picker dialog
  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      // Optionally style the date picker to match app theme
      // builder: (context, child) {
      //   return Theme(
      //     data: Theme.of(context).copyWith(
      //       colorScheme: Theme.of(context).colorScheme.copyWith(
      //             primary: Theme.of(context).colorScheme.primary, // header background
      //             onPrimary: Theme.of(context).colorScheme.onPrimary, // header text
      //             onSurface: Theme.of(context).colorScheme.onSurface, // body text
      //           ),
      //       textButtonTheme: TextButtonThemeData(
      //         style: TextButton.styleFrom(
      //           foregroundColor: Theme.of(context).colorScheme.primary, // button text color
      //         ),
      //       ),
      //     ),
      //     child: child!,
      //   );
      // },
    );
    // If a date was picked and it's different from the current one, update state
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _updateDateText(); // Update the text field
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

      // Additional validation for amount (must be positive) - redundant check as validator handles it, but safe
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please enter a valid positive amount.')),
        );
        return;
      }

      // Check if a payer is selected
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

      // Pass the new expense back to the previous screen
      Navigator.pop(context, newExpense);

       // Optional: Show confirmation SnackBar on the previous screen after popping
       // ScaffoldMessenger.of(context).showSnackBar(
       //   SnackBar(content: Text("Expense '${newExpense.description}' added.")),
       // );
    } else {
        // Optional: Indicate validation failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please correct the errors above.')),
        );
    }
  }

  // Helper method for consistent InputDecoration
  InputDecoration _buildInputDecoration(
      {required String hintText,
      String? labelText, // LabelText is optional now
      required IconData prefixIconData,
      String? suffixText,
      Color? prefixIconColor}) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hintText,
      labelText: labelText, // Keep labelText if desired
      filled: true,
      fillColor: Colors.black.withOpacity(0.04), // Match AddGroupScreen
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none, // Match AddGroupScreen
      ),
      prefixIcon: Icon(prefixIconData,
          color: prefixIconColor ??
              theme.colorScheme.primary.withOpacity(0.8), size: 20),
       suffixText: suffixText, // Keep suffixText for currency
       isDense: true, // Makes fields slightly more compact vertically
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme data

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Expense'),
        // Using default back button is standard unless custom behavior is needed
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back),
        //   onPressed: () => Navigator.of(context).pop(),
        // ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch buttons
            children: <Widget>[
              // --- Description Input ---
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
                  return null; // Return null if valid
                },
              ),
              const SizedBox(height: 16.0),

              // --- Amount Input ---
              TextFormField(
                controller: _amountController,
                decoration: _buildInputDecoration(
                  labelText: 'Amount',
                  hintText: '0.00',
                  prefixIconData: Icons.calculate_outlined, // Example icon
                  suffixText: widget.currencySymbol,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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
                items: widget.groupMembers.map((User user) {
                  return DropdownMenuItem<User>(
                    value: user,
                    child: Row( // Add avatar in dropdown item for consistency
                      children: [
                         CircleAvatar(
                          radius: 12, // Small avatar
                          backgroundColor: user.profileColor ?? theme.colorScheme.primaryContainer,
                          foregroundColor: theme.colorScheme.onPrimaryContainer,
                          child: Text(user.name.substring(0, 1), style: const TextStyle(fontSize: 10)),
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
                validator: (value) =>
                    value == null && widget.groupMembers.isNotEmpty
                        ? 'Please select who paid.'
                        : null,
                isExpanded: true, // Keep expanded
                // Style dropdown menu if needed
                // dropdownColor: theme.cardColor,
              ),
              const SizedBox(height: 16.0),

              // --- Date Selection (Using TextFormField) ---
              TextFormField(
                controller: _dateController,
                readOnly: true, // Make it non-editable directly
                decoration: _buildInputDecoration(
                  labelText: 'Date',
                  hintText: 'Select date',
                  prefixIconData: Icons.calendar_today_outlined,
                ),
                onTap: () {
                  // Unfocus any active field before opening picker
                  FocusScope.of(context).requestFocus(FocusNode());
                  _pickDate(context);
                },
                 validator: (value) { // Add validator if date is mandatory
                   if (value == null || value.isEmpty) {
                     return 'Please select a date.';
                   }
                   return null;
                 },
              ),
              const SizedBox(height: 24.0),

              // --- Save Button ---
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline), // Changed icon slightly
                label: const Text('Save Expense'),
                onPressed: _saveExpense,
                style: ElevatedButton.styleFrom(
                  foregroundColor: theme.colorScheme.onPrimary,
                  backgroundColor: theme.colorScheme.primary,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16), // Keep padding
                  textStyle: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    // Consistent rounded corners with inputs
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