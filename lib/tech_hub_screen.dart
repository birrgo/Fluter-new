import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class TechHubScreen extends StatefulWidget {
  const TechHubScreen({super.key});

  @override
  State<TechHubScreen> createState() => _TechHubScreenState();
}

class _TechHubScreenState extends State<TechHubScreen> with WidgetsBindingObserver {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  static const String appNodeName = "app14";

  List<Map<dynamic, dynamic>> _broadcasts = [];
  bool _isLoading = true;

  Map<dynamic, dynamic> _adConfig = {};
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAdConfigAndInit();
    _fetchDatabaseNews();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bannerAd?.dispose();
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
          _initBannerAd();
        }
      }
    });
  }

  void _showResumeAppOpenAd() {
    final bool adsEnabled = (_adConfig['adStatus'] ?? '').toString().toUpperCase() == 'TRUE';
    final bool resumePlacement = _adConfig['placements']?['appOpenAdStart'] == true;
    final String? appOpenId = _adConfig['adMobAppOpenUnitId'];

    if (!adsEnabled || !resumePlacement || appOpenId == null) return;

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

  // --- FIREBASE STREAMING FOR TECH HUB ---
  void _fetchDatabaseNews() {
    _dbRef.child('$appNodeName/shikelaNews').onValue.listen((event) {
      List<Map<dynamic, dynamic>> tempList = [];
      final data = event.snapshot.value;

      if (data is Map) {
        data.forEach((key, value) {
          if (value is Map) {
            final item = Map<dynamic, dynamic>.from(value);
            item['id'] = key;
            
            // Extract Timestamp safely
            var rawTime = item['updatedAt'] ?? item['createdAtTimestamp'] ?? item['timestamp'];
            if (rawTime == null && item['date'] != null) {
              rawTime = DateTime.tryParse(item['date'])?.millisecondsSinceEpoch;
            }
            item['resolvedTimestamp'] = rawTime ?? DateTime.now().millisecondsSinceEpoch;

            tempList.add(item);
          }
        });
      }

      tempList.sort((a, b) => b['resolvedTimestamp'].compareTo(a['resolvedTimestamp']));

      setState(() {
        _broadcasts = tempList;
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Strictly filter items to only show Tech Update and Tech Tips
    final filteredBroadcasts = _broadcasts.where((item) {
      final category = (item['category'] ?? 'Tech Update').toString().trim().toLowerCase();
      return category == 'tech update' || category == 'tech tips';
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF081B38),
        title: const Text('Tech Hub', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            // Open menu drawer
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredBroadcasts.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text(
                            "There are no updates or tips posted today.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredBroadcasts.length,
                        itemBuilder: (context, index) {
                          final item = filteredBroadcasts[index];
                          return NewsCard(item: item, adConfig: _adConfig);
                        },
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
    final title = item['title'] ?? item['newsTitle'] ?? 'Tech Update';
    final content = item['content'] ?? item['message'] ?? '';
    final preview = content.length > 120 ? '${content.substring(0, 120)}...' : content;
    final category = item['category'] ?? 'Tech Update';
    final imageUrl = item['imageUrl'] ?? item['image'] ?? '';

    final dateTime = DateTime.fromMillisecondsSinceEpoch(item['resolvedTimestamp']);
    final formattedTime = DateFormat('MMM d, yyyy • h:mm:ss a').format(dateTime);
    final isTips = category.trim().toLowerCase().contains("tips");

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
                    color: isTips ? const Color(0xFFF0F4F9) : const Color(0xFF0F2C59).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isTips ? const Color(0xFF2563EB) : const Color(0xFF0F2C59),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
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

// --- ARTICLE DETAILS SCREEN ---
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
