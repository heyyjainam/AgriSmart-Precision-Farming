import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:agrismart/core/theme.dart';
import 'package:agrismart/core/history_service.dart';
import 'package:agrismart/presentation/widgets/glass_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryEntry> _allEntries = [];
  List<HistoryEntry> _filtered = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Crop Prediction', 'Fertilizer Suggest', 'Disease Detection'];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final entries = await HistoryService().loadHistory();
    setState(() {
      _allEntries = entries;
      _applyFilter(_selectedFilter);
      _isLoading = false;
    });
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      _filtered = filter == 'All'
          ? List.from(_allEntries)
          : _allEntries.where((e) => e.type == filter).toList();
    });
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to delete all history records? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await HistoryService().clearHistory();
      await _loadHistory();
    }
  }

  // ── Icon per type ──
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

  Color _statusColor(String status) {
    return switch (status) {
      'Success' => Colors.green,
      'Healthy' => Colors.green,
      'Warning' => Colors.orange,
      'Detected'=> Colors.red,
      _         => Colors.grey,
    };
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
                gradient: LinearGradient(colors: [AppTheme.primaryColor, AppTheme.secondaryColor]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(FontAwesomeIcons.clockRotateLeft, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Prediction History', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              Text('Your past analyses saved locally on this device', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            ]),
            const Spacer(),
            // Refresh
            IconButton(
              tooltip: 'Refresh',
              icon: Icon(Icons.refresh, color: AppTheme.primaryColor),
              onPressed: _loadHistory,
            ),
            const SizedBox(width: 4),
            // Clear all
            if (_allEntries.isNotEmpty)
              TextButton.icon(
                onPressed: _clearHistory,
                icon: Icon(FontAwesomeIcons.trash, size: 13, color: Colors.red.shade400),
                label: Text('Clear All', style: TextStyle(color: Colors.red.shade400, fontSize: 13)),
              ),
          ]),
          const SizedBox(height: 24),

          // Summary stats row
          if (_allEntries.isNotEmpty) _buildStatsRow(),
          if (_allEntries.isNotEmpty) const SizedBox(height: 20),

          GlassCard(
            child: Column(children: [
              // Filter chips
              _buildFilterBar(),
              const SizedBox(height: 20),

              // Content
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_filtered.isEmpty)
                _buildEmptyState()
              else
                _buildTable(),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final cropCount = _allEntries.where((e) => e.type == 'Crop Prediction').length;
    final fertCount  = _allEntries.where((e) => e.type == 'Fertilizer Suggest').length;
    final diseCount  = _allEntries.where((e) => e.type == 'Disease Detection').length;

    return Row(children: [
      _statCard('Total Scans', '${_allEntries.length}', FontAwesomeIcons.clipboardList, AppTheme.primaryColor),
      const SizedBox(width: 16),
      _statCard('Crop Checks', '$cropCount', FontAwesomeIcons.wheatAwn, AppTheme.primaryColor),
      const SizedBox(width: 16),
      _statCard('Fertilizers', '$fertCount', FontAwesomeIcons.flask, const Color(0xFFE65100)),
      const SizedBox(width: 16),
      _statCard('Disease Scans', '$diseCount', FontAwesomeIcons.bug, Colors.purple),
    ]);
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: FaIcon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ]),
        ]),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Row(children: [
      const FaIcon(FontAwesomeIcons.filter, size: 13, color: AppTheme.textSecondary),
      const SizedBox(width: 10),
      const Text('Filter:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textSecondary)),
      const SizedBox(width: 12),
      Expanded(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _filters.map((f) {
              final selected = _selectedFilter == f;
              final color = f == 'All' ? AppTheme.primaryColor
                  : f == 'Crop Prediction' ? AppTheme.primaryColor
                  : f == 'Fertilizer Suggest' ? const Color(0xFFE65100)
                  : Colors.purple;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _applyFilter(f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? color : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? color : Colors.grey.shade300),
                    ),
                    child: Text(f, style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      color: selected ? Colors.white : AppTheme.textSecondary,
                    )),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      // Count badge
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('${_filtered.length} records', style: TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
      ),
    ]);
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(FontAwesomeIcons.clockRotateLeft, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            _selectedFilter == 'All' ? 'No history yet' : 'No $_selectedFilter records',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'All'
                ? 'Use Crop, Fertilizer or Disease pages\nto see results appear here automatically.'
                : 'Switch filter to "All" to see all records.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ]),
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: [
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: const [
            Expanded(flex: 2, child: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            Expanded(flex: 2, child: Text('Analysis Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            Expanded(flex: 2, child: Text('Result', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            Expanded(flex: 3, child: Text('Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            Expanded(flex: 1, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          ]),
        ),

        // Table rows
        ...List.generate(_filtered.length, (i) {
          final e = _filtered[i];
          final color = _colorFor(e.type);
          final statusColor = _statusColor(e.status);
          final isLast = i == _filtered.length - 1;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: i.isEven ? Colors.white : const Color(0xFFFAFDFA),
              borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(16)) : BorderRadius.zero,
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Date
              Expanded(flex: 2, child: Text(e.formattedDate, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary))),

              // Type
              Expanded(flex: 2, child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: FaIcon(_iconFor(e.type), size: 12, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(e.type, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary))),
              ])),

              // Result
              Expanded(flex: 2, child: Text(e.result, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color))),

              // Detail
              Expanded(flex: 3, child: Text(e.detail, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.4))),

              // Status badge
              Expanded(flex: 1, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.25)),
                ),
                child: Text(e.status,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
              )),
            ]),
          );
        }),
      ]),
    );
  }
}
