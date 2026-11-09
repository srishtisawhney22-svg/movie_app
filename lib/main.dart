import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'models/movie.dart';
import 'services/movie_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  runApp(const MovieApp());
}

class MovieApp extends StatelessWidget {
  const MovieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Movie App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MovieService movieService = MovieService();

  final TextEditingController searchController =
      TextEditingController();

  late Future<List<Movie>> movies;
  int currentPage = 1;
bool isLoadingMore = false;
  Set<int> favouriteIds = {};

@override
void initState() {
  super.initState();
  movies = movieService.fetchTrendingMovies();
  loadFavourites();
}

Future<void> loadFavourites() async {
  final prefs = await SharedPreferences.getInstance();

  setState(() {
    favouriteIds =
        (prefs.getStringList('favourites') ?? [])
            .map((id) => int.parse(id))
            .toSet();
  });
}

Future<void> toggleFavourite(int movieId) async {
  final prefs = await SharedPreferences.getInstance();

  setState(() {
    if (favouriteIds.contains(movieId)) {
      favouriteIds.remove(movieId);
    } else {
      favouriteIds.add(movieId);
    }
  });

  await prefs.setStringList(
    'favourites',
    favouriteIds.map((id) => id.toString()).toList(),
  );
}
  void searchMovies(String query) {
    currentPage=1;
    setState(() {
      if (query.trim().isEmpty) {
        movies = movieService.fetchTrendingMovies();
      } else {
        movies = movieService.searchMovies(query);
      }
    });
  }
  Future<void> loadMoreMovies() async {
  if (isLoadingMore) return;

  setState(() {
    isLoadingMore = true;
  });

  try {
    final oldMovies = await movies;
    final nextPage = currentPage + 1;

    final newMovies = searchController.text.trim().isEmpty
        ? await movieService.fetchTrendingMovies(page: nextPage)
        : await movieService.searchMovies(
            searchController.text.trim(),
            page: nextPage,
          );

    setState(() {
      movies = Future.value([...oldMovies, ...newMovies]);
      currentPage = nextPage;
    });
  } catch (e) {
    debugPrint('Load more error: $e');
  } finally {
    if (mounted) {
      setState(() {
        isLoadingMore = false;
      });
    }
  }
}

  void retryLoading() {
    setState(() {
      movies = movieService.fetchTrendingMovies();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
  title: const Text(
    'Movie App 🎬',
    style: TextStyle(fontWeight: FontWeight.bold),
  ),
  centerTitle: true,
  actions: [
    IconButton(
      icon: const Icon(Icons.favorite),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FavouritesScreen(
              movies: movies,
              favouriteIds: favouriteIds,
              onRemove: toggleFavourite,
            ),
          ),
        );
      },
    ),
  ],
),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Trending Movies',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: searchController,
              onSubmitted: searchMovies,
              decoration: InputDecoration(
                hintText: 'Search movies...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    searchMovies('');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: FutureBuilder<List<Movie>>(
              future: movies,
              builder: (context, snapshot) {

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Failed to load movies'),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: retryLoading,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No movies found'),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: snapshot.data!.length + 1,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),

                  itemBuilder: (context, index) {
                    final movie = snapshot.data![index];
                    if (index == snapshot.data!.length) {
  return Center(
    child: TextButton(
      onPressed: isLoadingMore ? null : loadMoreMovies,
      child: Text(
        isLoadingMore ? 'Loading...' : 'Load More Movies',
      ),
    ),
  );
}

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MovieDetailsScreen(movie: movie),
                          ),
                        );
                      },

                      child: Card(
                        elevation: 3,
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: movie.fullPosterUrl.isNotEmpty
                                  ? Image.network(
                                      movie.fullPosterUrl,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Center(
                                          child: Icon(
                                            Icons.movie,
                                            size: 50,
                                          ),
                                        );
                                      },
                                    )
                                  : const Center(
                                      child: Icon(
                                        Icons.movie,
                                        size: 50,
                                      ),
                                    ),
                            ),

                          Padding(
  padding: const EdgeInsets.all(8),
  child: Row(
    children: [
      Expanded(
        child: Text(
          movie.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: Icon(
          favouriteIds.contains(movie.id)
              ? Icons.favorite
              : Icons.favorite_border,
          color: Colors.red,
        ),
        onPressed: () {
          toggleFavourite(movie.id);
        },
      ),
    ],
  ),
),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 8,
                                bottom: 8,
                              ),
                              child: Text(
                                '⭐ ${movie.rating.toStringAsFixed(1)}',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MovieDetailsScreen extends StatelessWidget {
  final Movie movie;

  const MovieDetailsScreen({
    super.key,
    required this.movie,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie Details'),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (movie.fullPosterUrl.isNotEmpty)
              Image.network(
                movie.fullPosterUrl,
                width: double.infinity,
                height: 400,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    height: 200,
                    child: Center(
                      child: Icon(Icons.movie, size: 60),
                    ),
                  );
                },
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text('⭐ Rating: ${movie.rating.toStringAsFixed(1)}'),

                  const SizedBox(height: 8),

                  Text('Release Date: ${movie.releaseDate}'),

                  const SizedBox(height: 16),

                  const Text(
                    'Overview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    movie.overview.isEmpty
                        ? 'No overview available.'
                        : movie.overview,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class FavouritesScreen extends StatefulWidget {
  final Future<List<Movie>> movies;
  final Set<int> favouriteIds;
  final Future<void> Function(int) onRemove;

  const FavouritesScreen({
    super.key,
    required this.movies,
    required this.favouriteIds,
    required this.onRemove,
  });

  @override
  State<FavouritesScreen> createState() =>
      _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favourites ❤️'),
      ),
      body: FutureBuilder<List<Movie>>(
        future: widget.movies,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || snapshot.hasError) {
            return const Center(
              child: Text('Unable to load favourites'),
            );
          }

          final favouriteMovies = snapshot.data!
              .where((movie) =>
                  widget.favouriteIds.contains(movie.id))
              .toList();

          if (favouriteMovies.isEmpty) {
            return const Center(
              child: Text('No favourite movies added yet ❤️'),
            );
          }

          return ListView.builder(
            itemCount: favouriteMovies.length,
            itemBuilder: (context, index) {
              final movie = favouriteMovies[index];

              return ListTile(
                leading: movie.fullPosterUrl.isNotEmpty
                    ? Image.network(
                        movie.fullPosterUrl,
                        width: 55,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.movie),
                title: Text(movie.title),
                subtitle: Text(
                  '⭐ ${movie.rating.toStringAsFixed(1)}',
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.favorite,
                    color: Colors.red,
                  ),
                  onPressed: () async {
                    await widget.onRemove(movie.id);
                    setState(() {});
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MovieDetailsScreen(movie: movie),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}