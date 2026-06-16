import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:agrismart/presentation/widgets/glass_card.dart';
import 'package:agrismart/core/theme.dart';
import 'package:agrismart/core/api_config.dart';

class MandiRatesScreen extends StatefulWidget {
  const MandiRatesScreen({super.key});

  @override
  State<MandiRatesScreen> createState() => _MandiRatesScreenState();
}

class _MandiRatesScreenState extends State<MandiRatesScreen> {
  List<dynamic> _mandiData = [];
  List<dynamic> _filteredData = [];
  bool _isLoading = true;
  String _errorMessage = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMandiRates();
  }

  Future<void> _fetchMandiRates() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      // Updated to simplified endpoint /mandi
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/mandi'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _mandiData = data['data'];
          _filteredData = List.from(_mandiData);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Failed to load rates: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Connection error. Make sure backend is running.";
        _isLoading = false;
      });
    }
  }

  void _filterData(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredData = List.from(_mandiData);
      } else {
        _filteredData = _mandiData.where((item) {
          final commodity = item['commodity'].toString().toLowerCase();
          final state = item['state'].toString().toLowerCase();
          final mandi = item['mandi'].toString().toLowerCase();
          return commodity.contains(query.toLowerCase()) || 
                 state.contains(query.toLowerCase()) ||
                 mandi.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildSearchBar()),
          _isLoading 
            ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Colors.green)))
            : _errorMessage.isNotEmpty
              ? SliverFillRemaining(child: _buildErrorWidget())
              : _filteredData.isEmpty
                ? const SliverFillRemaining(child: Center(child: Text("No rates found for your search")))
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildMandiCard(_filteredData[index]),
                        childCount: _filteredData.length,
                      ),
                    ),
                  ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.green.shade700,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          "Live Mandi Rates",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.green.shade800, Colors.green.shade500],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _fetchMandiRates,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterData,
        decoration: InputDecoration(
          hintText: "Search crop, state or market...",
          prefixIcon: const Icon(Icons.search, color: Colors.green),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          suffixIcon: _searchController.text.isNotEmpty 
            ? IconButton(
                icon: const Icon(Icons.clear), 
                onPressed: () {
                  _searchController.clear();
                  _filterData("");
                })
            : null,
        ),
      ),
    );
  }

  Widget _buildMandiCard(dynamic item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.agriculture, color: AppTheme.primaryColor, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['commodity'],
                          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              "${item['mandi']}, ${item['state']}",
                              style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "₹${item['modal_price']}",
                        style: GoogleFonts.outfit(
                          fontSize: 22, 
                          fontWeight: FontWeight.bold, 
                          color: AppTheme.primaryColor
                        ),
                      ),
                      Text(
                        "per quintal",
                        style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              width: double.infinity,
              color: AppTheme.primaryColor.withOpacity(0.1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPriceDetail("Min", "₹${item['min_price']}", Colors.orange.shade700),
                  _buildPriceDetail("Max", "₹${item['max_price']}", Colors.red.shade700),
                  _buildPriceDetail("Date", item['arrival_date'], Colors.blue.shade700),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDetail(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
        Text(
          value, 
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: color)
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(_errorMessage, style: GoogleFonts.outfit(fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchMandiRates,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Retry Connection"),
          ),
        ],
      ),
    );
  }
}
