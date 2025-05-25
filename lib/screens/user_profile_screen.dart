import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../services/firestore_service.dart';
import '../models/models.dart';
import 'login_screen.dart';
import 'package:intl/intl.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  final FirestoreService firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  File? _imageFile;
  User? currentUser;
  String? email;
  String? uid;
  Timestamp? createdAt;
  bool _isEditing = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUid = prefs.getString('userId');
    final storedEmail = prefs.getString('userEmail');

    if (storedUid != null) {
      final doc = await firestoreService.getUserByID(storedUid);
      setState(() {
        uid = storedUid;
        email = storedEmail;
        createdAt = doc['createdAt'];
        currentUser = User(
          id: doc['id'],
          name: doc['name'],
          totalPaid: (doc['totalPaid'] ?? 0).toDouble(),
        );
        _nameController.text = currentUser?.name ?? '';
        _emailController.text = email ?? '';
      });
    }
  }

  Future<void> _openCamera() async {
    final XFile? pickedFile =
    await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final newName = _nameController.text.trim();

    if (currentUser != null && uid != null) {
      // Update name in Firestore
      await firestoreService.updateUserName(userId: uid!, newName: newName);

      setState(() {
        currentUser!.name = newName;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (currentUser == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            tooltip: _isEditing ? 'Cancel Edit' : 'Edit Profile',
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) {
                  _nameController.text = currentUser?.name ?? '';
                  _emailController.text = email ?? '';
                }
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : const AssetImage(
                        'assets/icons/avatar_placeholder.png')
                    as ImageProvider,
                  ),
                  Positioned(
                    bottom: -10,
                    right: -10,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt),
                      iconSize: 36,
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: _openCamera,
                      tooltip: 'Take Photo',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              _isEditing
                  ? TextFormField(
                controller: _nameController,
                decoration: _buildInputDecoration(
                  labelText: 'Name',
                  prefixIconData: Icons.person_outlined,
                  context: context,
                ),
                validator: (value) =>
                value == null || value.trim().isEmpty ? 'Enter name' : null,
              )
                  : TextFormField(
                readOnly: true,
                initialValue: currentUser?.name ?? '',
                decoration: _buildInputDecoration(
                  labelText: 'Name',
                  prefixIconData: Icons.person_outlined,
                  context: context,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                initialValue: email ?? '',
                decoration: _buildInputDecoration(
                  labelText: 'Email',
                  prefixIconData: Icons.email_outlined,
                  context: context,
                ),
              ),
              const SizedBox(height: 16),
              IgnorePointer(
                child: TextFormField(
                  readOnly: true,
                  initialValue:
                  currentUser?.totalPaid.toStringAsFixed(2) ?? '0.00',
                  decoration: _buildInputDecoration(
                    labelText: 'Total Paid',
                    prefixIconData: Icons.euro_outlined,
                    context: context,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              IgnorePointer(
                child: TextFormField(
                  readOnly: true,
                  initialValue: createdAt != null
                      ? DateFormat('dd.MM.yyyy').format(
                      DateTime.fromMillisecondsSinceEpoch(
                          createdAt!.millisecondsSinceEpoch))
                      : '',
                  decoration: _buildInputDecoration(
                    labelText: 'Created At',
                    prefixIconData: Icons.calendar_today_outlined,
                    context: context,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_isEditing)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _updateProfile,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Changes'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onPrimary,
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _confirmLogout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    String? hintText,
    IconData? prefixIconData,
    String? suffixText,
    BuildContext? context,
  }) {
    final iconColor =
    context != null ? Theme.of(context).colorScheme.primary : null;

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      filled: true,
      fillColor: Colors.black.withOpacity(0.04),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      prefixIcon: prefixIconData != null
          ? Icon(prefixIconData, color: iconColor)
          : null,
      suffixText: suffixText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }
}
