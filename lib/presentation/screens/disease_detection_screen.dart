import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:agrismart/core/theme.dart';
import 'package:agrismart/core/history_service.dart';
import 'package:agrismart/core/api_config.dart';
import 'package:agrismart/presentation/widgets/glass_card.dart';

// ─── Data Model ────────────────────────────────────────────────────────────────
class DiseaseResult {
  final String disease;
  final String confidence;
  final double confidenceValue;
  final String severity;
  final bool isHealthy;
  final String description;
  final List<String> symptoms;
  final List<String> treatments;
  final String prevention;

  DiseaseResult({
    required this.disease,
    required this.confidence,
    required this.confidenceValue,
    required this.severity,
    required this.isHealthy,
    required this.description,
    required this.symptoms,
    required this.treatments,
    required this.prevention,
  });

  factory DiseaseResult.fromJson(Map<String, dynamic> json) {
    return DiseaseResult(
      disease: json['disease'] ?? 'Unknown',
      confidence: json['confidence'] ?? '0%',
      confidenceValue: (json['confidence_value'] ?? 0.0).toDouble(),
      severity: json['severity'] ?? 'Unknown',
      isHealthy: json['is_healthy'] ?? false,
      description: json['description'] ?? '',
      symptoms: List<String>.from(json['symptoms'] ?? []),
      treatments: List<String>.from(json['treatments'] ?? []),
      prevention: json['prevention'] ?? '',
    );
  }
}

// ─── Main Screen ───────────────────────────────────────────────────────────────
class DiseaseDetectionScreen extends StatefulWidget {
  const DiseaseDetectionScreen({super.key});

  @override
  State<DiseaseDetectionScreen> createState() => _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState extends State<DiseaseDetectionScreen>
    with SingleTickerProviderStateMixin {
  Uint8List? _imageBytes;
  String? _imageName;
  bool _isAnalyzing = false;
  DiseaseResult? _result;
  String? _errorMessage;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _imageBytes = result.files.single.bytes;
        _imageName = result.files.single.name;
        _result = null;
        _errorMessage = null;
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageBytes == null) return;

    setState(() {
      _isAnalyzing = true;
      _result = null;
      _errorMessage = null;
    });

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/predict-disease');
      final request = http.MultipartRequest('POST', uri);

