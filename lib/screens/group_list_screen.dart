import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_2/services/firestore_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Assuming these imports are correct for your project structure
import '../providers.dart';
import '../data/dummy_data.dart';
import '../models/models.dart';
import 'main_screen.dart'; // Import MainScreen for navigation
import 'add_group_screen.dart'; // Import the new screen
import '../widgets/group_list/group_list_item.dart'; // Import the list item widget

// Change StatefulWidget to ConsumerStatefulWidget
class GroupListScreen extends ConsumerStatefulWidget {
  const GroupListScreen({super.key});

  @override
  ConsumerState<GroupListScreen> createState() => _GroupListScreenState();
}

// Change State to ConsumerState
class _GroupListScreenState extends ConsumerState<GroupListScreen> {
  final FirestoreService firestoreService = FirestoreService();
  User? currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadBannerAd();
  }

  Future<void> _loadUser() async {
    final uid = await _getStoredUid();
    if (uid != null) {
      final doc = await firestoreService.getUserByID(uid);
      setState(() {
        currentUser = User(id: doc['id'], name: doc['name']);
      });
    }
  }

  Future<String?> _getStoredUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Ad failed to load: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  // --- Navigation Logic ---
  void _navigateToGroup(PaymentGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(groupId: group.id),
      ),
    );
  }

  // --- MODIFIED: Navigate to Add Group Screen ---
  void _addGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddGroupScreen()),
    );
  }

  // --- Placeholder Actions --- (remain the same for now)
  void _onSync() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Placeholder: Sync Action')));
  }

  void _onFilter() {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Placeholder: Filter Action')));
  }

  void _onSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Placeholder: Options/Settings Action')));
  }

  @override
  Widget build(BuildContext context) {
    final List<PaymentGroup> groupsToShow = ref.watch(groupServiceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      // No AppBar
      body: SafeArea( // <--- SafeArea ADDED HERE
        child: Column( // <--- Column is now child of SafeArea
          children: [
            // --- Ad Section ---
            if (_isAdLoaded && _bannerAd != null)
              Container(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: AdWidget(ad: _bannerAd!),
              )
            else
              const SizedBox(height: 50),

            // --- Group List ---
            Expanded(
              child: groupsToShow.isEmpty
                  ? Center(
                      child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'No groups yet.\nTap the + icon to create one!',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      itemCount: groupsToShow.length,
                      itemBuilder: (context, index) {
                        final group = groupsToShow[index];

                        return GroupListItem(
                          group: group,
                          currentUser: currentUser!,
                          onTap: () => _navigateToGroup(group),
                        );
                      },
                    ),
            ),
          ],
        ),
      ), // <--- End of SafeArea
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addGroup,
        tooltip: 'Create a new group',
        icon: const Icon(Icons.add),
        label: const Text('Add Group'),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
                icon: const Icon(Icons.sync),
                onPressed: _onSync,
                tooltip: 'Sync'),
            IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _onFilter,
                tooltip: 'Filter'),
            // SizedBox needed for spacing with centerDocked FAB
            // Adjust width if needed
            // const SizedBox(width: 40),
            IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: _onSettings,
                tooltip: 'Options'),
          ],
        ),
      ),
    );
  }
}