import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:intl/intl.dart';

class ArticleDetailsScreen extends StatefulWidget {
  // FIXED: Changed from Map<String, dynamic> to Map<dynamic, dynamic> to prevent TypeCasting crashes
  final Map<dynamic, dynamic> articleData;
  final bool isAdminMode;

  const ArticleDetailsScreen({
    super.key,
    required this.articleData,
    this.isAdminMode = false,
  });

  @override
  State<ArticleDetailsScreen> createState() => _ArticleDetailsScreenState();
}

class _ArticleDetailsScreenState extends State<ArticleDetailsScreen> {
  // Theme Color Constants matching your HTML/CSS design
  static const Color primaryHeaderDark = Color(0xFF081B38);
  static const Color primaryBurgundy = Color(0xFF0F2C59);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFE2E8F0);

  // App Database Node Name
  static const String appNodeName = "app14";

  // AdMob Native Ad State
  NativeAd? _nativeAd;
  bool _isNativeAdLoaded = false;

  // YouTube Player Controller
  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();
    _initYouTubePlayer();
    _fetchAdConfigAndLoadNativeAd();
  }

  /// Initialize YouTube Embed if Video URL or ID exists
  void _initYouTubePlayer() {
    final rawVideoUrl = widget.articleData['videoUrl'] ??
        widget.articleData['youtubeUrl'] ??
        widget.articleData['youtubeId'] ??
        '';

    final videoId = YoutubePlayer.convertUrlToId(rawVideoUrl.toString());
    if (videoId != null && videoId.isNotEmpty) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: true,
        ),
      );
    }
  }

  /// Fetch AdMob Config from Firebase RTDB Node ('app14/adManager')
  Future<void> _fetchAdConfigAndLoadNativeAd() async {
    try {
      // FIXED: Updated from 'app1' to 'app14'
      final dbRef = FirebaseDatabase.instance.ref('$appNodeName/adManager');
      final snapshot = await dbRef.get();

      if (snapshot.exists && snapshot.value is Map) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        final bool status = (data['adStatus'] ?? '').toString().toUpperCase() == 'TRUE' ||
            (data['adStatus'] ?? '').toString().toUpperCase() == 'ON';

        final String nativeId = data['adMobNativeUnitId']?.toString() ?? '';

        if (status && nativeId.isNotEmpty) {
          _loadNativeAd(nativeId);
        }
      }
    } catch (e) {
      debugPrint("Firebase AdMob config fetch error: $e");
    }
  }

  /// Load Native AdMob Ad
  void _loadNativeAd(String unitId) {
    _nativeAd = NativeAd(
      adUnitId: unitId,
      factoryId: 'adFactorySmall',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isNativeAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Native Ad failed to load: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  /// Duplicate Article Functionality for Admin Mode
  Future<void> _duplicateAsAdmin() async {
    try {
      // FIXED: Updated from 'app1' to 'app14'
      final DatabaseReference dbRef =
          FirebaseDatabase.instance.ref('$appNodeName/shikelaNews');

      final cloned = Map<dynamic, dynamic>.from(widget.articleData);
      final now = DateTime.now().millisecondsSinceEpoch;

      cloned['createdAtTimestamp'] = now;
      cloned['updatedAt'] = now;
      cloned['timestamp'] = now;
      cloned['title'] = "${cloned['title'] ?? cloned['newsTitle'] ?? 'Untitled'} (Copy)";

      await dbRef.push().set(Map<String, dynamic>.from(cloned));
      _showPopupAlert("✅", "Article Duplicated", "Successfully duplicated item in database.");
    } catch (e) {
      _showPopupAlert("❌", "Duplication Error", "Failed to duplicate item into database.");
    }
  }

  /// Display Popup Dialog matching web style
  void _showPopupAlert(String icon, String title, String desc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 6),
            Text(desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: textMuted)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBurgundy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("Continue", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Launch external links safely
  Future<void> _launchExternalUrl(String urlStr) async {
    final Uri? uri = Uri.tryParse(urlStr);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Format Timestamps cleanly
  String _formatTimestamp(dynamic timestamp) {
    int epoch = DateTime.now().millisecondsSinceEpoch;
    if (timestamp is int) {
      epoch = timestamp;
    } else if (timestamp is String) {
      epoch = int.tryParse(timestamp) ?? DateTime.tryParse(timestamp)?.millisecondsSinceEpoch ?? epoch;
    }
    final dt = DateTime.fromMillisecondsSinceEpoch(epoch);
    return DateFormat('MMM d, yyyy • hh:mm:ss a').format(dt);
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.articleData;
    final headline = item['title'] ?? item['newsTitle'] ?? "Shikela Update";
    final fullContent = item['content'] ?? item['message'] ?? "";
    final category = item['category'] ?? "Online Update";
    final imageUrl = item['imageUrl'] ?? item['image'] ?? "";
    final duplicateCoverInArticle = item['duplicateCoverInArticle'] ?? item['duplicateImageInArticle'] ?? true;
    final targetRedirectUrl = item['link'] ?? item['redirectUrl'] ?? "";
    final customActionLabel = item['actionButtonLabel'] ?? item['buttonLabel'] ?? "Visit External Source / Link";
    final formattedDate = _formatTimestamp(item['updatedAt'] ?? item['createdAtTimestamp'] ?? item['timestamp']);

    final isTips = category.toString().toLowerCase().contains("tips");

    return Scaffold(
      backgroundColor: primaryHeaderDark,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // --- Sticky Top Header ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: primaryHeaderDark,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Article Details",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // --- FIXED TOP AD SECTION ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.white,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderLight),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1C40F),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "ADVERTISEMENT",
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 100,
                      width: double.infinity,
                      child: _isNativeAdLoaded && _nativeAd != null
                          ? AdWidget(ad: _nativeAd!)
                          : Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text(
                                  "Loading Ad...",
                                  style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // --- Scrollable Article Content ---
            Expanded(
              child: Container(
                color: Colors.white,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Admin Duplicate Button
                      if (widget.isAdminMode)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE2E8F0),
                                foregroundColor: textDark,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _duplicateAsAdmin,
                              icon: const Icon(Icons.copy, size: 16),
                              label: const Text("📋 Duplicate Article Entry", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),

                      // Meta Bar (Category Badge + Date)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isTips ? const Color(0xFFF0F4F9) : const Color(0x140F2C59),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              category.toString().toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isTips ? const Color(0xFF2563EB) : primaryBurgundy,
                              ),
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        headline.toString(),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textDark, height: 1.3),
                      ),
                      const SizedBox(height: 16),

                      // Image Frame
                      if (imageUrl.isNotEmpty && duplicateCoverInArticle)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl.toString(),
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 200,
                                color: const Color(0xFFF1F5F9),
                                child: const Center(child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) => const SizedBox.shrink(),
                            ),
                          ),
                        ),

                      // Video Player
                      if (_youtubeController != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: YoutubePlayer(
                              controller: _youtubeController!,
                              showVideoProgressIndicator: true,
                            ),
                          ),
                        ),

                      // Article Body Text
                      Text(
                        fullContent.toString(),
                        style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                      ),

                      // External Action Button
                      if (targetRedirectUrl.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBurgundy,
                                padding: const EdgeInsets.all(14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _launchExternalUrl(targetRedirectUrl.toString()),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(customActionLabel.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.open_in_new, size: 18, color: Colors.white),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // 300px Whitespace at the end
                      const SizedBox(height: 300),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom base block to cover mobile safe-area nicely
            Container(
              height: MediaQuery.of(context).padding.bottom + 10,
              color: primaryHeaderDark,
            ),
          ],
        ),
      ),
    );
  }
}
