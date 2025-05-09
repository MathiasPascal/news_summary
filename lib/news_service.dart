import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NewsService {
  final String newsApiKey = dotenv.env['NEWSAPI_KEY'] ?? "901acd16c39d4ef8a82cc6b62a9c8ad5";
  final String aiApiKey = dotenv.env['COHERE_API_KEY'] ?? "g9BcdGxiNPZs2y2Vee17QrS08VrPTpLcgRIWBw0V";

  /// Fetches news articles from the News API
  Future<List<Map<String, String>>> fetchNews() async {
    final url = "https://newsapi.org/v2/top-headlines?country=us&apiKey=$newsApiKey";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List articles = data['articles'] ?? [];

        return articles.map((article) {
          return {
            'title': (article['title'] ?? "No Title").toString(),
            'content': (article['description'] ?? "No Content Available").toString(),
          };
        }).toList();
      } else {
        throw Exception("Failed to load news: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error fetching news: $e");
    }
  }

  /// Sends an article to AI API for summarization
  Future<String> summarizeNews(String title, String content) async {
    final url = "https://api.cohere.ai/v1/summarize";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $aiApiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "text": "$title: $content",
          "length": "medium",
          "format": "paragraph",
          "extractiveness": "low",
        }),
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["summary"] ?? "No summary available";
      } else {
        throw Exception("Failed to summarize article: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error summarizing article: $e");
    }
  }
}
