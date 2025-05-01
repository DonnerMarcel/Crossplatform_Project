import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class FirestoreTestScreen extends StatefulWidget {
  const FirestoreTestScreen({super.key});

  @override
  State<FirestoreTestScreen> createState() => _FirestoreTestScreenState();
}

class _FirestoreTestScreenState extends State<FirestoreTestScreen> {
  final FirestoreService _service = FirestoreService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController(); // User ID field
  List<Map<String, dynamic>> _users = [];
  String? _selectedUserId;

  // Refresh user list
  void _refreshUsers() async {
    final users = await _service.getAllUsers();
    setState(() {
      _users = users;
      _selectedUserId = null;
      _idController.clear(); // Clear ID controller
      _nameController.clear(); // Clear name controller
    });
  }

  // Add user
  void _addUser() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    await _service.addUser(name);
    _nameController.clear();
    _refreshUsers();
  }

  // Update user
  void _updateUser() async {
    final id = _idController.text.trim();
    final name = _nameController.text.trim();
    if (id.isEmpty || name.isEmpty) return;

    await _service.updateUser(id, name);
    _refreshUsers();
  }

  // Delete user
  void _deleteUser() async {
    final id = _idController.text.trim();
    if (id.isEmpty) return;

    await _service.deleteUser(id);
    _nameController.clear();
    _idController.clear();
    _refreshUsers();
  }

  @override
  void initState() {
    super.initState();
    _refreshUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firestore Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // User name input
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'User name'),
            ),
            const SizedBox(height: 12),
            // User ID input (Read-only, filled when user is tapped)
            TextField(
              controller: _idController,
              decoration: const InputDecoration(labelText: 'User ID'),
              readOnly: true, // Prevent manual editing
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(onPressed: _addUser, child: const Text('Add')),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _updateUser, child: const Text('Update')),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _deleteUser, child: const Text('Delete')),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Users:', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  final isSelected = user['id'] == _selectedUserId;
                  return ListTile(
                    title: Text(user['name'] ?? 'Unnamed'),
                    subtitle: Text('ID: ${user['id']}'),
                    tileColor: isSelected ? Colors.blue[50] : null,
                    onTap: () {
                      setState(() {
                        _selectedUserId = user['id'];
                        _idController.text = user['id'] ?? '';
                        _nameController.text = user['name'] ?? '';
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}