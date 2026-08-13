import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Support & Help', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How can we help you?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F2C59)),
            ),
            const SizedBox(height: 10),
            const Text(
              'Get in touch with us for any queries, suggestions or technical issues.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 30),
            
            _supportCard(
              context,
              icon: Icons.email_outlined,
              title: 'Email Us',
              subtitle: 'support@indianinformation.com',
              color: Colors.blue,
              onTap: () => _launchUrl('mailto:support@indianinformation.com'),
            ),
            _supportCard(
              context,
              icon: Icons.chat_bubble_outline,
              title: 'WhatsApp Support',
              subtitle: 'Chat with our team directly',
              color: Colors.green,
              onTap: () => _launchUrl('https://wa.me/910000000000'), // Placeholder
            ),
            _supportCard(
              context,
              icon: Icons.help_outline,
              title: 'Frequently Asked Questions',
              subtitle: 'Find quick answers to common issues',
              color: Colors.orange,
              onTap: () {
                // Show some FAQ or navigate to FAQ page
              },
            ),
            
            const SizedBox(height: 40),
            const Text(
              'Follow Us',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                _socialCircle(Icons.facebook, Colors.blue[800]!, 'https://facebook.com'),
                const SizedBox(width: 15),
                _socialCircle(Icons.camera_alt, Colors.pink, 'https://instagram.com'),
                const SizedBox(width: 15),
                _socialCircle(Icons.language, Colors.blue, 'https://indianinformation.com'),
              ],
            ),
            
            const SizedBox(height: 50),
            Center(
              child: Column(
                children: [
                  const Text('Indian Information Super App', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 5),
                  Text('Version 1.0.0 (Build 1)', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _supportCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      ),
    );
  }

  Widget _socialCircle(IconData icon, Color color, String url) {
    return InkWell(
      onTap: () => _launchUrl(url),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
