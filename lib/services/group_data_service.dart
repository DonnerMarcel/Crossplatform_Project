// lib/services/group_data_service.dart
import 'dart:math';
import 'package:flutter/material.dart'; // Import material for Colors
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      userSara,
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


  // --- Group Data Access Methods --- (getGroupById remains the same)

  PaymentGroup? getGroupById(String groupId) {
    try {
      return state.firstWhere((group) => group.id == groupId);
    } catch (e) {
      print("Error in getGroupById: Group $groupId not found.");
      return null;
    }
  }

  // --- Group Data Modification Methods --- (updateGroupName, addExpenseToGroup remain the same)

  void updateGroupName(String groupId, String newName) {
    state = [
      for (final group in state)
        if (group.id == groupId)
          PaymentGroup(
              id: group.id,
              name: newName,
              members: group.members,
              expenses: group.expenses)
        else
          group,
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
            expenses: List.from(group.expenses)
              ..add(newExpense)
              ..sort((a, b) => b.date.compareTo(a.date)),
          )
        else
          group,
     ];
     print("GroupDataService: Expense '${newExpense.description}' added to group '$groupId'. State updated.");
     // TODO: Persist changes
  }

  // --- ADD GROUP METHOD ---
  // Adds a new group to the state list.
  void addGroup(String name, List<User> members) {
    if (name.trim().isEmpty) {
      print("GroupDataService: Cannot add group with empty name.");
      return;
    }
    if (members.isEmpty) {
       print("GroupDataService: Cannot add group with no members.");
       // Or decide if groups with 0 members initially are allowed
       return;
    }
    // Generate a unique ID for the group
    final newId = 'group-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999)}';
    final newGroup = PaymentGroup(
      id: newId,
      name: name.trim(),
      members: List.from(members), // Use a copy of the members list
      expenses: [], // Start with empty expenses
    );
    // Add the new group to the existing state list
    state = [...state, newGroup]; // Creates a new list
    print("GroupDataService: Group '$name' added with ID '$newId'. State updated.");
    // TODO: Persist group list changes
  }

  // --- Delete Group Method --- (Uncommented and uses state)
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

  // --- Placeholder for Member Management ---
  // void addMemberToGroup(String groupId, User newMember) {
  //    state = [
  //     for (final group in state)
  //       if (group.id == groupId)
  //          PaymentGroup(
  //             id: group.id,
  //             name: group.name,
  //             // Add member if not already present
  //             members: group.members.contains(newMember) ? group.members : [...group.members, newMember],
  //             expenses: group.expenses
  //           )
  //       else
  //         group,
  //    ];
  //    print("GroupDataService: Member '${newMember.name}' added to group '$groupId'. State updated.");
  //    // TODO: Persist changes
  // }

  // void removeMemberFromGroup(String groupId, String userId) {
  //    state = [
  //     for (final group in state)
  //       if (group.id == groupId)
  //          PaymentGroup(
  //             id: group.id,
  //             name: group.name,
  //             // Filter out the member
  //             members: group.members.where((member) => member.id != userId).toList(),
  //             expenses: group.expenses
  //             // TODO: Consider how removing a member affects expense splitting/balances
  //           )
  //       else
  //         group,
  //    ];
  //    print("GroupDataService: Member '$userId' removed from group '$groupId'. State updated.");
  //    // TODO: Persist changes
  // }
}