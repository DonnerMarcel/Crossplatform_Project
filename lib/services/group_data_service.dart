// lib/services/group_data_service.dart
import 'dart:math';
import 'package:flutter/material.dart'; // Import material for Colors
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Assuming correct path
import '../models/models.dart';
import '../data/dummy_data.dart'; // Still needed for initial users

// Make the service a StateNotifier, holding the list of groups as its state.
class GroupDataService extends StateNotifier<List<PaymentGroup>> {
  // --- Add state for all known users ---
  // This list will hold all users, including newly created ones.
  // In a real app, this would also be loaded/saved.
  final List<User> _allUsers = [];

  // Constructor: Initialize the state by loading initial data.
  GroupDataService() : super(_loadInitialGroups()) {
    // Also initialize the list of all known users
    _loadInitialUsers();
  }

  // Static private method to load initial groups
  static List<PaymentGroup> _loadInitialGroups() {
    final initialGroups = List<PaymentGroup>.from(dummyGroups);
    print("GroupDataService: Initial groups loaded.");
    // TODO: Implement loading groups from persistent storage later
    return initialGroups;
  }

  // Private method to load initial users from dummy data
  void _loadInitialUsers() {
    // Add users defined in dummy_data.dart initially
    // Ensure no duplicates if currentUser is also in the list explicitly
    _allUsers.addAll([
      userMe,
      userMax,
      userKlaus,
      userJohn,
      userAnna,
      userSara, // Assuming userSara is defined in dummy_data
    ]);
    // Remove duplicates just in case (based on ID)
    final uniqueUserIds = <String>{};
    _allUsers.retainWhere((user) => uniqueUserIds.add(user.id));
    print("GroupDataService: Initial users loaded. Count: ${_allUsers.length}");
    // TODO: Implement loading users from persistent storage later
  }

  // --- User Management Methods ---

  // Returns a copy of the list of all known users
  List<User> getAllUsers() {
    return List.from(_allUsers);
  }

  // Adds a new user to the central list
  // Returns the newly created User object
  User addUser(String name) {
    // Generate a unique ID
    final newId = 'user-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999)}';
    // Assign a random color (simple approach)
    final randomColor = Colors.primaries[Random().nextInt(Colors.primaries.length)];
    final newUser = User(
      id: newId,
      name: name.trim(),
      profileColor: randomColor,
      // totalPaid will be calculated per group context, starts at 0 conceptually
    );
    _allUsers.add(newUser);
    print("GroupDataService: User '${newUser.name}' added with ID '${newUser.id}'.");
    // TODO: Persist user list changes
    // Note: We might need a separate StateNotifier for users if UI needs to react directly to user list changes.
    // For now, AddGroupScreen will re-fetch the list after adding.
    return newUser;
  }


  // --- Group Data Access Methods ---

  PaymentGroup? getGroupById(String groupId) {
    try {
      // Use state directly, as it's the list of groups
      return state.firstWhere((group) => group.id == groupId);
    } catch (e) {
      print("Error in getGroupById: Group $groupId not found in current state.");
      return null;
    }
  }

  // --- Group Data Modification Methods ---

  void updateGroupName(String groupId, String newName) {
    state = [
      for (final group in state)
        if (group.id == groupId)
          // Create a new PaymentGroup object with the updated name
          PaymentGroup(
              id: group.id,
              name: newName.trim(), // Ensure name is trimmed
              members: group.members, // Keep existing members
              expenses: group.expenses // Keep existing expenses
          )
        else
          group, // Keep other groups unchanged
    ];
    print("GroupDataService: Group '$groupId' name updated to '$newName'. State updated.");
    // TODO: Persist changes
  }

  void addExpenseToGroup(String groupId, Expense newExpense) {
     state = [
       for (final group in state)
         if (group.id == groupId)
           PaymentGroup(
             id: group.id,
             name: group.name,
             members: group.members,
             // Create new list with added expense and sort it
             expenses: List.from(group.expenses)
               ..add(newExpense)
               // Ensure sorting happens correctly within the new list creation
               ..sort((a, b) => b.date.compareTo(a.date)),
           )
         else
           group,
     ];
     print("GroupDataService: Expense '${newExpense.description}' added to group '$groupId'. State updated.");
     // TODO: Persist changes
  }

  // --- ADD GROUP METHOD ---
  void addGroup(String name, List<User> members) {
    if (name.trim().isEmpty) {
      print("GroupDataService: Cannot add group with empty name.");
      return;
    }
    if (members.isEmpty) {
       print("GroupDataService: Cannot add group with no members.");
       return;
    }
    final newId = 'group-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999)}';
    final newGroup = PaymentGroup(
      id: newId,
      name: name.trim(),
      members: List.from(members),
      expenses: [],
    );
    // Create a new list including the new group
    state = [...state, newGroup];
    print("GroupDataService: Group '$name' added with ID '$newId'. State updated.");
    // TODO: Persist group list changes
  }

  // --- Delete Group Method --- (THIS IS ALREADY CORRECT)
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

  // --- Placeholder for Member Management --- (Keep commented out)
  // void addMemberToGroup(String groupId, User newMember) { ... }
  // void removeMemberFromGroup(String groupId, String userId) { ... }
}