import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ================
  // USER FUNCTIONS
  // ================

  /// Add a new user to the 'users' collection
  Future<void> addUser({required String userId, required String name}) async {
    await _db.collection('users').doc(userId).set({
      'name': name,
      'totalPaid': 0.0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update an existing user's name in the 'users' collection
  Future<void> updateUserName({required String userId, required String newName}) async {
    await _db.collection('users').doc(userId).update({
      'name': newName,
    });
  }

  /// Update an existing user's totalPaid in the 'users' collection
  Future<void> updateUserTotalPaid({required String userId, required double newTotalPaid}) async {
    await _db.collection('users').doc(userId).update({
      'totalPaid': newTotalPaid,
    });
  }

  /// Delete a user from the 'users' collection
  Future<void> deleteUser(String userId) async {
    await _db.collection('users').doc(userId).delete();
  }

  /// Get a specific user via its ID
  Future<Map<String, dynamic>> getUserByID(String userID) async {
    final doc = await _db.collection('users').doc(userID).get();

    if (!doc.exists) {
      throw Exception('User with ID $userID not found');
    }

    final data = doc.data()!;
    data['id'] = doc.id;
    return data;
  }

  /// Get all available Users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final snapshot = await _db.collection('users').get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // ================
  // GROUP FUNCTIONS
  // ================

  /// Add a new Group to the 'groups' collection
  Future<void> addGroup(String name, List<String> memberIds) async {
    await _db.collection('groups').add({
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
      'members': memberIds, // Store list of user IDs
    });
  }

  /// Update an existing group's name and/or members
  Future<void> updateGroup(String groupId, String newName, List<String> memberIds) async {
    await _db.collection('groups').doc(groupId).update({
      'name': newName,
      'members': memberIds, // Update the members list
    });
  }

  /// Delete a group from the 'groups' collection
  Future<void> deleteGroup(String groupId) async {
    final groupRef = _db.collection('groups').doc(groupId);
    final paymentsRef = groupRef.collection('payments');

    // Delete all documents in 'payments' sub-collection
    final paymentsSnapshot = await paymentsRef.get();
    for (final doc in paymentsSnapshot.docs) {
      await paymentsRef.doc(doc.id).delete();
    }

    // Delete the group document
    await groupRef.delete();
  }

  /// Get a specific group by its ID
  Future<Map<String, dynamic>> getGroupById(String groupId) async {
    final doc = await _db.collection('groups').doc(groupId).get();
    if (!doc.exists) {
      throw Exception('Group with ID $groupId not found');
    }
    final data = doc.data()!;
    data['id'] = doc.id;
    return data;
  }

  /// Get all groups where a specific user is a member
  Future<List<Map<String, dynamic>>> getGroupsByUser(String userId) async {
    final snapshot = await _db.collection('groups')
        .where('members', arrayContains: userId)  // Query where the user ID is in the members array
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Add a member to an existing group (by group ID and user ID)
  Future<void> addMemberToGroup(String groupId, String userId) async {
    final groupRef = _db.collection('groups').doc(groupId);
    final groupSnapshot = await groupRef.get();

    if (!groupSnapshot.exists) {
      throw Exception('Group not found');
    }

    final currentMembers = List<String>.from(groupSnapshot.data()?['members'] ?? []);
    if (!currentMembers.contains(userId)) {
      currentMembers.add(userId);
      await groupRef.update({'members': currentMembers});
    } else {
      throw Exception('User is already a member');
    }
  }

  /// Remove a member from an existing group (by group ID and user ID)
  Future<void> removeMemberFromGroup(String groupId, String userId) async {
    final groupRef = _db.collection('groups').doc(groupId);
    final groupSnapshot = await groupRef.get();

    if (!groupSnapshot.exists) {
      throw Exception('Group not found');
    }

    final currentMembers = List<String>.from(groupSnapshot.data()?['members'] ?? []);
    if (currentMembers.contains(userId)) {
      currentMembers.remove(userId);
      await groupRef.update({'members': currentMembers});
    } else {
      throw Exception('User not a member of this group');
    }
  }

  // ================
  // PAYMENT FUNCTIONS
  // ================

  /// Add a new payment to a specific group
  Future<void> addPayment(String groupId, double amount, String description, String paidByUserId) async {
    await _db.collection('groups').doc(groupId).collection('payments').add({
      'amount': amount,
      'createdAt': FieldValue.serverTimestamp(),
      'description': description,
      'paidBy': paidByUserId, // Reference to the user who paid
    });
  }

  /// Update an existing payment in the 'payments' sub-collection
  Future<void> updatePayment(String groupId, String paymentId, double amount, String description) async {
    await _db.collection('groups').doc(groupId).collection('payments').doc(paymentId).update({
      'amount': amount,
      'description': description,
    });
  }

  /// Delete a payment from a group
  Future<void> deletePayment(String groupId, String paymentId) async {
    await _db.collection('groups').doc(groupId).collection('payments').doc(paymentId).delete();
  }

  /// Get a specific payment by its ID in a group
  Future<Map<String, dynamic>> getPaymentById(String groupId, String paymentId) async {
    final doc = await _db.collection('groups').doc(groupId).collection('payments').doc(paymentId).get();
    if (!doc.exists) {
      throw Exception('Payment with ID $paymentId not found');
    }
    final data = doc.data()!;
    data['id'] = doc.id;
    return data;
  }

  /// Get all payments for a specific group
  Future<List<Map<String, dynamic>>> getPaymentsByGroup(String groupId) async {
    final snapshot = await _db.collection('groups').doc(groupId).collection('payments').get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }
}
