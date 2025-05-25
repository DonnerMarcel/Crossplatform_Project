import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  File? _imageFile;
  User? currentUser;
  String? email;
  String? uid;
  Timestamp? createdAt;

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
        createdAt = doc['createdAt']; // <-- Get it directly
        currentUser = User(
          id: doc['id'],
          name: doc['name'],
          totalPaid: (doc['totalPaid'] ?? 0).toDouble(),
        );
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
    if (currentUser == null) {
      //show empty container until _loadUser is finished or I would have to code
      //a lot of garbage to handle nulls
      return const Scaffold();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
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
              const SizedBox(height: 16),
              IgnorePointer(
                child: TextFormField(
                  readOnly: true,
                  initialValue: currentUser?.name,
                  // Your actual displayed text inside the field
                  decoration: InputDecoration(
                    labelText: 'Name',
                    // Floating label above the field
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    prefixIcon:Icon(Icons.person_outlined, color: Theme.of(context).colorScheme.primary),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              IgnorePointer(
                child: TextFormField(
                  readOnly: true,
                  initialValue: email ?? '',
                  decoration: InputDecoration(
                    labelText: 'Email',
                    // Floating label above the field
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    prefixIcon: Icon(Icons.email_outlined, color: Theme.of(context).colorScheme.primary),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              IgnorePointer(
                child: TextFormField(
                  readOnly: true,
                  initialValue: currentUser?.totalPaid.toStringAsFixed(2),
                  decoration: InputDecoration(
                    labelText: 'Total Paid',
                    // Floating label above the field
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    prefixIcon: Icon(Icons.euro_outlined, color: Theme.of(context).colorScheme.primary),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
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
                  decoration: InputDecoration(
                    labelText: 'Created At',
                    // Floating label above the field
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    prefixIcon: Icon(Icons.calendar_today_outlined, color: Theme.of(context).colorScheme.primary),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _confirmLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
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
      floatingLabelBehavior: FloatingLabelBehavior.never,
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
