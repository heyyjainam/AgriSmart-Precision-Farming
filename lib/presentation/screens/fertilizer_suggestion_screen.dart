import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:agrismart/core/theme.dart';
import 'package:agrismart/core/history_service.dart';
import 'package:agrismart/core/api_config.dart';
import 'package:agrismart/presentation/widgets/glass_card.dart';

class FertilizerResult {
  final String fertilizer, formula, npkRatio, fertilizerType, colorHex;
  final String description, applicationMethod, nStatus, pStatus, kStatus, totalDose;
  final List<String> bestFor, schedule, benefits, precautions;

  FertilizerResult({
    required this.fertilizer, required this.formula, required this.npkRatio,
    required this.fertilizerType, required this.colorHex, required this.description,
    required this.applicationMethod, required this.nStatus, required this.pStatus,
    required this.kStatus, required this.totalDose,
    required this.bestFor, required this.schedule, required this.benefits, required this.precautions,
  });

  factory FertilizerResult.fromJson(Map<String, dynamic> j) => FertilizerResult(
    fertilizer: j['recommended_fertilizer'] ?? '',
    formula: j['formula'] ?? '',
    npkRatio: j['npk_ratio'] ?? '',
    fertilizerType: j['fertilizer_type'] ?? '',
    colorHex: j['color_hex'] ?? '0xFF2E7D32',
    description: j['description'] ?? '',
    applicationMethod: j['application_method'] ?? '',
    nStatus: j['n_status'] ?? 'Optimal',
    pStatus: j['p_status'] ?? 'Optimal',
    kStatus: j['k_status'] ?? 'Optimal',
    totalDose: j['total_dose_per_acre'] ?? '50 kg',
    bestFor: List<String>.from(j['best_for_crops'] ?? []),
    schedule: List<String>.from(j['application_schedule'] ?? []),
    benefits: List<String>.from(j['benefits'] ?? []),
    precautions: List<String>.from(j['precautions'] ?? []),
  );

  Color get color {
    try { return Color(int.parse(colorHex)); } catch (_) { return AppTheme.primaryColor; }
  }
}

class FertilizerSuggestionScreen extends StatefulWidget {
  const FertilizerSuggestionScreen({super.key});
  @override
  State<FertilizerSuggestionScreen> createState() => _FertilizerSuggestionScreenState();
}

class _FertilizerSuggestionScreenState extends State<FertilizerSuggestionScreen> {
  final _nCtrl = TextEditingController();
  final _pCtrl = TextEditingController();
  final _kCtrl = TextEditingController();
  String _selectedCrop = 'Rice';
  bool _isLoading = false;
  FertilizerResult? _result;
  String? _error;

  final List<String> _crops = [
    'Rice', 'Wheat', 'Maize', 'Sugarcane', 'Cotton',
    'Potato', 'Soybean', 'Groundnut', 'Mustard', 'Banana',
  ];

  @override
  void dispose() {
    _nCtrl.dispose(); _pCtrl.dispose(); _kCtrl.dispose();
    super.dispose();
  }

