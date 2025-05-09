import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'news_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const NewsApp());
}

class NewsApp extends StatelessWidget {
  const NewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NewsScreen(),
    );
  }
}

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final NewsService newsService = NewsService();
  List<Map<String, String>> newsArticles = [];
  String? selectedArticleTitle;
  String? selectedArticleContent;
  String? summary;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  /// Fetch news articles
  Future<void> fetchNews() async {
    try {
      final articles = await newsService.fetchNews();
      setState(() {
        newsArticles = articles;
      });
    } catch (e) {
      showError("Error loading news: $e");
    }
  }

  /// Summarize a selected article
  Future<void> summarizeArticle(String title, String content) async {
    if (content.length < 250) {
      showError("Article too short to summarize.");
      setState(() {
        summary = "This article is too short to summarize meaningfully.";
      });
      return;
    }

    setState(() {
      isLoading = true;
      summary = null;
    });

    try {
      final summarizedText = await newsService.summarizeNews(title, content);
      setState(() {
        summary = summarizedText;
      });
    } catch (e) {
      showError("Error summarizing article: $e");
      setState(() {
        summary = "Unable to generate summary.";
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  /// Show error messages
  void showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI News Summarizer")),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // News List
            Expanded(
              child: newsArticles.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: newsArticles.length,
                      itemBuilder: (context, index) {
                        final article = newsArticles[index];
                        return ListTile(
                          title: Text(
                            article['title']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            article['content']!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            setState(() {
                              selectedArticleTitle = article['title'];
                              selectedArticleContent = article['content'];
                            });
                            summarizeArticle(
                              article['title']!,
                              article['content']!,
                            );
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),

            // Summary Display
            if (selectedArticleTitle != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Summary for: $selectedArticleTitle",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Text(
                          summary ?? "Tap an article to summarize it",
                          textAlign: TextAlign.center,
                        ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
