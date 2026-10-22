import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  static const String appId = "app14";

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String? _telegramUrl;
  String? _instagramUrl;
  String? _emailAddress;

  String? _selectedSubjectKey;
  String? _selectedSubjectTitle;

  bool _isSubmitting = false;

  final Map<String, String> _subjects = {
    'jobs': 'Question about a Daily Job Vacancy',
    'business': 'Submit a Profitable Business Tip',
    'advertising': 'Advertising / Corporate Partnerships',
    'tech': 'Tech Issue / App Support',
    'other': 'Other General Inquiry',
  };

  @override
  void initState() {
    super.initState();
    _fetchSocialLinks();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _fetchSocialLinks() {
    _dbRef.child('$appId/social_links').get().then((snapshot) {
      if (snapshot.exists && snapshot.value is Map) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        setState(() {
          _telegramUrl = data['telegram']?.toString();
          _instagramUrl = data['instagram']?.toString();
          _emailAddress = data['email']?.toString();
        });
      }
    });
  }

  Future<void> _launchURL(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      _showStatusDialog(
        isSuccess: false,
        title: 'Error',
        message: 'Could not open link.',
      );
    }
  }

  void _openSubjectPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF334155)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.between,
                  children: [
                    const Text(
                      'Select Subject',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._subjects.entries.map((entry) {
                  final isSelected = entry.key == _selectedSubjectKey;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedSubjectKey = entry.key;
                          _selectedSubjectTitle = entry.value;
                        });
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF334155),
                          ),
                        ),
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSubjectKey == null) {
      _showStatusDialog(
        isSuccess: false,
        title: 'Required Field',
        message: 'Please select a Subject of Inquiry before sending.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final messagesRef = _dbRef.child('$appId/messages').push();
      await messagesRef.set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'subject': _selectedSubjectKey,
        'message': _messageController.text.trim(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      _nameController.clear();
      _emailController.clear();
      _messageController.clear();
      setState(() {
        _selectedSubjectKey = null;
        _selectedSubjectTitle = null;
      });

      _showStatusDialog(
        isSuccess: true,
        title: 'Message Sent!',
        message: 'Thank you for contacting Fikra Pro! Your message has been sent successfully.',
      );
    } catch (e) {
      _showStatusDialog(
        isSuccess: false,
        title: 'Submission Failed',
        message: 'Failed to send message. Please try again later.',
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showStatusDialog({required bool isSuccess, required String title, required String message}) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF334155)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSuccess
                        ? const Color(0xFF10B981).withOpacity(0.15)
                        : const Color(0xFFEF4444).withOpacity(0.15),
                  ),
                  child: Icon(
                    isSuccess ? Icons.check : Icons.close,
                    color: isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
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
          'Contact Support',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'We Are Here to Help',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'At Fikra Pro, community is at the heart of everything we do. Whether you are an Ethiopian freelancer looking for guidance on a specific daily job vacancy, an entrepreneur wanting to share a profitable business tip, or a brand interested in advertising on our platform, our dedicated support team is ready to assist you.',
                style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 15, height: 1.6),
              ),
              const SizedBox(height: 12),
              const Text(
                'Because we handle a high volume of inquiries regarding digital work and tech updates, we have provided multiple channels for you to reach us. Choose the method that works best for you below.',
                style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 15, height: 1.6),
              ),

              const SizedBox(height: 25),
              const Divider(color: Color(0xFF334155)),
              const SizedBox(height: 20),

              const Text(
                'Connect via Socials & Email',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'For immediate community support, daily updates, or direct admin contact, use our official channels below.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              ),
              const SizedBox(height: 16),

              // Social buttons
              _buildSocialButton(
                title: 'Join our Telegram Community',
                color: const Color(0xFF0088CC),
                icon: Icons.send,
                onTap: () => _launchURL(_telegramUrl),
              ),
              const SizedBox(height: 12),
              _buildSocialButton(
                title: 'Follow us on Instagram',
                color: const Color(0xFFDC2743),
                icon: Icons.camera_alt,
                onTap: () => _launchURL(_instagramUrl),
              ),
              const SizedBox(height: 12),
              _buildSocialButton(
                title: 'Email our Support Team directly',
                color: const Color(0xFFEA4335),
                icon: Icons.email,
                onTap: () => _launchURL(_emailAddress != null ? 'mailto:$_emailAddress' : null),
              ),

              const SizedBox(height: 30),
              const Text(
                'Send a Secure Message',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'If you prefer, you can fill out the secure form below. We aim to reply to all formal inquiries within 24 to 48 business hours.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              ),
              const SizedBox(height: 20),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Full Name'),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration('e.g. Abebe Kebede'),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 18),

                    _buildLabel('Email Address'),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration('your@email.com'),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your email' : null,
                    ),
                    const SizedBox(height: 18),

                    _buildLabel('Subject of Inquiry'),
                    InkWell(
                      onTap: _openSubjectPicker,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF475569)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.between,
                          children: [
                            Text(
                              _selectedSubjectTitle ?? 'Select an inquiry type...',
                              style: TextStyle(
                                color: _selectedSubjectTitle != null ? Colors.white : const Color(0xFF64748B),
                                fontSize: 15,
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    _buildLabel('Detailed Message'),
                    TextFormField(
                      controller: _messageController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration('Please provide as much context and detail as possible...'),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a message' : null,
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isSubmitting ? null : _submitForm,
                        child: Text(
                          _isSubmitting ? 'Sending...' : 'Send Secure Message',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: const Border(
                    left: BorderSide(color: Color(0xFF10B981), width: 4),
                  ),
                ),
                child: const RichText(
                  text: TextSpan(
                    style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14, height: 1.5),
                    children: [
                      TextSpan(
                        text: 'Support Guidelines: ',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      TextSpan(
                        text: 'Please note that Fikra Pro acts as an aggregator for online job postings. We do not directly hire for the external vacancies listed on our site. Please do not send CVs or resumes through this contact form, as they will not be forwarded to third-party employers.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFF1E293B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF475569)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF475569)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
      ),
      contentPadding: const EdgeInsets.all(14),
    );
  }

  Widget _buildSocialButton({
    required String title,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
