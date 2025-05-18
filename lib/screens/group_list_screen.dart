import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/firestore_service.dart';
import '../providers.dart';
import '../models/models.dart';
import '../widgets/group_list/group_list_item.dart';
import 'add_group_screen.dart';
import 'main_screen.dart';
import 'user_profile_screen.dart';

class GroupListScreen extends ConsumerStatefulWidget {
  const GroupListScreen({super.key});

  @override
  ConsumerState<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends ConsumerState<GroupListScreen> {
  final FirestoreService firestoreService = FirestoreService();
  User? currentUser;
  int _selectedIndex = 0;

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

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

  void _addGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddGroupScreen()),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    final bool isSelected = _selectedIndex == index;
    final Color? itemColor = isSelected
        ? Theme.of(context).colorScheme.primary
        : Colors.grey[600];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: IconButton(
        icon: Icon(isSelected ? activeIcon : icon),
        color: itemColor,
        tooltip: label,
        onPressed: () => _onItemTapped(index),
      ),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildGroupListPage(),
      const UserProfileScreen(),
      const SettingsPlaceholderScreen(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
        onPressed: _addGroup,
        tooltip: 'Create a new group',
        icon: const Icon(Icons.add),
        label: const Text('Add Group'),
      )
          : null,
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).bottomAppBarTheme.color ?? Colors.white,
        elevation: Theme.of(context).bottomAppBarTheme.elevation ?? 2,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(Icons.list_alt_outlined, Icons.list_alt, 'Groups', 0),
            _buildNavItem(Icons.person_outline, Icons.person, 'Profile', 1),
            _buildNavItem(Icons.settings_outlined, Icons.settings, 'Settings', 2), // <-- Added
          ],
        ),
      ),
    );
  }



  Widget _buildGroupListPage() {
    final List<PaymentGroup> groupsToShow = ref.watch(groupServiceProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        children: [
          if (_isAdLoaded && _bannerAd != null)
            Container(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: AdWidget(ad: _bannerAd!),
            )
          else
            const SizedBox(height: 50),
          Expanded(
            child: groupsToShow.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'No groups yet.\nTap the + icon to create one!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: groupsToShow.length,
              itemBuilder: (context, index) {
                final group = groupsToShow[index];
                return GroupListItem(
                  group: group,
                  currentUser: currentUser!,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MainScreen(groupId: group.id)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsPlaceholderScreen extends StatelessWidget {
  const SettingsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text("Settings screen (placeholder)")),
    );
  }
}
