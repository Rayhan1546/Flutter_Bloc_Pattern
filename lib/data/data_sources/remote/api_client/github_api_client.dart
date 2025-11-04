import 'package:junie_ai_test/data/data_sources/remote/api_client/api_client.dart';

/// GitHub API Client implementation
/// Provides base URL and default headers for GitHub API
class GithubApiClient extends ApiClient {
  GithubApiClient(super.dio);

  @override
  String get baseUrl => 'https://api.github.com';

  @override
  Future<Map<String, String>> defaultHeader() async {
    return {
      'Accept': 'application/vnd.github.v3+json',
      'Content-Type': 'application/json',
    };
  }
}
