import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:agrismart/core/theme.dart';
import 'package:agrismart/presentation/widgets/glass_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Icon(FontAwesomeIcons.leaf, size: 64, color: Colors.white),
          ),
          SizedBox(height: 24),
          Text(
            'AgriSmart Assistant',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          SizedBox(height: 8),
          Text(
            'Version 1.0.0',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          SizedBox(height: 48),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(FontAwesomeIcons.bullseye, size: 32, color: AppTheme.primaryColor),
                      SizedBox(height: 16),
                      Text('Our Mission', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 12),
                      Text(
                        'To empower farmers with cutting-edge artificial intelligence, enabling them to make data-driven decisions that increase yield, optimize resource usage, and promote sustainable agriculture.',
                        style: TextStyle(height: 1.5, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 32),
              Expanded(
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(FontAwesomeIcons.microchip, size: 32, color: AppTheme.primaryColor),
                      SizedBox(height: 16),
                      Text('Technologies', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 12),
                      _buildTechRow('Flutter', 'Cross-platform UI Framework'),
                      SizedBox(height: 8),
                      _buildTechRow('TensorFlow Lite', 'On-device Machine Learning'),
                      SizedBox(height: 8),
                      _buildTechRow('REST API', 'Backend Data Synchronization'),
                      SizedBox(height: 8),
                      _buildTechRow('Provider/Riverpod', 'State Management'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 48),
          Text('Built with ❤️ for a greener future', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildTechRow(String title, String desc) {
    return Row(
      children: [
        Icon(Icons.check_circle, size: 16, color: AppTheme.primaryColor),
        SizedBox(width: 8),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        Text(' - '),
        Text(desc, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      ],
    );
  }
}
