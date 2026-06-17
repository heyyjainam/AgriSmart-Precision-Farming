import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:agrismart/core/theme.dart';
import 'package:agrismart/core/history_service.dart';
import 'package:agrismart/core/api_config.dart';
import 'package:agrismart/presentation/widgets/glass_card.dart';
import 'package:agrismart/presentation/screens/ai_model_info_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;
  final _backendUrlController = TextEditingController();
  
  // Dynamic Data
  int _totalScans = 0;
  int _cropScans = 0;
  int _fertScans = 0;
  int _diseScans = 0;
  List<HistoryEntry> _recentLogs = [];
  bool _isDiseaseModelOnline = false;
  bool _isCropModelOnline = false;
  bool _isLoading = true;
  List<dynamic> _fertilizersList = [];
  bool _loadingFertilizers = false;

  Future<void> _fetchFertilizers() async {
    setState(() => _loadingFertilizers = true);
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/fertilizers'),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        setState(() {
          _fertilizersList = jsonDecode(res.body);
        });
      }
    } catch (e) {
      print('Error loading fertilizers: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingFertilizers = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _backendUrlController.text = ApiConfig.baseUrl;
    _loadAdminData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _backendUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    
    // 1. Fetch real history for stats
    final history = await HistoryService().loadHistory();
    
    // 2. Perform live health checks
    bool diseaseOnline = await _checkHealth('${ApiConfig.baseUrl}/api/v1/predict-disease');
    bool cropOnline = await _checkHealth('${ApiConfig.baseUrl}/api/v1/predict-crop'); // Assuming this exists or returns 405/422 if online

    // Load fertilizers list
    _fetchFertilizers();

    if (mounted) {
      setState(() {
        _totalScans = history.length;
        _cropScans = history.where((e) => e.type == 'Crop Prediction').length;
        _fertScans = history.where((e) => e.type == 'Fertilizer Suggest').length;
        _diseScans = history.where((e) => e.type == 'Disease Detection').length;
        _recentLogs = history.take(10).toList();
        _isDiseaseModelOnline = diseaseOnline;
        _isCropModelOnline = cropOnline;
        _isLoading = false;
      });
    }
  }

  Future<bool> _checkHealth(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 2));
      // Even if it returns 405 Method Not Allowed, it means server is UP
      return response.statusCode != 404;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F0),
      ),
      child: Row(
        children: [
          // ── Sidebar ──
          _buildSidebar(),
          
          // ── Main Content Area ──
          Expanded(
            child: Column(
              children: [
                _buildTopHeader(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildOverviewTab(),
                      _buildUserManagementTab(),
                      _buildModelHealthTab(),
                      _buildManageFertilizersTab(),
                      _buildSettingsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Sidebar Widget ──
  Widget _buildSidebar() {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppTheme.primaryColor, AppTheme.secondaryColor]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(FontAwesomeIcons.shieldHalved, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Admin Console', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              ],
            ),
          ),
          _sidebarItem(0, 'Dashboard', FontAwesomeIcons.chartPie),
          _sidebarItem(1, 'User Accounts', FontAwesomeIcons.users),
          _sidebarItem(2, 'AI Model Status', FontAwesomeIcons.microchip),
          _sidebarItem(3, 'Manage Fertilizers', FontAwesomeIcons.flask),
          _sidebarItem(4, 'System Settings', FontAwesomeIcons.gears),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  const Text('System Version', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const Text('v2.4.0-stable', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, String title, IconData icon) {
    bool isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
            _tabController.animateTo(index);
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : AppTheme.textSecondary),
              const SizedBox(width: 16),
              Text(title, style: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top Header ──
  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      color: Colors.white,
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back, Admin', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text('Here is what\'s happening with AgriSmart today.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                const Text('System Online', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          const CircleAvatar(
            backgroundColor: Color(0xFFE0E0E0),
            child: Icon(Icons.person, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Overview ──
  Widget _buildOverviewTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    
    return RefreshIndicator(
      onRefresh: _loadAdminData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatCard('Total Farm Scans', '$_totalScans', FontAwesomeIcons.leaf, Colors.green, '+${((_totalScans/20)*100).toInt()}%'),
                const SizedBox(width: 20),
                _buildStatCard('Disease Scans', '$_diseScans', FontAwesomeIcons.bug, Colors.purple, 'Real-time'),
                const SizedBox(width: 20),
                _buildStatCard('Crop Suggestions', '$_cropScans', FontAwesomeIcons.wheatAwn, Colors.blue, 'Active'),
                const SizedBox(width: 20),
                _buildStatCard('Fertilizer Logs', '$_fertScans', FontAwesomeIcons.flask, Colors.orange, 'Verified'),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildActivityChart()),
                const SizedBox(width: 24),
                Expanded(child: _buildRecentLogs()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String trend) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 20),
                ),
                Text(trend, style: TextStyle(color: trend.startsWith('+') ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 20),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System Usage Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 3), const FlSpot(2, 2), const FlSpot(4, 5),
                      const FlSpot(6, 3.5), const FlSpot(8, 4), const FlSpot(10, 8),
                      const FlSpot(12, 6),
                    ],
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryColor.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentLogs() {
    return Container(
      padding: const EdgeInsets.all(24),
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Real-time Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: _recentLogs.isEmpty 
              ? const Center(child: Text('No activity yet', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                itemCount: _recentLogs.length,
                itemBuilder: (context, index) {
                  final log = _recentLogs[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18, 
                          backgroundColor: _colorFor(log.type).withOpacity(0.1), 
                          child: Icon(_iconFor(log.type), size: 14, color: _colorFor(log.type))
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(log.result, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                              Text(log.type, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                        Text(log.formattedDate.split(' · ')[1], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  );
                },
              ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String type) {
    return switch (type) {
      'Crop Prediction'     => FontAwesomeIcons.wheatAwn,
      'Fertilizer Suggest'  => FontAwesomeIcons.flask,
      'Disease Detection'   => FontAwesomeIcons.bug,
      _                     => FontAwesomeIcons.clockRotateLeft,
    };
  }

  Color _colorFor(String type) {
    return switch (type) {
      'Crop Prediction'     => AppTheme.primaryColor,
      'Fertilizer Suggest'  => const Color(0xFFE65100),
      'Disease Detection'   => Colors.purple,
      _                     => AppTheme.textSecondary,
    };
  }

  // ── Tab 2: User Management ──
  Widget _buildUserManagementTab() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Registered Farmers', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add New User'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(3),
                    2: FlexColumnWidth(2),
                    3: FlexColumnWidth(2),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade50),
                      children: const [
                        Padding(padding: EdgeInsets.all(16), child: Text('User ID', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(16), child: Text('Email Address', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(16), child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(16), child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                    _userRow('USR-001', 'farmer.john@gmail.com', 'Active'),
                    _userRow('USR-002', 'mark.crops@outlook.com', 'Active'),
                    _userRow('USR-003', 'sarah.agri@vsnl.com', 'Pending'),
                    _userRow('USR-004', 'admin.master@agrismart.ai', 'Active'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TableRow _userRow(String id, String email, String status) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(16), child: Text(id)),
        Padding(padding: const EdgeInsets.all(16), child: Text(email)),
        Padding(padding: const EdgeInsets.all(16), child: Text(status, style: TextStyle(color: status == 'Active' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold))),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.edit, size: 18, color: Colors.blue), onPressed: () {}),
              IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () {}),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tab 3: Model Health ──
  Widget _buildModelHealthTab() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Row(
            children: [
              _buildModelCard('Disease Detection', _isDiseaseModelOnline ? 'Online' : 'Offline', 'MobileNetV2 based', Colors.purple),
              const SizedBox(width: 20),
              _buildModelCard('Crop Recommend', _isCropModelOnline ? 'Online' : 'Offline', 'RandomForest based', Colors.green),
              const SizedBox(width: 20),
              _buildModelCard('Fertilizer AI', 'Online', 'Rule-based Expert System', Colors.orange),
            ],
          ),
          const SizedBox(height: 32),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Model Training Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                const Text('Current Task: Disease Model Retraining (Kaggle Dataset)'),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: 0.65,
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Epoch 8/12', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    Text('65%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelCard(String name, String status, String metric, Color color) {
    bool isOnline = status == 'Online';
    return Expanded(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AIModelInfoScreen()),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(20), 
            border: Border.all(color: color.withOpacity(0.2))
          ),
          child: Column(
            children: [
              Icon(FontAwesomeIcons.robot, color: color, size: 30),
              const SizedBox(height: 16),
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(status, style: TextStyle(color: isOnline ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
              const Divider(height: 24),
              Text(metric, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab 4: Settings ──
  Widget _buildSettingsTab() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('System Configurations', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Text(
              'Backend Server URL',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _backendUrlController,
                      decoration: const InputDecoration(
                        hintText: 'e.g., http://192.168.1.15:8000',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final newUrl = _backendUrlController.text.trim();
                    if (newUrl.isNotEmpty) {
                      await ApiConfig.setBaseUrl(newUrl);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('API Base URL updated to: ${ApiConfig.baseUrl}'),
                            backgroundColor: AppTheme.primaryColor,
                          ),
                        );
                        _loadAdminData(); // Refresh health status using new URL
                      }
                    }
                  },
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            ListTile(
              title: const Text('Maintenance Mode'),
              subtitle: const Text('Disable all AI requests for system updates'),
              trailing: Switch(value: false, onChanged: (v) {}),
            ),
            const Divider(),
            ListTile(
              title: const Text('Auto-Retrain Models'),
              subtitle: const Text('Automatically start training when new data threshold is met'),
              trailing: Switch(value: true, onChanged: (v) {}),
            ),
            const Divider(),
            ListTile(
              title: const Text('API Access Keys'),
              subtitle: const Text('Manage third-party integration tokens'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
  }

  // ── Tab: Manage Fertilizers ──
  Widget _buildManageFertilizersTab() {
    if (_loadingFertilizers) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }
    if (_fertilizersList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FontAwesomeIcons.flask, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No fertilizers loaded or backend offline.', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchFertilizers,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: const Text('Retry Connection', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Manage Fertilizers Knowledge Base', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
                  onPressed: _fetchFertilizers,
                )
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: _fertilizersList.length,
                itemBuilder: (context, index) {
                  final fert = _fertilizersList[index];
                  final name = fert['recommended_fertilizer'] ?? 'Unknown';
                  final formula = fert['formula'] ?? '';
                  final npk = fert['npk_ratio'] ?? '';
                  final type = fert['fertilizer_type'] ?? '';
                  final colorHex = fert['color_hex'] ?? '0xFF546E7A';
                  final desc = fert['description'] ?? '';
                  Color fColor;
                  try {
                    fColor = Color(int.parse(colorHex));
                  } catch (_) {
                    fColor = Colors.grey;
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: fColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(FontAwesomeIcons.flask, color: fColor, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: fColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        formula,
                                        style: TextStyle(color: fColor, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'NPK Ratio: $npk  |  Type: $type',
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  desc,
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _editFertilizerDialog(fert),
                            icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                            label: const Text('Edit', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editFertilizerDialog(Map<String, dynamic> fert) {
    final name = fert['recommended_fertilizer'] ?? '';
    final formulaCtrl = TextEditingController(text: fert['formula'] ?? '');
    final npkCtrl = TextEditingController(text: fert['npk_ratio'] ?? '');
    final typeCtrl = TextEditingController(text: fert['fertilizer_type'] ?? '');
    final colorCtrl = TextEditingController(text: fert['color_hex'] ?? '0xFF546E7A');
    final descCtrl = TextEditingController(text: fert['description'] ?? '');
    final methodCtrl = TextEditingController(text: fert['application_method'] ?? '');
    
    final List<dynamic> bestForList = fert['best_for_crops'] ?? [];
    final bestForCtrl = TextEditingController(text: bestForList.join(', '));

    final List<dynamic> scheduleList = fert['application_schedule'] ?? [];
    final scheduleCtrl = TextEditingController(text: scheduleList.join(', '));

    final List<dynamic> benefitsList = fert['benefits'] ?? [];
    final benefitsCtrl = TextEditingController(text: benefitsList.join(', '));

    final List<dynamic> precautionsList = fert['precautions'] ?? [];
    final precautionsCtrl = TextEditingController(text: precautionsList.join(', '));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Fertilizer: $name', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _dialogField(formulaCtrl, 'Formula', 'e.g. CO(NH2)2'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dialogField(npkCtrl, 'NPK Ratio', 'e.g. 46-0-0'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _dialogField(typeCtrl, 'Fertilizer Type', 'e.g. Nitrogenous'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dialogField(colorCtrl, 'Color Hex Code', 'e.g. 0xFF1565C0'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _dialogField(descCtrl, 'Description', 'Provide details...', maxLines: 3),
                  const SizedBox(height: 12),
                  _dialogField(bestForCtrl, 'Best for Crops (comma-separated)', 'e.g. Rice, Wheat, Maize'),
                  const SizedBox(height: 12),
                  _dialogField(scheduleCtrl, 'Application Schedule (comma-separated)', 'e.g. Basal Dose: 50 kg'),
                  const SizedBox(height: 12),
                  _dialogField(benefitsCtrl, 'Benefits (comma-separated)', 'e.g. Fast acting'),
                  const SizedBox(height: 12),
                  _dialogField(precautionsCtrl, 'Precautions (comma-separated)', 'e.g. Avoid rain'),
                  const SizedBox(height: 12),
                  _dialogField(methodCtrl, 'Application Method', 'e.g. Broadcast', maxLines: 2),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final payload = {
                  'formula': formulaCtrl.text.trim(),
                  'npk_ratio': npkCtrl.text.trim(),
                  'fertilizer_type': typeCtrl.text.trim(),
                  'color_hex': colorCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'best_for': bestForCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                  'schedule': scheduleCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                  'benefits': benefitsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                  'precautions': precautionsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                  'application_method': methodCtrl.text.trim(),
                };

                try {
                  final res = await http.put(
                    Uri.parse('${ApiConfig.baseUrl}/api/v1/fertilizers/$name'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode(payload),
                  ).timeout(const Duration(seconds: 5));

                  if (res.statusCode == 200) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$name updated successfully!'), backgroundColor: AppTheme.primaryColor),
                    );
                    _fetchFertilizers(); // Refresh list
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update: ${res.statusCode}'), backgroundColor: Colors.red),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _dialogField(TextEditingController ctrl, String label, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: ctrl,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}
