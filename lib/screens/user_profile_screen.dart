import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/firestore_service.dart';
import '../models/models.dart';

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
        currentUser = User(id: doc['id'], name: doc['name']);
      });
    }
  }

  Future<void> _openCamera() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 32),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : const AssetImage('assets/icons/avatar_placeholder.png')
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
              const SizedBox(height: 32),
              TextFormField(
                readOnly: true,
                initialValue: currentUser?.name,
                decoration: _buildInputDecoration(
                  context: context,
                  labelText: currentUser?.name ?? '',
                  prefixIconData: Icons.person_outline,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                initialValue: uid ?? '',
                decoration: _buildInputDecoration(
                  context: context,
                  labelText: uid ?? '',
                  prefixIconData: Icons.fingerprint,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                initialValue: email ?? '',
                decoration: _buildInputDecoration(
                  context: context,
                  labelText: email ?? '',
                  prefixIconData: Icons.email_outlined,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _buildInputDecoration({
  required String labelText,
  String? hintText,
  IconData? prefixIconData,
  String? suffixText,
  BuildContext? context,
}) {
  final iconColor = context != null
      ? Theme.of(context).colorScheme.primary
      : null;

  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    filled: true,
    fillColor: Colors.black.withOpacity(0.04),
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
