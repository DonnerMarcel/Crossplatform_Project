import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'firestore_service.dart';

class GroupDataService extends StateNotifier<List<PaymentGroup>> {
  final FirestoreService firestoreService = FirestoreService();
  final List<User> _allUsers = [];

  GroupDataService() : super([]) {
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadInitialUsers();
    state = await _loadGroups();
  }

  static Future<List<PaymentGroup>> _loadGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null) {
      throw Exception("User ID not found in SharedPreferences");
    }

    final firestoreService = FirestoreService();
    final rawGroups = await firestoreService.getGroupsByUser(userId);

    List<PaymentGroup> groups = [];

    for (var groupData in rawGroups) {
      final groupId = groupData['id'];

      // Get full user objects for each member
      final memberIds = List<String>.from(groupData['members']);
      final members = await Future.wait(memberIds.map((id) async {
        final userMap = await firestoreService.getUserByID(id);
        return User(
          id: userMap['id'],
          name: userMap['name'],
          totalPaid: (userMap['totalPaid'] as num?)?.toDouble() ?? 0.0,
          profileColor: null,
        );
      }));

      final rawExpenses = await firestoreService.getPaymentsByGroup(groupId);
      final expenses = rawExpenses.map((expense) {
        return Expense(
          id: expense['id'],
          amount: (expense['amount'] as num).toDouble(),
          description: expense['description'],
          date: (expense['createdAt'] as Timestamp).toDate(),
          payerId: expense['paidBy'],
        );
      }).toList();

      groups.add(PaymentGroup(
        id: groupId,
        name: groupData['name'],
        members: members,
        expenses: expenses..sort((a, b) => b.date.compareTo(a.date)),
      ));
    }

    print("GroupDataService: Loaded ${groups.length} groups from Firestore.");
    return groups;
  }

  Future<void> _loadInitialUsers() async {
    final rawUsers = await firestoreService.getAllUsers();

    _allUsers.clear();
    _allUsers.addAll(rawUsers.map((userData) {
      return User(
        id: userData['id'],
        name: userData['name'],
        profileColor: null,
      );
    }));

    print("GroupDataService: Loaded ${_allUsers.length} users from Firestore.");
  }

  List<User> getAllUsers() => List.from(_allUsers);

  User addUser(String name) {
    final newId = 'user-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999)}';
    final color = Colors.primaries[Random().nextInt(Colors.primaries.length)];
    final newUser = User(id: newId, name: name.trim(), profileColor: color);

    _allUsers.add(newUser);
    firestoreService.addUser(name: newUser.name, userId: ''); // Firestore auto-generates ID

    print("GroupDataService: User '${newUser.name}' added.");
    return newUser;
  }

  PaymentGroup getGroupById(String groupId) {
    return state.firstWhere(
          (group) => group.id == groupId,
      orElse: () => throw Exception('Group not found: $groupId'),
    );
  }

  Future<void> updateGroupName(String groupId, String newName) async {
    final group = getGroupById(groupId);
    if (group == null) return;

    await firestoreService.updateGroup(groupId, newName.trim(), group.members.map((m) => m.id).toList());
    state = await _loadGroups();
    print("GroupDataService: Group name updated in Firestore.");
  }

  Future<void> addExpenseToGroup({
    required String groupId,
    required Expense newExpense,
  }) async {
    await firestoreService.addPayment(
      groupId,
      newExpense.amount,
      newExpense.description,
      newExpense.payerId,
    );

    final userDoc = await firestoreService.getUserByID(newExpense.payerId);
    final currentTotalPaid = userDoc['totalPaid'] ?? 0.0;

    await firestoreService.updateUserTotalPaid(
      userId: userDoc['id'],
      newTotalPaid: currentTotalPaid + newExpense.amount,
    );

    state = await _loadGroups();
    print("GroupDataService: Expense added and state refreshed.");
  }

  Future<void> updateExpenseInGroup({
    required String groupId,
    required String paymentId,
    required String userId,
    required double newAmount,
    required String newDescription,
  }) async {
    // Get the old payment to compare old vs new amount
    final oldPayment = await firestoreService.getPaymentById(groupId, paymentId);
    final oldAmount = oldPayment['amount'] ?? 0.0;

    // Update the payment
    await firestoreService.updatePayment(groupId, paymentId, newAmount, newDescription);

    // Adjust the user's totalPaid
    final userDoc = await firestoreService.getUserByID(userId);
    final currentTotalPaid = userDoc['totalPaid'] ?? 0.0;

    final adjustedTotal = currentTotalPaid - oldAmount + newAmount;

    await firestoreService.updateUserTotalPaid(userId: userId, newTotalPaid: adjustedTotal);

    state = await _loadGroups();
    print("GroupDataService: Expense updated and state refreshed.");
  }

  Future<void> deleteExpenseFromGroup({
    required String groupId,
    required String paymentId,
    required String userId,
  }) async {
    // Get the payment to subtract its amount
    final payment = await firestoreService.getPaymentById(groupId, paymentId);
    final amount = payment['amount'] ?? 0.0;

    // Delete the payment
    await firestoreService.deletePayment(groupId, paymentId);

    // Adjust the user's totalPaid
    final userDoc = await firestoreService.getUserByID(userId);
    final currentTotalPaid = userDoc['totalPaid'] ?? 0.0;

    final newTotal = currentTotalPaid - amount;
    await firestoreService.updateUserTotalPaid(userId: userId, newTotalPaid: newTotal);

    state = await _loadGroups();
    print("GroupDataService: Expense deleted and state refreshed.");
  }

  Future<void> addGroup(String name, List<User> members) async {
    if (name.trim().isEmpty || members.isEmpty) {
      print("GroupDataService: Cannot add group with empty name or no members.");
      return;
    }

    await firestoreService.addGroup(name, members.map((m) => m.id).toList());

    state = await _loadGroups();
    print("GroupDataService: Group added to Firestore.");
  }

  Future<void> deleteGroup(String groupId) async {
    await firestoreService.deleteGroup(groupId);
    state = await _loadGroups();
    print("GroupDataService: Group deleted from Firestore.");
  }
}
