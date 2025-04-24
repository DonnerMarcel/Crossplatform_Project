// lib/screens/add_expense_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';      // For date formatting
import '../models/models.dart';      // Import models User and Expense

class AddExpenseScreen extends StatefulWidget {
  final List<User> groupMembers;      // List of users to select from
  final String? preselectedPayerId; // Optional ID of the user pre-selected (e.g., from spin wheel)
  final String currencySymbol;      // Currency symbol to display (e.g., '$', '€')

  const AddExpenseScreen({
    super.key,
    required this.groupMembers,
    this.preselectedPayerId,
    required this.currencySymbol, // Make currency symbol required
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
    final _formKey = GlobalKey<FormState>(); // Key for the form validation
    // Text editing controllers for the input fields
    final _descriptionController = TextEditingController();
    final _amountController = TextEditingController();
    // State variables for selected payer and date
    User? _selectedPayer;
    DateTime _selectedDate = DateTime.now(); // Default to current date

    @override
    void initState() {
        super.initState();
        // Pre-select the payer if an ID is provided and the member exists
        if (widget.preselectedPayerId != null && widget.groupMembers.isNotEmpty) {
            try {
                // Find the user in the groupMembers list matching the preselected ID
                _selectedPayer = widget.groupMembers.firstWhere(
                    (member) => member.id == widget.preselectedPayerId,
                );
            } catch (e) {
                // Handle cases where the preselected ID might not be found
                // (e.g., user left the group after spin but before adding details)
                print("Warning: Preselected payer ID (${widget.preselectedPayerId}) not found in group members.");
                // Fallback: select the first member if available
                if (widget.groupMembers.isNotEmpty) {
                    _selectedPayer = widget.groupMembers.first;
                }
            }
        } else if (widget.groupMembers.isNotEmpty) {
             // If no preselection, default to the first member in the list
            _selectedPayer = widget.groupMembers.first;
        }
        // If groupMembers is empty, _selectedPayer remains null
    }

    @override
    void dispose() {
        // Dispose controllers when the widget is removed from the tree
        _descriptionController.dispose();
        _amountController.dispose();
        super.dispose();
    }

    // Function to show the date picker dialog
    Future<void> _pickDate(BuildContext context) async {
        final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: _selectedDate, // Start picker at currently selected date
            firstDate: DateTime(2000), // Allow dates from year 2000 onwards
            lastDate: DateTime.now().add(const Duration(days: 365)), // Allow dates up to 1 year in the future
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
                return; // Stop if amount is invalid
            }

            // Check if a payer is selected (important if the group could be empty initially)
            if (_selectedPayer == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a payer.')),
                );
                return; // Stop if no payer is selected
            }

            // Create a new Expense object
            final newExpense = Expense(
                // Generate a unique ID (simple approach using timestamp)
                id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
                description: _descriptionController.text.trim(), // Trim whitespace
                amount: amount,
                date: _selectedDate,
                payerId: _selectedPayer!.id, // Use the ID of the selected user
            );

            // Pop the screen and return the newly created expense object
            Navigator.pop(context, newExpense);
        }
    }


  @override
  Widget build(BuildContext context) {
    // Define date format - could be moved to utils/formatters later
    // Ensure 'package:intl/intl.dart' is imported
    final DateFormat dateFormatter = DateFormat('dd.MM.yyyy'); // German date format example

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Expense'),
        leading: IconButton( // Add a back button explicitly if needed
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(), // Pops without returning data
        ),
      ),
      body: SingleChildScrollView( // Allow scrolling if content overflows
        padding: const EdgeInsets.all(16.0),
        child: Form( // Use a Form widget for validation
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch buttons etc.
            children: <Widget>[
              // --- Description Input ---
               TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'e.g., Groceries, Dinner, Movie Tickets',
                        border: OutlineInputBorder(), // Add border
                    ),
                    textCapitalization: TextCapitalization.sentences, // Capitalize start of sentence
                    validator: (value) { // Validation rule
                        if (value == null || value.trim().isEmpty) {
                            return 'Please enter a description.';
                        }
                        return null; // Return null if valid
                    },
                ),
                const SizedBox(height: 16.0), // Spacing

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
                keyboardType: const TextInputType.numberWithOptions(decimal: true), // Show numeric keyboard
                 validator: (value) { // Validation rules
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
                    return null; // Return null if valid
                 },
              ),
              const SizedBox(height: 16.0),

               // --- Payer Selection Dropdown ---
               DropdownButtonFormField<User>(
                    value: _selectedPayer, // Currently selected user
                    // Generate dropdown items from group members
                    items: widget.groupMembers.map((User user) {
                        return DropdownMenuItem<User>(
                            value: user, // The User object itself is the value
                            child: Text(user.name), // Display user name
                        );
                    }).toList(),
                    onChanged: (User? newValue) { // Update state when selection changes
                        setState(() {
                            _selectedPayer = newValue;
                        });
                    },
                    decoration: const InputDecoration(
                        labelText: 'Paid by',
                        border: OutlineInputBorder(),
                    ),
                    // Validation: Ensure a payer is selected if members exist
                    validator: (value) => value == null && widget.groupMembers.isNotEmpty
                        ? 'Please select who paid.'
                        : null, // Return null if valid or no members
                    // Enhance usability if list is long
                    isExpanded: true, // Allow dropdown to expand fully
                ),
                const SizedBox(height: 16.0),

               // --- Date Selection ---
                ListTile(
                    // Use ListTile for better alignment and tap target
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), // Adjust padding
                    shape: RoundedRectangleBorder( // Use outlined border like other fields
                       borderRadius: BorderRadius.circular(4),
                       side: BorderSide(color: Theme.of(context).colorScheme.outline) // Use theme color
                    ),
                    // tileColor: Colors.white, // Avoid fixed white color, let theme decide
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Date'),
                    // Display the formatted selected date
                    subtitle: Text(dateFormatter.format(_selectedDate)),
                    // Open date picker on tap
                    onTap: () => _pickDate(context),
                ),
                const SizedBox(height: 24.0), // More spacing before button

               // --- Save Button ---
                ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save Expense'),
                    onPressed: _saveExpense, // Call save function on press
                    style: ElevatedButton.styleFrom(
                        // Use theme colors for consistency
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16), // Make button taller
                        textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)) // Match card radius
                    ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}