      // Determine MIME type from file extension
      final ext = (_imageName ?? 'leaf.jpg').split('.').last.toLowerCase();
      final mimeType = switch (ext) {
        'png'  => 'image/png',
        'webp' => 'image/webp',
        'bmp'  => 'image/bmp',
        'gif'  => 'image/gif',
        _      => 'image/jpeg',
      };

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          _imageBytes!,
          filename: _imageName ?? 'leaf.jpg',
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = DiseaseResult.fromJson(data);
        // Save to history
        // Save to history
        await HistoryService().addEntry(HistoryEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'Disease Detection',
          result: result.disease,
          detail: 'Severity: ${result.severity} | Conf: ${result.confidence}',
          status: result.isHealthy ? 'Healthy' : 'Diseased',
          timestamp: DateTime.now(),
        ));
        setState(() {
          _result = result;
          _isAnalyzing = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}. Please try again.';
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error. Make sure the backend is running.\n$e';
        _isAnalyzing = false;
      });
    }
  }

  void _clearImage() {
    setState(() {
      _imageBytes = null;
      _imageName = null;
      _result = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(FontAwesomeIcons.microscope, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plant Disease Detection',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'AI-powered leaf analysis using MobileNetV2',
                    style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Supported crops banner ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.eco, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Supports: Apple · Corn · Tomato',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Main content row ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Upload
              Expanded(flex: 1, child: _buildUploadSection()),
              const SizedBox(width: 28),
              // Right: Result
              Expanded(
                flex: 1,
                child: _result != null
                    ? _buildResultSection()
                    : _errorMessage != null
                        ? _buildErrorState()
                        : _buildEmptyState(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Upload Section ───────────────────────────────────────────────────────────
  Widget _buildUploadSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FontAwesomeIcons.fileImage, color: AppTheme.primaryColor, size: 18),
              const SizedBox(width: 10),
              Text(
                'Upload Leaf Image',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Drop zone
          GestureDetector(
            onTap: _imageBytes == null ? _pickImage : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 260,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _imageBytes != null
                    ? Colors.transparent
                    : AppTheme.primaryColor.withOpacity(0.03),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _imageBytes != null
                      ? AppTheme.primaryColor.withOpacity(0.5)
                      : Colors.grey.withOpacity(0.25),
                  width: 2,
                  style: _imageBytes != null ? BorderStyle.solid : BorderStyle.solid,
                ),
              ),
              child: _imageBytes != null ? _buildImagePreview() : _buildDropZoneContent(),
            ),
          ),
          const SizedBox(height: 20),

          // Tip
          if (_imageBytes == null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.tips_and_updates, color: Colors.amber.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'For best results, use a close-up photo of a single leaf with good lighting.',
                      style: TextStyle(fontSize: 12, color: Colors.amber.shade800),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Buttons
          Row(
            children: [
              if (_imageBytes != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearImage,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Clear'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _imageBytes != null && !_isAnalyzing ? _analyzeImage : null,
                  icon: _isAnalyzing
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(FontAwesomeIcons.magnifyingGlass, size: 16),
                  label: Text(
                    _isAnalyzing ? 'Analyzing...' : 'Analyze with AI',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade200,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
        ),
        // Overlay while analyzing
        if (_isAnalyzing)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: Colors.black54,
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (_, __) => Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(FontAwesomeIcons.microscope, color: Colors.white, size: 32),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'AI Scanning...',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Analyzing leaf patterns',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        // Remove button (when not analyzing)
        if (!_isAnalyzing)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: _clearImage,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        // File name tag
        if (!_isAnalyzing)
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _imageName ?? 'image.jpg',
                style: const TextStyle(color: Colors.white, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDropZoneContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            FontAwesomeIcons.cloudArrowUp,
            size: 40,
            color: AppTheme.primaryColor.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Click to upload a leaf photo',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Supports JPG, PNG, WEBP · Max 10MB',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  // ─── Empty State ─────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return GlassCard(
      child: SizedBox(
        height: 380,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(FontAwesomeIcons.microscope, size: 48, color: Colors.grey.shade300),
              ),
              const SizedBox(height: 24),
              Text(
                'Awaiting Analysis',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload a leaf image and tap\n"Analyze with AI" to get started',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
              const SizedBox(height: 32),
              _buildInfoBadge(FontAwesomeIcons.bolt, '< 5 sec analysis', Colors.amber),
              const SizedBox(height: 10),
              _buildInfoBadge(FontAwesomeIcons.shield, '7 disease classes', AppTheme.primaryColor),
              const SizedBox(height: 10),
              _buildInfoBadge(FontAwesomeIcons.pills, 'Full treatment plans', Colors.blue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 12, color: color),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ─── Error State ─────────────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return GlassCard(
      child: SizedBox(
        height: 380,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
              ),
              const SizedBox(height: 16),
              Text('Analysis Failed',
                  style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red.shade700,
                  )),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _errorMessage ?? 'Unknown error occurred.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade600, fontSize: 13),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _analyzeImage,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Result Section ───────────────────────────────────────────────────────────
  Widget _buildResultSection() {
    final r = _result!;
    final Color statusColor = r.isHealthy
        ? const Color(0xFF2E7D32)
        : r.severity == 'High'
            ? Colors.red.shade700
            : Colors.orange.shade700;
    final Color statusBg = r.isHealthy
        ? Colors.green.shade50
        : r.severity == 'High'
            ? Colors.red.shade50
            : Colors.orange.shade50;
    final IconData statusIcon = r.isHealthy
        ? FontAwesomeIcons.circleCheck
        : FontAwesomeIcons.triangleExclamation;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status banner ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: FaIcon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.isHealthy ? 'Plant is Healthy! ✓' : 'Disease Detected',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        r.disease,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Severity chip
                if (!r.isHealthy)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      r.severity,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Description ──
          Text(
            r.description,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 20),

          // ── Confidence bar ──
          _buildSectionLabel(FontAwesomeIcons.chartBar, 'Confidence Score'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: r.confidenceValue),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOut,
                    builder: (_, value, __) => LinearProgressIndicator(
                      value: value,
                      minHeight: 14,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                r.confidence,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Symptoms ──
          _buildSectionLabel(FontAwesomeIcons.listUl, 'Symptoms Observed'),
          const SizedBox(height: 10),
          ...r.symptoms.map((s) => _buildBulletRow(s, statusColor)),
          const SizedBox(height: 24),

          // ── Treatments ──
          _buildSectionLabel(FontAwesomeIcons.pills, 'Treatment Recommendations'),
          const SizedBox(height: 10),
          ...r.treatments.asMap().entries.map((entry) {
            final parts = entry.value.split(': ');
            final title = parts.first;
            final desc = parts.length > 1 ? parts.sublist(1).join(': ') : '';
            return _buildTreatmentCard(entry.key + 1, title, desc, statusColor);
          }),
          const SizedBox(height: 20),

          // ── Prevention ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(FontAwesomeIcons.shieldHalved, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prevention Tip',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        r.prevention,
                        style: TextStyle(fontSize: 13, color: Colors.blue.shade800, height: 1.4),
                      ),
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

  Widget _buildSectionLabel(IconData icon, String label) {
    return Row(
      children: [
        FaIcon(icon, size: 14, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBulletRow(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentCard(int idx, String title, String desc, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$idx',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                  ),
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