  Future<void> _getRecommendation() async {
    final n = double.tryParse(_nCtrl.text.trim());
    final p = double.tryParse(_pCtrl.text.trim());
    final k = double.tryParse(_kCtrl.text.trim());

    if (n == null || p == null || k == null) {
      setState(() => _error = 'Please enter valid numbers for N, P, and K.');
      return;
    }

    setState(() { _isLoading = true; _result = null; _error = null; });

    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/predict-fertilizer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'N': n, 'P': p, 'K': k, 'crop_type': _selectedCrop}),
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final result = FertilizerResult.fromJson(jsonDecode(res.body));
        // Save to history
        await HistoryService().addEntry(HistoryEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'Fertilizer Suggest',
          result: 'Recommended: ${result.fertilizer}',
          detail: 'Crop: $_selectedCrop | Ratio: ${result.npkRatio}',
          status: 'Active',
          timestamp: DateTime.now(),
        ));
        setState(() { _result = result; _isLoading = false; });
      } else {
        setState(() { _error = 'Server error ${res.statusCode}. Try again.'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Connection failed. Make sure backend is running.\n$e'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [const Color(0xFFE65100), const Color(0xFFFFA000)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(FontAwesomeIcons.flaskVial, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Fertilizer Suggestion', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              Text('ML-powered NPK analysis & fertilizer recommendation', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            ]),
          ]),
          const SizedBox(height: 32),

          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 3, child: _buildInputForm()),
            const SizedBox(width: 28),
            Expanded(flex: 2, child: _result != null ? _buildResultPanel() : _error != null ? _buildErrorState() : _buildEmptyState()),
          ]),
        ],
      ),
    );
  }

  Widget _buildInputForm() {
    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(FontAwesomeIcons.seedling, color: AppTheme.primaryColor, size: 16),
          const SizedBox(width: 8),
          Text('Soil Nutrient Inputs', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        ]),
        const SizedBox(height: 20),

        // NPK visual bar
        _buildNPKInfoBanner(),
        const SizedBox(height: 24),

        // Crop selector
        Text('Target Crop', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCrop, isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
              items: _crops.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) { if (v != null) setState(() => _selectedCrop = v); },
            ),
          ),
        ),
        const SizedBox(height: 24),

        // N P K inputs
        Text('Soil NPK Values (kg/ha)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildNPKField(_nCtrl, 'Nitrogen (N)', '0-120', const Color(0xFF1565C0))),
          const SizedBox(width: 12),
          Expanded(child: _buildNPKField(_pCtrl, 'Phosphorus (P)', '0-100', const Color(0xFF6A1B9A))),
          const SizedBox(width: 12),
          Expanded(child: _buildNPKField(_kCtrl, 'Potassium (K)', '0-100', const Color(0xFFBF360C))),
        ]),
        const SizedBox(height: 24),

        // Typical ranges hint
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Row(children: [
            Icon(Icons.tips_and_updates, color: Colors.amber.shade700, size: 15),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'Typical ranges: N: 0–120 · P: 0–100 · K: 0–100 kg/ha\nLow N (<40) → Urea · Low P (<30) → DAP · Low K (<30) → MOP',
              style: TextStyle(fontSize: 11.5, color: Colors.amber.shade800, height: 1.5),
            )),
          ]),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity, height: 54,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _getRecommendation,
            icon: _isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(FontAwesomeIcons.magnifyingGlass, size: 15),
            label: Text(_isLoading ? 'Analyzing...' : 'Get Recommendation', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildNPKField(TextEditingController ctrl, String label, String hint, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.normal),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          ),
        ),
      ),
    ]);
  }

  Widget _buildNPKInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withOpacity(0.05), Colors.transparent],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _npkChip('N', 'Nitrogen', 'Leaf Growth', const Color(0xFF1565C0)),
        _divider(),
        _npkChip('P', 'Phosphorus', 'Root & Flower', const Color(0xFF6A1B9A)),
        _divider(),
        _npkChip('K', 'Potassium', 'Fruit Quality', const Color(0xFFBF360C)),
      ]),
    );
  }

  Widget _npkChip(String sym, String name, String role, Color color) {
    return Column(children: [
      CircleAvatar(radius: 18, backgroundColor: color.withOpacity(0.12),
          child: Text(sym, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16))),
      const SizedBox(height: 4),
      Text(name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
      Text(role, style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
    ]);
  }

  Widget _divider() => Container(height: 40, width: 1, color: Colors.grey.shade200);

  // ── Empty State ──
  Widget _buildEmptyState() {
    return GlassCard(
      child: SizedBox(height: 420, child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(FontAwesomeIcons.flaskVial, size: 44, color: Colors.grey.shade300)),
        const SizedBox(height: 20),
        Text('Awaiting Input', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        Text('Enter soil NPK values and\nselect crop to get recommendation', textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        const SizedBox(height: 28),
        _badgeRow(FontAwesomeIcons.bolt, '< 2 sec result', Colors.amber),
        const SizedBox(height: 8),
        _badgeRow(FontAwesomeIcons.leaf, 'ML + rule-based', AppTheme.primaryColor),
        const SizedBox(height: 8),
        _badgeRow(FontAwesomeIcons.calendarDays, 'Full schedule', const Color(0xFFE65100)),
      ]))),
    );
  }

  Widget _badgeRow(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        FaIcon(icon, size: 11, color: color), const SizedBox(width: 7),
        Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  // ── Error State ──
  Widget _buildErrorState() {
    return GlassCard(
      child: SizedBox(height: 300, child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
        const SizedBox(height: 12),
        Text('Error', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
        const SizedBox(height: 8),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(_error ?? '', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.red.shade600))),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _getRecommendation, style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, foregroundColor: Colors.white),
            child: const Text('Retry')),
      ]))),
    );
  }

  // ── Result Panel ──
  Widget _buildResultPanel() {
    final r = _result!;
    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Fertilizer banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: r.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: r.color.withOpacity(0.25)),
          ),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: r.color.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(FontAwesomeIcons.boxOpen, color: r.color, size: 22)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Recommended', style: TextStyle(fontSize: 11, color: r.color, fontWeight: FontWeight.w600)),
              Text(r.fertilizer, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: r.color)),
              Text('${r.npkRatio} · ${r.fertilizerType}', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ])),
            Column(children: [
              Text(r.totalDose, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: r.color)),
              Text('per acre', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        // NPK soil status
        _sectionLabel(FontAwesomeIcons.chartBar, 'Soil Nutrient Status'),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _statusChip('N', _nCtrl.text, r.nStatus, const Color(0xFF1565C0))),
          const SizedBox(width: 8),
          Expanded(child: _statusChip('P', _pCtrl.text, r.pStatus, const Color(0xFF6A1B9A))),
          const SizedBox(width: 8),
          Expanded(child: _statusChip('K', _kCtrl.text, r.kStatus, const Color(0xFFBF360C))),
        ]),
        const SizedBox(height: 20),

        // Description
        Text(r.description, style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary, height: 1.5)),
        const SizedBox(height: 20),

        // Application Schedule
        _sectionLabel(FontAwesomeIcons.calendarDays, 'Application Schedule'),
        const SizedBox(height: 10),
        ...r.schedule.asMap().entries.map((e) => _scheduleCard(e.key + 1, e.value, r.color)),

        const SizedBox(height: 20),

        // Benefits
        _sectionLabel(FontAwesomeIcons.circleCheck, 'Benefits'),
        const SizedBox(height: 8),
        ...r.benefits.map((b) => _bulletRow(b, AppTheme.primaryColor)),
        const SizedBox(height: 16),

        // Application Method
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(FontAwesomeIcons.tractor, size: 14, color: Colors.blue.shade700),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Application Method', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700, fontSize: 12)),
              const SizedBox(height: 4),
              Text(r.applicationMethod, style: TextStyle(fontSize: 12, color: Colors.blue.shade800, height: 1.4)),
            ])),
          ]),
        ),
        const SizedBox(height: 14),

        // Precautions
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade100),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(FontAwesomeIcons.triangleExclamation, size: 13, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text('Precautions', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade700, fontSize: 12)),
            ]),
            const SizedBox(height: 6),
            ...r.precautions.map((p) => _bulletRow(p, Colors.orange.shade700)),
          ]),
        ),

        const SizedBox(height: 14),

        // Best for crops chips
        _sectionLabel(FontAwesomeIcons.seedling, 'Best For'),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6, children: r.bestFor.map((c) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: r.color.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: r.color.withOpacity(0.2))),
          child: Text(c, style: TextStyle(fontSize: 12, color: r.color, fontWeight: FontWeight.w500)),
        )).toList()),
      ]),
    );
  }

  Widget _sectionLabel(IconData icon, String label) => Row(children: [
    FaIcon(icon, size: 13, color: AppTheme.primaryColor),
    const SizedBox(width: 8),
    Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
  ]);

  Widget _statusChip(String sym, String val, String status, Color color) {
    final statusColor = status == 'Deficient' ? Colors.red : status == 'Excess' ? Colors.orange : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.15))),
      child: Column(children: [
        Text(sym, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
        Text(val.isEmpty ? '-' : val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
        Container(margin: const EdgeInsets.only(top: 3), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Text(status, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600))),
      ]),
    );
  }

  Widget _scheduleCard(int idx, String text, Color color) {
    final parts = text.split(': ');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 4, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(width: 26, height: 26, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(7)),
            child: Center(child: Text('$idx', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (parts.length > 1) ...[
            Text(parts[0], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimary)),
            Text(parts.sublist(1).join(': '), style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ] else
            Text(text, style: TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
        ])),
      ]),
    );
  }

  Widget _bulletRow(String text, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(margin: const EdgeInsets.only(top: 6), width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4))),
    ]),
  );
}
