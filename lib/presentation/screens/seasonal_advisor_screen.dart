import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:agrismart/core/theme.dart';
import 'package:agrismart/presentation/widgets/glass_card.dart';

class SeasonalAdvisorScreen extends StatefulWidget {
  const SeasonalAdvisorScreen({super.key});

  @override
  State<SeasonalAdvisorScreen> createState() => _SeasonalAdvisorScreenState();
}

class _SeasonalAdvisorScreenState extends State<SeasonalAdvisorScreen> {
  String _currentSeason = "";
  String _seasonDesc = "";
  String _aiTip = "";
  List<Map<String, dynamic>> _suggestedCrops = [];
  List<Map<String, dynamic>> _pestAlerts = [];

  @override
  void initState() {
    super.initState();
    _calculateSeason();
  }

  void _calculateSeason() {
    final month = DateTime.now().month;
    
    if (month >= 6 && month <= 10) {
      _currentSeason = "Kharif Season";
      _seasonDesc = "Monsoon period. High humidity.";
      _aiTip = "Monsoon rains can cause soil erosion. Ensure proper drainage channels in your Rice fields.";
      _suggestedCrops = [
        {'name': 'Rice', 'price': 'High', 'water': 'High', 'time': '150 Days', 'icon': FontAwesomeIcons.wheatAwn, 'color': Colors.blue},
        {'name': 'Maize', 'price': 'Med', 'water': 'Med', 'time': '110 Days', 'icon': FontAwesomeIcons.seedling, 'color': Colors.orange},
      ];
      _pestAlerts = [
        {'name': 'Stem Borer', 'impact': 'High', 'desc': 'Attacks Rice stems during growth.'},
        {'name': 'Fall Armyworm', 'impact': 'Critical', 'desc': 'Major threat to Maize crops.'},
      ];
    } else if (month >= 11 || month <= 3) {
      _currentSeason = "Rabi Season";
      _seasonDesc = "Winter period. Cool climate.";
      _aiTip = "Early morning frost can damage Mustard flowers. Use smoke or light irrigation for protection.";
      _suggestedCrops = [
        {'name': 'Wheat', 'price': 'High', 'water': 'Med', 'time': '140 Days', 'icon': FontAwesomeIcons.wheatAwn, 'color': Colors.amber},
        {'name': 'Mustard', 'price': 'V.High', 'water': 'Low', 'time': '120 Days', 'icon': FontAwesomeIcons.sun, 'color': Colors.yellow.shade800},
      ];
      _pestAlerts = [
        {'name': 'Aphids', 'impact': 'High', 'desc': 'Sucks sap from Mustard flowers.'},
        {'name': 'Pod Borer', 'impact': 'Med', 'desc': 'Common in Pulse crops.'},
      ];
    } else {
      _currentSeason = "Zaid Season";
      _seasonDesc = "Summer period. Fast growth.";
      _aiTip = "Temperatures are rising! Water your Watermelons in the evening to reduce evaporation loss.";
      _suggestedCrops = [
        {'name': 'Watermelon', 'price': 'High', 'water': 'High', 'time': '90 Days', 'icon': FontAwesomeIcons.solidCircle, 'color': Colors.red},
        {'name': 'Cucumber', 'price': 'Med', 'water': 'Med', 'time': '60 Days', 'icon': FontAwesomeIcons.leaf, 'color': Colors.green},
      ];
      _pestAlerts = [
        {'name': 'Fruit Fly', 'impact': 'High', 'desc': 'Damages fruit quality in melons.'},
        {'name': 'Red Pumpkin Beetle', 'impact': 'Med', 'desc': 'Feeds on young seedlings.'},
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildAITipBanner(),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildMainContent()),
              const SizedBox(width: 32),
              Expanded(flex: 2, child: _buildPestSection()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seasonal Crop Advisor', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            Text('Intelligent seasonal planning and risk management.', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
        _buildCurrentDateBadge(),
      ],
    );
  }

  Widget _buildCurrentDateBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          const Icon(FontAwesomeIcons.calendarDay, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text('${DateTime.now().day} May 2026', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildAITipBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
            child: const Icon(FontAwesomeIcons.robot, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI SEASONAL TIP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2, color: AppTheme.primaryColor)),
                const SizedBox(height: 4),
                Text(_aiTip, style: const TextStyle(fontSize: 14, height: 1.4, color: AppTheme.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSeasonBanner(),
        const SizedBox(height: 32),
        const Text('Recommended Crops', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.0,
          ),
          itemCount: _suggestedCrops.length,
          itemBuilder: (context, index) => _buildCropCard(_suggestedCrops[index]),
        ),
      ],
    );
  }

  Widget _buildSeasonBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.primaryColor, Colors.teal.shade700]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_currentSeason, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(_seasonDesc, style: TextStyle(color: Colors.white.withOpacity(0.9))),
        ],
      ),
    );
  }

  Widget _buildCropCard(Map<String, dynamic> crop) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(crop['icon'], color: crop['color'], size: 24),
              Text(crop['price'], style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 12),
          Text(crop['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildCropTimeline(crop['time']),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showHowToGrow(crop['name']),
              style: ElevatedButton.styleFrom(
                backgroundColor: crop['color'].withOpacity(0.1),
                foregroundColor: crop['color'],
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Guide', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropTimeline(String days) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Timeline', style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text(days, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Expanded(flex: 3, child: Container(decoration: BoxDecoration(color: Colors.green.shade400, borderRadius: const BorderRadius.horizontal(left: Radius.circular(10))))),
              Expanded(flex: 7, child: Container()),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text('Phase: Sowing/Growth', style: TextStyle(fontSize: 9, fontStyle: FontStyle.italic)),
      ],
    );
  }

  Widget _buildPestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(FontAwesomeIcons.triangleExclamation, color: Colors.orange, size: 16),
            SizedBox(width: 8),
            Text('PEST ALERTS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
          ],
        ),
        const SizedBox(height: 16),
        ..._pestAlerts.map((pest) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.withOpacity(0.2)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(pest['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(pest['impact'], style: const TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(pest['desc'], style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4)),
            ],
          ),
        )),
      ],
    );
  }

  void _showHowToGrow(String crop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Growing Guide: $crop', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildStep(1, 'Land Preparation', 'Ensure soil is well-aerated.'),
              _buildStep(2, 'Seed Treatment', 'Treat seeds to prevent fungal infections.'),
              _buildStep(3, 'Nutrition', 'Add NPK as per recommendation.'),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(int num, String title, String desc) {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(children: [
      CircleAvatar(radius: 12, child: Text('$num', style: const TextStyle(fontSize: 12))),
      const SizedBox(width: 16),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ]),
    ]));
  }
}
