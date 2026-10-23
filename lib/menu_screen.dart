import 'package:flutter/material.dart';
import 'terms_screen.dart';
import 'privacy_screen.dart';
import 'about_screen.dart';
import 'contact_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF081B38),
        elevation: 0,
        title: const Text(
          'Menu',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Menu Cards List
            _buildMenuCard(
              context,
              title: 'Terms & Conditions',
              icon: Icons.description_outlined,
              destination: const TermsScreen(),
            ),
            const SizedBox(height: 16),
            _buildMenuCard(
              context,
              title: 'Privacy Policy',
              icon: Icons.security_outlined,
              destination: const PrivacyScreen(),
            ),
            const SizedBox(height: 16),
            _buildMenuCard(
              context,
              title: 'About Us',
              icon: Icons.info_outline,
              destination: const AboutScreen(),
            ),
            const SizedBox(height: 16),
            _buildMenuCard(
              context,
              title: 'Contact Us',
              icon: Icons.mail_outline,
              destination: const ContactScreen(),
            ),

            const SizedBox(height: 40),
            const Center(
              child: Text(
                'FIKRA PRO VERIFIED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget destination,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          // FIXED: Changed from MainAxisAlignment.between to MainAxisAlignment.spaceBetween
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: const Color(0xFF38BDF8),
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.white60,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
