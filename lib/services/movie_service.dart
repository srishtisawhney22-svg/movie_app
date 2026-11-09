import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/movie.dart';

class MovieService {
  static const String baseUrl = 'https://api.themoviedb.org/3';

  final String apiKey = dotenv.env['TMDB_API_KEY'] ?? '';

  Future<List<Movie>> fetchTrendingMovies({int page = 1}) async {
    if (apiKey.isEmpty) {
      throw Exception('API key is missing');
    }

    final url = Uri.parse(
      '$baseUrl/trending/movie/week?api_key=$apiKey&page=$page',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List results = data['results'];
      return results.map((item) => Movie.fromJson(item)).toList();
    }

    throw Exception('Failed to load movies: ${response.statusCode}');
  }

  Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    final url = Uri.parse(
      '$baseUrl/search/movie?api_key=$apiKey&query=${Uri.encodeQueryComponent(query)}&page=$page',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List results = data['results'];

      return results.map((item) => Movie.fromJson(item)).toList();
    }

    throw Exception('Search failed: ${response.statusCode}');
  }
}