import 'package:flutter/material.dart';
import 'package:agrismart/core/theme.dart';
import 'package:agrismart/presentation/widgets/glass_card.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AIModelInfoScreen extends StatelessWidget {
  const AIModelInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text('AI Model Intelligence', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Model Architecture Header ──
            _buildHeaderCard(),
            const SizedBox(height: 32),
            
            const Text('Supported Disease Detection', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildSupportedClassesGrid(),
            
            const SizedBox(height: 32),
            const Text('Processing Pipeline', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildPipelineFlow(),
            
            const SizedBox(height: 32),
            _buildTechSpecCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.primaryColor, AppTheme.secondaryColor]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(FontAwesomeIcons.brain, color: Colors.white, size: 40),
          SizedBox(height: 20),
          Text('MobileNetV2 Architecture', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(
            'A lightweight convolutional neural network optimized for mobile and edge devices, delivering high-precision agricultural diagnosis.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportedClassesGrid() {
    final classes = [
      {'icon': FontAwesomeIcons.apple, 'name': 'Apple Scab'},
      {'icon': FontAwesomeIcons.apple, 'name': 'Black Rot'},
      {'icon': FontAwesomeIcons.pepperHot, 'name': 'Bacterial Spot'},
      {'icon': FontAwesomeIcons.cloudSun, 'name': 'Early Blight'},
      {'icon': FontAwesomeIcons.cloudShowersHeavy, 'name': 'Late Blight'},
      {'icon': FontAwesomeIcons.bug, 'name': 'Spider Mites'},
      {'icon': FontAwesomeIcons.virus, 'name': 'Mosaic Virus'},
      {'icon': FontAwesomeIcons.leaf, 'name': 'Leaf Mold'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(classes[index]['icon'] as IconData, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              Text(classes[index]['name'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPipelineFlow() {
    return GlassCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _flowStep(FontAwesomeIcons.camera, 'Capture'),
          const Icon(Icons.arrow_forward, color: Colors.grey, size: 16),
          _flowStep(FontAwesomeIcons.scissors, 'Crop'),
          const Icon(Icons.arrow_forward, color: Colors.grey, size: 16),
          _flowStep(FontAwesomeIcons.microchip, 'Analyze'),
          const Icon(Icons.arrow_forward, color: Colors.grey, size: 16),
          _flowStep(FontAwesomeIcons.checkDouble, 'Diagnose'),
        ],
      ),
    );
  }

  Widget _flowStep(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTechSpecCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3436),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Framework', style: TextStyle(color: Colors.white70)),
              Text('TensorFlow 2.15', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          Divider(color: Colors.white10, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Input Size', style: TextStyle(color: Colors.white70)),
              Text('224 x 224 x 3', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          Divider(color: Colors.white10, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Optimized For', style: TextStyle(color: Colors.white70)),
              Text('Edge Devices', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
