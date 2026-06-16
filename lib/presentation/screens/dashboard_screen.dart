import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:agrismart/core/theme.dart';
import 'package:agrismart/presentation/widgets/glass_card.dart';
import 'package:agrismart/presentation/widgets/stat_card.dart';
import 'package:agrismart/presentation/widgets/weather_widget.dart';
import 'package:agrismart/presentation/screens/mandi_rates_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Live Sensor Data State
  double nitrogenValue = 45.0;
  double phValue = 6.5;
  double healthValue = 92.0;
  Timer? _sensorTimer;
  final Random _random = Random();

  // Chart State
  String selectedFilter = '1M';
  List<FlSpot> chartData = [];

  @override
  void initState() {
    super.initState();
    _generateChartData('1M');
    _startSensorSimulation();
  }

  @override
  void dispose() {
    _sensorTimer?.cancel();
    super.dispose();
  }

  void _startSensorSimulation() {
    // Simulate live sensor readings changing slightly every 3 seconds
    _sensorTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          // Generate small random changes
          nitrogenValue = (40.0 + _random.nextDouble() * 10.0); // 40-50 range
          phValue = (6.0 + _random.nextDouble() * 1.5); // 6.0-7.5 range
          healthValue = (85.0 + _random.nextDouble() * 14.0); // 85-99 range
        });
      }
    });
  }

  void _generateChartData(String filter) {
    setState(() {
      selectedFilter = filter;
      chartData.clear();
      int pointsCount;
      double variance;
      
      switch (filter) {
        case '1W':
          pointsCount = 7;
          variance = 1.0;
          break;
        case '1M':
          pointsCount = 15; // sample every 2 days
          variance = 2.5;
          break;
        case '6M':
          pointsCount = 24; // 4 points per month
          variance = 5.0;
          break;
        case '1Y':
          pointsCount = 12; // 1 point per month
          variance = 8.0;
          break;
        default:
          pointsCount = 7;
          variance = 1.0;
      }

      double currentY = 3.0;
      for (int i = 0; i < pointsCount; i++) {
        // Create a realistic-looking trend
        currentY += (_random.nextDouble() * variance) - (variance / 2.2);
        if (currentY < 1) currentY = 1.0 + _random.nextDouble(); // minimum bound
        chartData.add(FlSpot(i.toDouble(), currentY));
      }
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroSection(),
          SizedBox(height: 32),
          _buildStatsRow(),
          SizedBox(height: 32),
          _buildMarketOverview(),
          SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildChartSection(),
              ),
              SizedBox(width: 32),
              Expanded(
                flex: 1,
                child: DynamicWeatherWidget(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    final greeting = _getGreeting();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, Farmer!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Your sensors are online. Get real-time insights on soil health, fertilizer needs, and disease detection directly from your dashboard.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _showAIAnalysisDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Analyze Farm Data', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          SizedBox(width: 32),
          Icon(
            FontAwesomeIcons.seedling,
            size: 120,
            color: Colors.white70,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    // Dynamic coloring based on thresholds
    Color phColor = (phValue < 5.5 || phValue > 7.5) ? Colors.red : Colors.purple;
    Color healthColor = (healthValue < 80.0) ? Colors.red : AppTheme.primaryColor;
    
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Live Soil Nitrogen',
            value: '${nitrogenValue.toStringAsFixed(1)} mg/kg',
            icon: FontAwesomeIcons.flask,
            iconColor: Colors.blue,
            subtitle: 'Updating every 3s...',
          ),
        ),
        SizedBox(width: 24),
        Expanded(
          child: StatCard(
            title: 'Live Soil pH',
            value: phValue.toStringAsFixed(2),
            icon: FontAwesomeIcons.vial,
            iconColor: phColor,
            subtitle: (phValue < 5.5 || phValue > 7.5) ? 'Warning: Suboptimal' : 'Optimal Range',
          ),
        ),
        SizedBox(width: 24),
        Expanded(
          child: StatCard(
            title: 'Crop Health Index',
            value: '${healthValue.toStringAsFixed(1)}%',
            icon: FontAwesomeIcons.heartPulse,
            iconColor: healthColor,
            subtitle: 'Live visual analysis',
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Yield Prediction Analytics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Row(
                children: ['1W', '1M', '6M', '1Y'].map((filter) {
                  final isSelected = selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: InkWell(
                      onTap: () => _generateChartData(filter),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryColor : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          SizedBox(height: 32),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData,
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryColor.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 500), // Smooth transition animation
              curve: Curves.easeInOut,
            ),
          ),
        ],
      ),
    );
  }
  void _showAIAnalysisDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _AIAnalysisDialog(),
    );
  }

  Widget _buildMarketOverview() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.trending_up, color: Colors.green, size: 32),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Market Trends (Mandi)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Check live prices for 100+ commodities across Indian markets.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MandiRatesScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Row(
              children: [
                Text('View Prices'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AIAnalysisDialog extends StatefulWidget {
  const _AIAnalysisDialog();

  @override
  State<_AIAnalysisDialog> createState() => _AIAnalysisDialogState();
}

class _AIAnalysisDialogState extends State<_AIAnalysisDialog> {
  bool _isAnalyzing = true;
  String _statusText = "Initializing AI Engine...";
  int _step = 0;

  final List<String> _analysisSteps = [
    "Fetching Live IoT Sensor Data...",
    "Correlating with Local Weather...",
    "Running Machine Learning Models...",
    "Generating Actionable Insights...",
  ];

  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  void _startAnalysis() async {
    for (int i = 0; i < _analysisSteps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() {
          _statusText = _analysisSteps[i];
          _step = i;
        });
      }
    }
    
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(32),
        decoration: AppTheme.glassDecoration,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _isAnalyzing ? _buildLoadingState() : _buildResultState(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      key: const ValueKey("loading"),
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 100,
              width: 100,
              child: CircularProgressIndicator(
                value: (_step + 1) / _analysisSteps.length,
                strokeWidth: 8,
                backgroundColor: Colors.grey.withOpacity(0.2),
                color: AppTheme.primaryColor,
              ),
            ),
            const Icon(FontAwesomeIcons.microchip, size: 40, color: AppTheme.primaryColor),
          ],
        ),
        const SizedBox(height: 32),
        const Text(
          'AI Farm Analysis',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          _statusText,
          style: TextStyle(fontSize: 16, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildResultState() {
    return Column(
      key: const ValueKey("result"),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 32),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Analysis Complete', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Overall Farm Health: 88% (Excellent)', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Divider(),
        ),
        const Text('AI Recommendations:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        _buildInsightItem(
          icon: FontAwesomeIcons.leaf,
          color: Colors.green,
          text: 'Nitrogen levels are dropping slightly. Apply organic compost within 5 days.',
        ),
        const SizedBox(height: 12),
        _buildInsightItem(
          icon: FontAwesomeIcons.droplet,
          color: Colors.blue,
          text: 'Soil moisture is optimal. No irrigation required for the next 48 hours.',
        ),
        const SizedBox(height: 12),
        _buildInsightItem(
          icon: FontAwesomeIcons.cloudSun,
          color: Colors.orange,
          text: 'Clear skies forecasted. Perfect window for targeted fertilizer application.',
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Got it, thanks!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightItem({required IconData icon, required Color color, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ),
      ],
    );
  }
}
