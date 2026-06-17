import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:agrismart/core/theme.dart';
import 'package:agrismart/presentation/screens/dashboard_screen.dart';
import 'package:agrismart/presentation/screens/admin_dashboard_screen.dart';
import 'package:agrismart/presentation/screens/seasonal_advisor_screen.dart';
import 'package:agrismart/presentation/screens/fertilizer_suggestion_screen.dart';
import 'package:agrismart/presentation/screens/disease_detection_screen.dart';
import 'package:agrismart/presentation/screens/chatbot_screen.dart';
import 'package:agrismart/presentation/screens/history_screen.dart';
import 'package:agrismart/presentation/screens/about_screen.dart';
import 'package:agrismart/presentation/screens/login_screen.dart';

class MainLayout extends StatefulWidget {
  final String userRole; // 'Farmer' or 'Admin'
  final String userName;

  const MainLayout({super.key, required this.userRole, this.userName = 'Farmer John'});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  late List<Widget> _screens;
  late List<Map<String, dynamic>> _navItems;

  @override
  void initState() {
    super.initState();
    _setupRoleBasedUI();
  }

  void _setupRoleBasedUI() {
    if (widget.userRole == 'Admin') {
      _screens = [
        const AdminDashboardScreen(),
        const Center(child: Text('User Management coming soon')),
        const Center(child: Text('Model Analytics coming soon')),
        const Center(child: Text('System Settings coming soon')),
      ];
      _navItems = [
        {'title': 'Overview', 'icon': FontAwesomeIcons.chartPie},
        {'title': 'Users', 'icon': FontAwesomeIcons.users},
        {'title': 'AI Models', 'icon': FontAwesomeIcons.brain},
        {'title': 'Settings', 'icon': FontAwesomeIcons.gear},
      ];
    } else {
      // Default to Farmer
      _screens = [
        const DashboardScreen(),
        const SeasonalAdvisorScreen(),
        const FertilizerSuggestionScreen(),
        const DiseaseDetectionScreen(),
        const ChatbotScreen(),
        const HistoryScreen(),
        const AboutScreen(),
      ];
      _navItems = [
        {'title': 'Dashboard', 'icon': FontAwesomeIcons.chartLine},
        {'title': 'Seasonal Advisor', 'icon': FontAwesomeIcons.calendarDay},
        {'title': 'Fertilizer', 'icon': FontAwesomeIcons.flask},
        {'title': 'Disease Detect', 'icon': FontAwesomeIcons.bug},
        {'title': 'Agri Chatbot', 'icon': FontAwesomeIcons.robot},
        {'title': 'History logs', 'icon': FontAwesomeIcons.clockRotateLeft},
        {'title': 'About', 'icon': FontAwesomeIcons.circleInfo},
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: isDesktop ? null : AppBar(
        title: const Text('AgriSmart'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: _buildAppBarActions(),
      ),
      drawer: isDesktop ? null : _buildDrawer(),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                if (isDesktop) _buildTopNavbar(),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _screens[_selectedIndex],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      IconButton(
        icon: const Icon(FontAwesomeIcons.bell, size: 20),
        onPressed: () {},
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: InkWell(
          onTap: () => _logout(),
          child: const CircleAvatar(
            backgroundColor: AppTheme.primaryColor,
            radius: 16,
            child: Icon(Icons.logout, color: Colors.white, size: 16),
          ),
        ),
      ),
    ];
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedIndex == index;
                return ListTile(
                  leading: Icon(
                    _navItems[index]['icon'],
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                  ),
                  title: Text(
                    _navItems[index]['title'],
                    style: TextStyle(
                      color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: AppTheme.primaryColor.withOpacity(0.1),
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    Navigator.pop(context); // Close drawer
                  },
                );
              },
            ),
          ),
          _buildLogoutTile(),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      color: Colors.white,
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedIndex == index;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: Icon(
                      _navItems[index]['icon'],
                      color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                      size: 20,
                    ),
                    title: Text(
                      _navItems[index]['title'],
                      style: TextStyle(
                        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      setState(() => _selectedIndex = index);
                    },
                  ),
                );
              },
            ),
          ),
          _buildLogoutTile(),
        ],
      ),
    );
  }

  Widget _buildLogoutTile() {
    return Container(
      margin: const EdgeInsets.all(12),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
        title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        onTap: () => _logout(),
      ),
    );
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(FontAwesomeIcons.leaf, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'AgriSmart',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavbar() {
    final bool isAdmin = widget.userRole == 'Admin';
    final String welcomeMsg = isAdmin ? 'System Administration & Management' : 'Welcome back to your smart farm dashboard';
    final String userName = widget.userName;
    final String userType = isAdmin ? 'System Administrator' : 'Premium User';

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
      ),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _navItems[_selectedIndex]['title'],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                welcomeMsg,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Notifications
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: const Icon(FontAwesomeIcons.bell, size: 18, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 16),
          // Profile
          Row(
            children: [
              CircleAvatar(
                backgroundColor: isAdmin ? Colors.deepPurple : AppTheme.primaryColor,
                radius: 20,
                child: Icon(isAdmin ? FontAwesomeIcons.userTie : Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  Text(
                    userType,
                    style: TextStyle(fontSize: 12, color: isAdmin ? Colors.deepPurple : AppTheme.primaryColor),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
