import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

void main() {
  runApp(const WitAnimeApp());
}

// ==========================================
// 1. MODELS (نماذج البيانات)
// ==========================================
class EpisodeModel {
  final String title;
  final String episodeNumber;
  final String imageUrl;
  final String episodeUrl;

  EpisodeModel({
    required this.title,
    required this.episodeNumber,
    required this.imageUrl,
    required this.episodeUrl,
  });
}

class ServerModel {
  final String serverName;
  final String iframeUrl;

  ServerModel({
    required this.serverName,
    required this.iframeUrl,
  });
}

// ==========================================
// 2. SCRAPING SERVICE (خدمة جلب البيانات)
// ==========================================
class WitAnimeService {
  static const String baseUrl = 'https://witanime.site';

  static const Map<String, String> headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  };

  /// جلب أحدث الحلقات من الصفحة الرئيسية
  Future<List<EpisodeModel>> fetchLatestEpisodes() async {
    List<EpisodeModel> episodes = [];
    try {
      final response = await http.get(Uri.parse(baseUrl), headers: headers);

      if (response.statusCode == 200) {
        var document = parser.parse(response.body);
        var episodeElements = document.querySelectorAll('.episodes-card-container, .anime-card-container');

        for (var element in episodeElements) {
          var titleElement = element.querySelector('.episodes-card-title a, .anime-card-title a');
          String title = titleElement?.text.trim() ?? 'أنمي غير معروف';
          String episodeUrl = titleElement?.attributes['href'] ?? '';

          var imgElement = element.querySelector('img');
          String imageUrl = imgElement?.attributes['src'] ?? imgElement?.attributes['data-src'] ?? '';

          var epNumElement = element.querySelector('.episode-number, .anime-card-status');
          String epNum = epNumElement?.text.trim() ?? 'حلقة جديدة';

          if (episodeUrl.isNotEmpty) {
            episodes.add(EpisodeModel(
              title: title,
              episodeNumber: epNum,
              imageUrl: imageUrl,
              episodeUrl: episodeUrl,
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('خطأ أثناء جلب البيانات: $e');
    }
    return episodes;
  }

  /// جلب سيرفرات المشاهدة الخاصة بحلقة محددة
  Future<List<ServerModel>> fetchEpisodeServers(String episodeUrl) async {
    List<ServerModel> servers = [];
    try {
      final response = await http.get(Uri.parse(episodeUrl), headers: headers);

      if (response.statusCode == 200) {
        var document = parser.parse(response.body);
        var serverElements = document.querySelectorAll('#episode-servers li a, .episode-watch-single-page iframe');

        for (var element in serverElements) {
          String name = element.text.trim();
          String url = element.attributes['data-ep-url'] ?? element.attributes['src'] ?? '';

          if (url.isNotEmpty) {
            servers.add(ServerModel(
              serverName: name.isEmpty ? 'سيرفر مشاهدة' : name,
              iframeUrl: url,
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('خطأ أثناء جلب السيرفرات: $e');
    }
    return servers;
  }
}

// ==========================================
// 3. MAIN APP & NETFLIX THEME
// ==========================================
class WitAnimeApp extends StatelessWidget {
  const WitAnimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WitAnime Stream',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF141414), // أسود نتفلكس
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// ==========================================
// 4. HOME SCREEN (الفيلم والرئيسية)
// ==========================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WitAnimeService _animeService = WitAnimeService();
  late Future<List<EpisodeModel>> _latestEpisodesFuture;

  @override
  void initState() {
    super.initState();
    _latestEpisodesFuture = _animeService.fetchLatestEpisodes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar علوي شفاف
          SliverAppBar(
            floating: true,
            pinned: false,
            backgroundColor: const Color(0xFF141414).withValues(alpha: 0.9),
            title: const Text(
              'WITANIME',
              style: TextStyle(
                color: Color(0xFFE50914), // أحمر نتفلكس الشهير
                fontWeight: FontWeight.w900,
                fontSize: 26,
                letterSpacing: 1.2,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _latestEpisodesFuture = _animeService.fetchLatestEpisodes();
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),

          // البنر الرئيسي (Hero Banner)
          SliverToBoxAdapter(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  height: 400,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage('https://witanime.site/wp-content/uploads/2023/10/Solo-Leveling-Poster.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // تدرج أسود لتوضيح النصوص والأزرار
                Container(
                  height: 400,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                        const Color(0xFF141414),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // أزرار التفاعل بالأسفل
                Positioned(
                  bottom: 10,
                  child: Column(
                    children: [
                      const Text(
                        'أنمي الأسبوع الأكثر مشاهدة 🔥',
                        style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            onPressed: () {},
                            icon: const Icon(Icons.play_arrow, size: 28),
                            label: const Text('مشاهدة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white, width: 1.5),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            onPressed: () {},
                            icon: const Icon(Icons.add, size: 24),
                            label: const Text('قائمتي', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // قسم "جديد الحلقات" (الحية)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'جديد الحلقات المضافة حديثاً 🔥',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<EpisodeModel>>(
                    future: _latestEpisodesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 200,
                          child: Center(child: CircularProgressIndicator(color: Color(0xFFE50914))),
                        );
                      } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                        return Container(
                          height: 150,
                          alignment: Alignment.center,
                          child: const Text('تعذر جلب الحلقات. تأكد من الاتصال بالإنترنت.',
                              style: TextStyle(color: Colors.white54)),
                        );
                      }

                      final episodes = snapshot.data!;

                      return SizedBox(
                        height: 220,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: episodes.length,
                          itemBuilder: (context, index) {
                            final item = episodes[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EpisodeDetailScreen(episode: item),
                                  ),
                                );
                              },
                              child: Container(
                                width: 135,
                                margin: const EdgeInsets.only(right: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Stack(
                                          children: [
                                            Image.network(
                                              item.imageUrl,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                color: Colors.grey[900],
                                                child: const Icon(Icons.movie, color: Colors.white24),
                                              ),
                                            ),
                                            Positioned(
                                              top: 6,
                                              left: 6,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE50914),
                                                  borderRadius: BorderRadius.circular(3),
                                                ),
                                                child: Text(
                                                  item.episodeNumber,
                                                  style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 5. EPISODE DETAIL & SERVERS SCREEN
// ==========================================
class EpisodeDetailScreen extends StatefulWidget {
  final EpisodeModel episode;

  const EpisodeDetailScreen({super.key, required this.episode});

  @override
  State<EpisodeDetailScreen> createState() => _EpisodeDetailScreenState();
}

class _EpisodeDetailScreenState extends State<EpisodeDetailScreen> {
  final WitAnimeService _animeService = WitAnimeService();
  late Future<List<ServerModel>> _serversFuture;

  @override
  void initState() {
    super.initState();
    _serversFuture = _animeService.fetchEpisodeServers(widget.episode.episodeUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.episode.title, style: const TextStyle(fontSize: 16)),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة الحلقة والمعلومات
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.episode.imageUrl,
                    width: 110,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.episode.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE50914),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.episode.episodeNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'سيرفرات المشاهدة المتاحة:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),

            // قائمة السيرفرات المسحوبة من الموقع
            Expanded(
              child: FutureBuilder<List<ServerModel>>(
                future: _serversFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)));
                  } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('جاري تجهيز السيرفرات أو فتحها بالموقع المباشر.',
                          style: TextStyle(color: Colors.white54)),
                    );
                  }

                  final servers = snapshot.data!;

                  return ListView.builder(
                    itemCount: servers.length,
                    itemBuilder: (context, index) {
                      final server = servers[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          tileColor: const Color(0xFF222222),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          leading: const Icon(Icons.play_circle_fill, color: Color(0xFFE50914)),
                          title: Text(server.serverName, style: const TextStyle(color: Colors.white)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم اختيار: ${server.serverName}')),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}