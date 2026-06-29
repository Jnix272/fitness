import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'http://127.0.0.1:8000';

  Future<void> logSession(Map<String, dynamic> sessionData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sessions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(sessionData),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to log session: ${response.body}');
    }
  }

  Future<List<dynamic>> getWeeklyAnalytics() async {
    final response = await http.get(Uri.parse('$baseUrl/analytics/weekly'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load analytics: ${response.body}');
    }
  }

  Future<List<dynamic>> getTemplates() async {
    final response = await http.get(Uri.parse('$baseUrl/templates'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load templates: ${response.body}');
    }
  }

  Future<List<dynamic>> getExercises({String? template}) async {
    final uri = template == null
        ? Uri.parse('$baseUrl/exercises')
        : Uri.parse('$baseUrl/exercises?template=$template');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load exercises: ${response.body}');
    }
  }

  Future<List<dynamic>> getProtocols(String template) async {
    final response = await http.get(
      Uri.parse('$baseUrl/protocols?template=$template'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load protocols: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getNextSuggestions() async {
    final response = await http.get(Uri.parse('$baseUrl/suggestions/next'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load suggestions: ${response.body}');
    }
  }

  Future<String> explainSuggestion(String suggestion) async {
    final response = await http.post(
      Uri.parse('$baseUrl/coach/explain'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'suggestion': suggestion}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['explanation'];
    } else {
      return "Failed to get explanation.";
    }
  }

  Future<String> chatCoach(String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/coach/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': message}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['reply'];
    } else {
      return "Failed to get reply.";
    }
  }
}
