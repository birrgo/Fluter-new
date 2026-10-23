import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'menu_screen.dart';
import 'online_jobs_screen.dart';
import 'tech_hub_screen.dart';
import 'social_hub_screen.dart';
import 'article_details_screen.dart';

void main() async {
  // Global catch for framework errors to prevent silent crash-stops
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint("FlutterError caught: ${details.exception}");
  };

  WidgetsFlutterBinding.ensureInitialized();
  
  // Crash-proof initializations
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  try {
    MobileAds.instance.initialize();
  } catch (e) {
    debugPrint("AdMob init error: $e");
  }

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
          errorBuilder: (context, error, stackTrace) => 
              const Center(child: Text("Fikra Pro", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }
}

// --- PARENT HOME SCREEN WITH NAVIGATION ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  DatabaseReference? _dbRef;
  static const String appNodeName = "app14";

  int _currentIndex = 0;
  Map<dynamic, dynamic> _adConfig = {};
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  AppOpenAd? _appOpenAd;
  bool _isInitialAdLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    try {
      _dbRef = FirebaseDatabase.instance.ref();
      _loadAdConfigAndInit();
    } catch (e) {
      debugPrint("Database init error: $e");
    }
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

  void _loadAdConfigAndInit() {
    if (_dbRef == null) return;
    _dbRef!.child('$appNodeName/adManager').onValue.listen((event) {
      try {
        final val = event.snapshot.value;
        if (val is Map && mounted) {
          setState(() {
            _adConfig = Map<dynamic, dynamic>.from(val);
          });
          
          final bool adsEnabled = (_adConfig['adStatus'] ?? '').toString().toUpperCase() == 'TRUE' || 
                                  (_adConfig['adStatus'] ?? '').toString().toUpperCase() == 'ON';
          
          if (adsEnabled) {
            _loadInitialAppOpenAd();
            _initBannerAd();
          }
        }
      } catch (e) {
        debugPrint("AdConfig parse error: $e");
      }
    }, onError: (e) {
      debugPrint("AdConfig stream error: $e");
    });
  }

  bool _getPlacement(String key) {
    try {
      final placements = _adConfig['placements'];
      if (placements is Map) {
        return placements[key] == true;
      }
    } catch (e) {
      debugPrint("Placement read error: $e");
    }
    return false;
  }

  void _loadInitialAppOpenAd() {
    final String? appOpenId = _adConfig['adMobAppOpenUnitId']?.toString();
    if (appOpenId == null || appOpenId.isEmpty) return;

    AppOpenAd.load(
      adUnitId: appOpenId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          if (!_isInitialAdLoaded && mounted) {
            _isInitialAdLoaded = true;
            _appOpenAd?.show();
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint("AppOpenAd load failed: $error");
        },
      ),
    );
  }

  void _showResumeAppOpenAd() {
    final bool adsEnabled = (_adConfig['adStatus'] ?? '').toString().toUpperCase() == 'TRUE';
    final bool resumePlacement = _getPlacement('appOpenAdResume');
    final String? appOpenId = _adConfig['adMobAppOpenUnitId']?.toString();

    if (!adsEnabled || !resumePlacement || appOpenId == null || appOpenId.isEmpty) return;

    AppOpenAd.load(
      adUnitId: appOpenId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) => ad.show(),
        onAdFailedToLoad: (error) {},
      ),
    );
  }

  void _initBannerAd() {
    final bool showBanner = _getPlacement('bannerAdHomePage');
    final String? bannerId = _adConfig['adMobBannerUnitId']?.toString();

    if (!showBanner || bannerId == null || bannerId.isEmpty) return;

    _bannerAd = BannerAd(
      adUnitId: bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isBannerLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint("BannerAd load failed: $error");
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      FikraProNewsList(adConfig: _adConfig),
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
            child: IndexedStack(
              index: _currentIndex,
              children: screens,
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
        padding: const EdgeInsets.only(bottom: 24),
        color: const Color(0xFF131313),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF131313),
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blue[600],
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(color: Colors.white),
          unselectedLabelStyle: const TextStyle(color: Colors.grey),
          showUnselectedLabels: true,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Online'),
            BottomNavigationBarItem(icon: Icon(Icons.engineering), label: 'Tech'),
            BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Social'),
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
  DatabaseReference? _dbRef;
  static const String appNodeName = "app14";

  List<Map<dynamic, dynamic>> _broadcasts = [];
  bool _isLoading = true;

  Map<dynamic, dynamic> _shikelaNewsCache = {};
  Map<dynamic, dynamic> _newNewsCache = {};

  @override
  void initState() {
    super.initState();
    try {
      _dbRef = FirebaseDatabase.instance.ref();
      _fetchDatabaseNews();
    } catch (e) {
      debugPrint("News init error: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _fetchDatabaseNews() {
    if (_dbRef == null) return;

    void processAndCombine() {
      List<Map<dynamic, dynamic>> tempList = [];

      void parseNode(Map<dynamic, dynamic>? data, String defaultCat) {
        if (data != null) {
          data.forEach((key, value) {
            if (value is Map) {
              try {
                final item = Map<dynamic, dynamic>.from(value);
                item['id'] = key;
                item['category'] = (item['category'] ?? defaultCat).toString().replaceAll(RegExp('Shikela', caseSensitive: false), 'Fikra Pro');
                
                var rawTime = item['timestamp'] ?? item['updatedAt'] ?? item['createdAtTimestamp'] ?? DateTime.now().millisecondsSinceEpoch;
                int resolvedTime = DateTime.now().millisecondsSinceEpoch;
                if (rawTime is int) {
                  resolvedTime = rawTime;
                } else if (rawTime is String) {
                  resolvedTime = int.tryParse(rawTime) ?? resolvedTime;
                } else if (rawTime is double) {
                  resolvedTime = rawTime.toInt();
                }
                item['resolvedTimestamp'] = resolvedTime;

                tempList.add(item);
              } catch (e) {
                debugPrint("Item parse error: $e");
              }
            }
          });
        }
      }

      parseNode(_shikelaNewsCache, 'Fikra Pro Update');
      parseNode(_newNewsCache, 'Fikra Pro Tips');

      tempList.sort((a, b) => (b['resolvedTimestamp'] as int).compareTo(a['resolvedTimestamp'] as int));
      
      if (mounted) {
        setState(() {
          _broadcasts = tempList;
          _isLoading = false;
        });
      }
    }

    _dbRef!.child('$appNodeName/shikelaNews').onValue.listen((event) {
      try {
        final val = event.snapshot.value;
        if (val is Map) {
          _shikelaNewsCache = Map<dynamic, dynamic>.from(val);
        } else {
          _shikelaNewsCache = {};
        }
        processAndCombine();
      } catch (e) {
        debugPrint("shikelaNews stream error: $e");
      }
    });

    _dbRef!.child('$appNodeName/newNews').onValue.listen((event) {
      try {
        final val = event.snapshot.value;
        if (val is Map) {
          _newNewsCache = Map<dynamic, dynamic>.from(val);
        } else {
          _newNewsCache = {};
        }
        processAndCombine();
      } catch (e) {
        debugPrint("newNews stream error: $e");
      }
    });
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

  bool _getPlacement(String key) {
    try {
      final placements = adConfig['placements'];
      if (placements is Map) {
        return placements[key] == true;
      }
    } catch (_) {}
    return false;
  }

  void _handleCardTap(BuildContext context) {
    final bool adsEnabled = (adConfig['adStatus'] ?? '').toString().toUpperCase() == 'TRUE';
    final bool interstitialPlacement = _getPlacement('interstitialAdPostDetails');
    final String? interstitialId = adConfig['adMobInterstitialUnitId']?.toString();

    if (adsEnabled && interstitialPlacement && interstitialId != null && interstitialId.isNotEmpty) {
      InterstitialAd.load(
        adUnitId: interstitialId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            ad.show();
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _navigateToDetails(context);
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                _navigateToDetails(context);
              },
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
      MaterialPageRoute(builder: (context) => ArticleDetailsScreen(articleData: item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = item['title'] ?? item['newsTitle'] ?? 'Fikra Pro Update';
    final content = item['content'] ?? item['message'] ?? '';
    final preview = content.length > 120 ? '${content.substring(0, 120)}...' : content;
    final category = item['category'] ?? 'Fikra Pro Update';
    
    int timestamp = item['resolvedTimestamp'] ?? DateTime.now().millisecondsSinceEpoch;
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final formattedTime = DateFormat('MMM d, yyyy • h:mm:ss a').format(dateTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: () => _handleCardTap(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(category.toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F2C59))),
                  Text(formattedTime, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                ],
              ),
              const SizedBox(height: 8),
              Text(title.toString(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 4),
              Text(preview.toString(), style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
            ],
          ),
        ),
      ),
    );
  }
}
