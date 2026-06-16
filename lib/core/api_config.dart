import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _baseUrlKey = 'api_base_url';
  static const String _defaultUrl = 'http://127.0.0.1:8000';

  static String _currentUrl = _defaultUrl;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUrl = prefs.getString(_baseUrlKey) ?? _defaultUrl;
    } catch (_) {
      _currentUrl = _defaultUrl;
    }
  }

  static String get baseUrl => _currentUrl;

  static Future<void> setBaseUrl(String url) async {
    String formattedUrl = url.trim();
    if (formattedUrl.endsWith('/')) {
      formattedUrl = formattedUrl.substring(0, formattedUrl.length - 1);
    }
    
    if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
      formattedUrl = 'http://$formattedUrl';
    }

    _currentUrl = formattedUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, _currentUrl);
  }
}
