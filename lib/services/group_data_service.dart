// lib/services/group_data_service.dart
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod

import '../models/models.dart';
import '../data/dummy_data.dart';

// Make the service a StateNotifier, holding the list of groups as its state.
class GroupDataService extends StateNotifier<List<PaymentGroup>> {

  // Constructor: Initialize the state by loading initial data.
  // super() calls the StateNotifier constructor with the initial state.
  GroupDataService() : super(_loadInitialData());

  // Static private method to load initial data (can be called by constructor)
  static List<PaymentGroup> _loadInitialData() {
    // Create a deep copy or ensure PaymentGroup is designed for mutation if needed.
    final initialGroups = List<PaymentGroup>.from(dummyGroups);
    print("GroupDataService: Initial data loaded from dummy_data.dart");
    // TODO: Implement loading from persistent storage later
    return initialGroups;
  }

  // --- Data Access Methods ---

  // Get all groups directly from the current state.
  // Riverpod automatically provides the current state list.
  // You can access the current list via the 'state' property in widgets watching the provider.
  // Example: ref.watch(groupServiceProvider) returns List<PaymentGroup>
  // If you absolutely need a getter method: List<PaymentGroup> getAllGroups() => state;

  // Finds a specific group by its ID from the current state. Returns null if not found.
  PaymentGroup? getGroupById(String groupId) {
    try {
      // Access the current list of groups via the 'state' property
      return state.firstWhere((group) => group.id == groupId);
    } catch (e) {
      print("Error in getGroupById: Group $groupId not found.");
      return null;
    }
  }

  // --- Data Modification Methods ---

  // Updates the name of a specific group.
  void updateGroupName(String groupId, String newName) {
    // Create a new list based on the current state
    state = [
      for (final group in state)
        if (group.id == groupId)
          // If models were immutable, we'd use copyWith:
          // group.copyWith(name: newName)
          // Since our model is mutable, we can modify and return it:
          PaymentGroup(
              id: group.id,
              name: newName, // Update the name
              members: group.members,
              expenses: group.expenses)
        else
          group, // Keep other groups unchanged
    ];
    print("GroupDataService: Group '$groupId' name updated to '$newName'. State updated.");
    // StateNotifier automatically notifies listeners when 'state' is reassigned.
    // TODO: Persist changes to local storage later
  }

  // Adds a new expense to a specific group.
  void addExpenseToGroup(String groupId, Expense newExpense) {
     state = [
      for (final group in state)
        if (group.id == groupId)
          // Create a new group instance with the added expense
          PaymentGroup(
            id: group.id,
            name: group.name,
            members: group.members,
            // Create a new list for expenses, add the new one, and sort
            expenses: List.from(group.expenses) // Create a mutable copy
              ..add(newExpense)
              ..sort((a, b) => b.date.compareTo(a.date)),
          )
        else
          group, // Keep other groups unchanged
     ];
     print("GroupDataService: Expense '${newExpense.description}' added to group '$groupId'. State updated.");
     // StateNotifier automatically notifies listeners.
     // TODO: Persist changes to local storage later
  }

  // --- Placeholder for Future Methods ---

  void addGroup(String name, List<User> members) {
    final newId = 'g_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}';
    final newGroup = PaymentGroup(id: newId, name: name, members: members, expenses: []);
    // Add the new group to the existing state list
    state = [...state, newGroup]; // Creates a new list
    print("GroupDataService: Group '$name' added with ID '$newId'. State updated.");
    // TODO: Persist changes
  }

  void deleteGroup(String groupId) {
    final initialLength = state.length;
    // Filter out the group to be deleted, creating a new list
    state = state.where((group) => group.id != groupId).toList();
    if (state.length < initialLength) {
       print("GroupDataService: Group '$groupId' deleted. State updated.");
        // TODO: Persist changes
    } else {
       print("GroupDataService: Group '$groupId' not found for deletion.");
    }
  }

  // void addMemberToGroup(String groupId, User newMember) { ... update state ... }
  // void removeMemberFromGroup(String groupId, String userId) { ... update state ... }
}