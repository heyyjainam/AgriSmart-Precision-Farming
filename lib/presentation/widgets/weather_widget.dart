import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:agrismart/core/theme.dart';
import 'package:agrismart/presentation/widgets/glass_card.dart';

class DynamicWeatherWidget extends StatefulWidget {
  const DynamicWeatherWidget({super.key});

  @override
  State<DynamicWeatherWidget> createState() => _DynamicWeatherWidgetState();
}

class _DynamicWeatherWidgetState extends State<DynamicWeatherWidget> {
  bool isLoading = true;
  String temperature = '--';
  String condition = 'Loading...';
  String humidity = '--';
  String rainfall = '--';
  String windSpeed = '--';
  IconData weatherIcon = FontAwesomeIcons.cloud;
  Color weatherColor = Colors.grey;
  bool isAlert = false;
  String alertMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    try {
      double lat = 28.6139; // Default to Delhi
      double lon = 77.2090;

      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          
          if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
            Position position = await Geolocator.getCurrentPosition(
              timeLimit: const Duration(seconds: 3),
            );
            lat = position.latitude;
            lon = position.longitude;
          }
        }
      } catch (e) {
        print("Location fetch failed, using default location: $e");
      }
      
      // Fetch weather from open-meteo using resolved coordinates
      final url = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,precipitation,weather_code,wind_speed_10m&timezone=auto');
          
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current'];
        
        final temp = current['temperature_2m'];
        final hum = current['relative_humidity_2m'];
        final precip = current['precipitation'];
        final wind = current['wind_speed_10m'];
        final code = current['weather_code'];
        
        setState(() {
          temperature = '${temp.round()}°C';
          humidity = '$hum%';
          rainfall = '${precip}mm';
          windSpeed = '${wind} km/h';
          _setWeatherCondition(code);
          isLoading = false;
        });
      } else {
        setState(() {
          condition = 'Error Fetching API';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        condition = 'Error: $e';
        isLoading = false;
      });
    }
  }

  void _setWeatherCondition(int code) {
    // WMO Weather interpretation codes
    if (code == 0) {
      condition = 'Clear sky';
      weatherIcon = FontAwesomeIcons.sun;
      weatherColor = Colors.orange;
    } else if (code >= 1 && code <= 3) {
      condition = 'Partly cloudy';
      weatherIcon = FontAwesomeIcons.cloudSun;
      weatherColor = Colors.lightBlue;
    } else if (code == 45 || code == 48) {
      condition = 'Fog';
      weatherIcon = FontAwesomeIcons.smog;
      weatherColor = Colors.grey;
    } else if (code >= 51 && code <= 57) {
      condition = 'Drizzle';
      weatherIcon = FontAwesomeIcons.cloudRain;
      weatherColor = Colors.blue;
    } else if (code >= 61 && code <= 67 || code >= 80 && code <= 82) {
      condition = 'Rain';
      weatherIcon = FontAwesomeIcons.cloudShowersHeavy;
      weatherColor = Colors.blueAccent;
      isAlert = true;
      alertMessage = 'Heavy rain expected, protect crops!';
    } else if (code >= 71 && code <= 77 || code >= 85 && code <= 86) {
      condition = 'Snow';
      weatherIcon = FontAwesomeIcons.snowflake;
      weatherColor = Colors.lightBlueAccent;
    } else if (code >= 95 && code <= 99) {
      condition = 'Thunderstorm';
      weatherIcon = FontAwesomeIcons.bolt;
      weatherColor = Colors.deepPurple;
      isAlert = true;
      alertMessage = 'Thunderstorm warning, secure farm equipment!';
    } else {
      condition = 'Unknown';
      weatherIcon = FontAwesomeIcons.cloud;
      weatherColor = Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Local Weather',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: Icon(Icons.refresh, size: 20, color: AppTheme.textSecondary),
                  onPressed: () {
                    setState(() {
                      isLoading = true;
                      isAlert = false;
                    });
                    _fetchWeather();
                  },
                ),
            ],
          ),
          if (isAlert)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                border: Border.all(color: Colors.red.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      alertMessage,
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    temperature,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    condition,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Icon(
                weatherIcon,
                size: 64,
                color: weatherColor,
              ),
            ],
          ),
          SizedBox(height: 32),
          _buildWeatherRow('Humidity', humidity, FontAwesomeIcons.droplet, Colors.blue),
          SizedBox(height: 16),
          _buildWeatherRow('Rainfall', rainfall, FontAwesomeIcons.cloudRain, Colors.lightBlue),
          SizedBox(height: 16),
          _buildWeatherRow('Wind', windSpeed, FontAwesomeIcons.wind, Colors.grey),
        ],
      ),
    );
  }

  Widget _buildWeatherRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        SizedBox(width: 16),
        Text(
          label,
          style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
      ],
    );
  }
}
