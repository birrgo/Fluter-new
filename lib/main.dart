import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'menu_screen.dart';
// Note: Imports for new screens would go here, e.g.,
// import 'online_jobs_screen.dart';
// import 'tech_hub_screen.dart';
// import 'social_hub_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  MobileAds.instance.initialize();
  runApp(const FikraProApp());
}

class FikraProApp extends StatelessWidget {
  const FikraProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fikra Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F2C59)),
        scaffoldBackgroundColor: const Color(0xFFFAFBFC),
        fontFamily: 'Plus Jakarta Sans',
      ),
      home: const SplashScreen(),
    );
  }
}

// --- SPLASH / WELCOME SCREEN WITH s1.png ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Transition to HomeScreen after initial splash display delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF081B38),
      body: SizedBox.expand(
        child: Image.asset(
          'assets/images/s1.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// --- PLACEHOLDER SCREENS ---
class OnlineJobsScreen extends StatelessWidget {
  const OnlineJobsScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text("Online Jobs Screen"));
}

class TechHubScreen extends StatelessWidget {
  const TechHubScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text("Tech Hub Screen"));
}

class SocialHubScreen extends StatelessWidget {
  const SocialHubScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text("Social Hub Screen"));
}

// --- PARENT HOME SCREEN WITH NAVIGATION ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  static const String appNodeName = "app14";

  int _currentIndex = 0; // State for BottomNavigationBar

  // AdMob config objects
  Map<dynamic, dynamic> _adConfig = {};
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  AppOpenAd? _appOpenAd;
  bool _isInitialAdLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAdConfigAndInit();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bannerAd?.dispose();
    _appOpenAd?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _showResumeAppOpenAd();
    }
  }

  // --- ADMOB CONFIGURATION ---
  void _loadAdConfigAndInit() {
    _dbRef.child('$appNodeName/adManager').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          _adConfig = data;
        });
        
        final bool adsEnabled = (_adConfig['adStatus'] ?? '').toString().toUpperCase() == 'TRUE' || 
                                (_adConfig['adStatus'] ?? '').toString().toUpperCase() == 'ON';
        
        if (adsEnabled) {
          _loadInitialAppOpenAd();
          _initBannerAd();
        }
      }
    });
  }

  void _loadInitialAppOpenAd() {
    final String? appOpenId = _adConfig['adMobAppOpenUnitId'];
    if (appOpenId == null) return;

    AppOpenAd.load(
      adUnitId: appOpenId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          if (!_isInitialAdLoaded) {
            _isInitialAdLoaded = true;
            _appOpenAd?.show();
          }
        },
        onAdFailedToLoad: (error) {},
      ),
    );
  }

  void _showResumeAppOpenAd() {
    final bool adsEnabled = (_adConfig['adStatus'] ?? '').toString().toUpperCase() == 'TRUE';
    final bool resumePlacement = _adConfig['placements']?['appOpenAdResume'] == true;
    final String? appOpenId = _adConfig['adMobAppOpenUnitId'];

    if (!adsEnabled || !resumePlacement || appOpenId == null) return;

    AppOpenAd.load(
      adUnitId: appOpenId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          ad.show();
        },
        onAdFailedToLoad: (error) {},
      ),
    );
  }

  void _initBannerAd() {
    final bool showBanner = _adConfig['placements']?['bannerAdHomePage'] == true;
    final String? bannerId = _adConfig['adMobBannerUnitId'];

    if (!showBanner || bannerId == null) return;

    _bannerAd = BannerAd(
      adUnitId: bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBannerLoaded = true),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();
  }

  // --- UI BUILDER ---
  @override
  Widget build(BuildContext context) {
    // List of screens to display, order must match BottomNavigationBarItems
    final List<Widget> _screens = [
      FikraProNewsList(adConfig: _adConfig), // The original content widget
      const OnlineJobsScreen(),
      const TechHubScreen(),
      const SocialHubScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF081B38),
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/s.png',
              width: 28,
              height: 28,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
            const SizedBox(width: 10),
            const Text(
              'Fikra Pro',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MenuScreen()),
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack( // efficient for switching screens
              index: _currentIndex,
              children: _screens,
            ),
          ),
          if (_isBannerLoaded && _bannerAd != null)
            SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              width: _bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 24), // mimic the dark-theme bar look
        color: const Color(0xFF131313), // dark theme from image
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF131313), // dark theme from image
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed, // show all items
          selectedItemColor: Colors.blue[600], // blue selected color from image
          unselectedItemColor: Colors.grey, // unselected grey from image
          selectedLabelStyle: const TextStyle(color: Colors.white), // white selected text
          unselectedLabelStyle: const TextStyle(color: Colors.grey), // unselected grey text
          showUnselectedLabels: true, // as seen in image
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view), // blocks for online/categories
              label: 'Online',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.engineering), // chip/cog for tech/bookmarks style from image but label is tech
              label: 'Tech',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group), // group for social/profile from image but label is social
              label: 'Social',
            ),
          ],
        ),
      ),
    );
  }
}

