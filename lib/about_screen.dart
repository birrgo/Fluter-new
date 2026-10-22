import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  static const String appId = "app14";

  String? _aboutContent;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchAboutDataFromFirebase();
  }

  void _fetchAboutDataFromFirebase() {
    _dbRef.child('$appId/about').onValue.listen(
      (event) {
        final data = event.snapshot.value;
        if (mounted) {
          setState(() {
            if (data != null) {
              if (data is String) {
                _aboutContent = data;
              } else if (data is Map && data.containsKey('content')) {
                _aboutContent = data['content'].toString();
              } else {
                _aboutContent = 'No content available.';
              }
            } else {
              _aboutContent = 'No information available yet.';
            }
            _isLoading = false;
            _hasError = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF081B38),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'About Us',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 200),
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 15,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: _buildContentState(),
        ),
      ),
    );
  }

  Widget _buildContentState() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40.0),
        child: Center(
          child: Text(
            'Loading content...',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    if (_hasError) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40.0),
        child: Center(
          child: Text(
            'Failed to load content.',
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Text(
      _aboutContent ?? 'No information available yet.',
      style: const TextStyle(
        color: Color(0xFFCBD5E1),
        fontSize: 15,
        height: 1.8,
      ),
    );
  }
}
