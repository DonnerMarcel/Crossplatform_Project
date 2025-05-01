import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Add a new user to the 'users' collection
  Future<void> addUser(String name) async {
    await _db.collection('users').add({
      'name': name,
      'createdAt' : FieldValue.serverTimestamp(),
    });
  }

  /// Update an existing user in the 'users' collection
  Future<void> updateUser(String userId, String newName) async {
    await _db.collection('users').doc(userId).update({
      'name': newName,
    });
  }

  /// Delete a user from the 'users' collection
  Future<void> deleteUser(String userId) async {
    await _db.collection('users').doc(userId).delete();
  }

  /// get a specific user via its ID
  Future<Map<String, dynamic>> getUserByID(String userID) async {
    final doc = await _db.collection('users').doc(userID).get();

    if (!doc.exists) {
      throw Exception('User with ID $userID not found');
    }

    final data = doc.data()!;
    data['id'] = doc.id;
    return data;
  }

  /// get all available Users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final snapshot = await _db.collection('users').get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }
}
