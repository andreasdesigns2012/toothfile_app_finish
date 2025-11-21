import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_3/invite_collaborator_dialog.dart';
import 'package:flutter_application_3/main.dart';
import 'package:flutter_application_3/supabase_auth_service.dart';
import 'package:flutter_application_3/received_files_tab.dart';
import 'package:flutter_application_3/send_files_tab.dart';
import 'package:flutter_application_3/file_tracker_tab.dart';
import 'package:flutter_application_3/requests_tab.dart';
import 'package:flutter_application_3/directory_tab.dart';
import 'package:flutter_application_3/order_form_tab.dart';
import 'package:flutter_application_3/settings_tab.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _userName = 'User';
  String _userRole = 'Role';
  String _userEmail = '';
  String _userInitials = 'U';
  int _selectedIndex = 0;
  bool _isMenuOpen = false;
  final GlobalKey _menuButtonKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  final List<Widget> _pages = [
    const ReceivedFilesTab(),
    const SendFilesTab(),
    const FileTrackerTab(),
    const RequestsTab(),
    const DirectoryTab(),
    const OrderFormTab(),
    const SettingsTab(),
  ];

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    _userName = user?.userMetadata?['name']?.toString() ?? 'User';
    _userRole =
        user?.userMetadata?['user_role']?.toString() ??
        user?.userMetadata?['role']?.toString() ??
        'Role';
    _userEmail = user?.email ?? '';
    _userInitials = _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U';
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isMenuOpen = false;
  }

  void _toggleMenu() {
    if (_isMenuOpen) {
      _removeOverlay();
      setState(() {});
    } else {
      _showMenu();
    }
  }

  void _showMenu() {
    final RenderBox renderBox =
        _menuButtonKey.currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Transparent barrier to detect outside taps
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _removeOverlay();
                });
              },
              child: Container(color: Colors.transparent),
            ),
          ),
          // The actual menu
          Positioned(
            top: offset.dy + size.height + 8,
            right: MediaQuery.of(context).size.width - offset.dx - size.width,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFF2563EB),
                            radius: 20,
                            child: Text(
                              _userInitials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF020817),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _userEmail,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE2E8F0),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _removeOverlay();
                        });
                        // Instead of showDialog, use:
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (BuildContext context) {
                            return const InviteCollaboratorDialog();
                          },
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.person_add_alt_1_outlined,
                              size: 18,
                              color: Color(0xFF64748B),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Invite',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF020817),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        setState(() {
                          _removeOverlay();
                        });
                        await SupabaseAuthService.logout();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Logged out successfully'),
                          ),
                        );
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const MyApp(),
                          ),
                          (Route<dynamic> route) => false,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.logout,
                              size: 18,
                              color: Color(0xFF64748B),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Sign Out',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF020817),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isMenuOpen = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Column(
        children: [
          // Header
          (!kIsWeb &&
                  (defaultTargetPlatform == TargetPlatform.android ||
                      defaultTargetPlatform == TargetPlatform.iOS))
              ? const SizedBox(height: 20)
              : const SizedBox.shrink(),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            child: Row(
              children: [
                // Logo and Title
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset('assets/logo.png', width: 20, height: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'ToothFile',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF020817),
                        height: 1.2,
                      ),
                    ),
                    Text(
                      'Dashboard',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF64748B),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // User Menu Button
                GestureDetector(
                  key: _menuButtonKey,
                  onTap: _toggleMenu,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF2563EB),
                          radius: 14,
                          child: Text(
                            _userInitials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _isMenuOpen
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 18,
                          color: const Color(0xFF64748B),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Welcome Section
          (!kIsWeb &&
                  (defaultTargetPlatform == TargetPlatform.windows ||
                      defaultTargetPlatform == TargetPlatform.macOS ||
                      defaultTargetPlatform == TargetPlatform.linux))
              ? Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, $_userName!',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF020817),
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Manage your files and collaborate with dental technicians',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),

          // Navigation Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildNavTab(0, Icons.download_outlined, 'Received Files'),
                  _buildNavTab(1, Icons.send_outlined, 'Send Files'),
                  _buildNavTab(2, Icons.insert_chart_outlined, 'File Tracker'),
                  _buildNavTab(3, Icons.notifications_outlined, 'Requests'),
                  _buildNavTab(4, Icons.people_outline, 'Directory'),
                  _buildNavTab(5, Icons.description_outlined, 'Order Form'),
                  _buildNavTab(6, Icons.settings_outlined, 'Settings'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 3),

          // Divider
          Container(height: 1, color: const Color(0xFFE2E8F0)),

          // Content Area
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }

  Widget _buildNavTab(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
          if (_isMenuOpen) {
            _removeOverlay();
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF1F5F9) : Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? const Color(0xFF020817)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF020817)
                    : const Color(0xFF64748B),
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