// --- ENCAPSULATED NEWS LIST WIDGET ---
class FikraProNewsList extends StatefulWidget {
  final Map<dynamic, dynamic> adConfig;
  const FikraProNewsList({super.key, required this.adConfig});

  @override
  State<FikraProNewsList> createState() => _FikraProNewsListState();
}

class _FikraProNewsListState extends State<FikraProNewsList> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  static const String appNodeName = "app14";

  List<Map<dynamic, dynamic>> _broadcasts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDatabaseNews();
  }

  // --- FIREBASE NEWS STREAMING ---
  void _fetchDatabaseNews() {
    List<Map<dynamic, dynamic>> tempList = [];

    void processNode(Object? data, String defaultCat) {
      if (data is Map) {
        data.forEach((key, value) {
          if (value is Map) {
            final item = Map<dynamic, dynamic>.from(value);
            item['id'] = key;
            item['category'] = (item['category'] ?? defaultCat).toString().replaceAll(RegExp('Shikela', caseSensitive: false), 'Fikra Pro');
            
            // Extract Timestamp safely
            var rawTime = item['timestamp'] ?? item['updatedAt'] ?? item['createdAtTimestamp'] ?? DateTime.now().millisecondsSinceEpoch;
            if (rawTime is String) rawTime = int.tryParse(rawTime) ?? DateTime.now().millisecondsSinceEpoch;
            item['resolvedTimestamp'] = rawTime;

            tempList.add(item);
          }
        });
      }
    }

    _dbRef.child('$appNodeName/shikelaNews').onValue.listen((event) {
      processNode(event.snapshot.value, 'Fikra Pro Update');
      _sortAndSaveList(tempList);
    });

    _dbRef.child('$appNodeName/newNews').onValue.listen((event) {
      processNode(event.snapshot.value, 'Fikra Pro Tips');
      _sortAndSaveList(tempList);
    });
  }

  void _sortAndSaveList(List<Map<dynamic, dynamic>> list) {
    list.sort((a, b) => b['resolvedTimestamp'].compareTo(a['resolvedTimestamp']));
    if (mounted) {
      setState(() {
        _broadcasts = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _broadcasts.isEmpty
            ? const Center(child: Text("No updates posted today."))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _broadcasts.length,
                itemBuilder: (context, index) {
                  final item = _broadcasts[index];
                  return NewsCard(item: item, adConfig: widget.adConfig);
                },
              );
  }
}

// --- NEWS CARD WIDGET ---
class NewsCard extends StatelessWidget {
  final Map<dynamic, dynamic> item;
  final Map<dynamic, dynamic> adConfig;

  const NewsCard({super.key, required this.item, required this.adConfig});

  void _handleCardTap(BuildContext context) {
    final bool adsEnabled = (adConfig['adStatus'] ?? '').toString().toUpperCase() == 'TRUE';
    final bool interstitialPlacement = adConfig['placements']?['interstitialAdPostDetails'] == true;
    final String? interstitialId = adConfig['adMobInterstitialUnitId'];

    if (adsEnabled && interstitialPlacement && interstitialId != null) {
      InterstitialAd.load(
        adUnitId: interstitialId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            ad.show();
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) => _navigateToDetails(context),
            );
          },
          onAdFailedToLoad: (error) => _navigateToDetails(context),
        ),
      );
    } else {
      _navigateToDetails(context);
    }
  }

  void _navigateToDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ArticleDetailsScreen(item: item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = item['title'] ?? item['newsTitle'] ?? 'Fikra Pro Update';
    final content = item['content'] ?? item['message'] ?? '';
    final preview = content.length > 120 ? '${content.substring(0, 120)}...' : content;
    final category = item['category'] ?? 'Fikra Pro Update';
    final imageUrl = item['imageUrl'] ?? item['image'] ?? '';
    
    final dateTime = DateTime.fromMillisecondsSinceEpoch(item['resolvedTimestamp']);
    final formattedTime = DateFormat('MMM d, yyyy • h:mm:ss a').format(dateTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: InkWell(
        onTap: () => _handleCardTap(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F2C59).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(category, style: const TextStyle(color: Color(0xFF0F2C59), fontSize: 9.5, fontWeight: FontWeight.w800)),
                ),
                Text(formattedTime, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
              ],
            ),
            if (imageUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(height: 180, color: Colors.grey[200]),
                  errorWidget: (context, url, error) => const SizedBox.shrink(),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), height: 1.35)),
            const SizedBox(height: 6),
            Text(preview, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: Color(0xFF475569), height: 1.55)),
          ],
        ),
      ),
    );
  }
}

// --- ARTICLE DETAILS PAGE ---
class ArticleDetailsScreen extends StatelessWidget {
  final Map<dynamic, dynamic> item;
  const ArticleDetailsScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final title = item['title'] ?? item['newsTitle'] ?? 'Details';
    final content = item['content'] ?? item['message'] ?? '';
    final imageUrl = item['imageUrl'] ?? item['image'] ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(title, style: const TextStyle(fontSize: 14))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
            ],
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(content, style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF334155))),
          ],
        ),
      ),
    );
  }
}
