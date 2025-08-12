import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _launchUrl(String url) async {
    try {
      if (!await launchUrl(Uri.parse(url))) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  void _showEmailCopiedSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Email address copied to clipboard'),
          ],
        ),
        backgroundColor: Colors.grey,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          color: Colors.yellow,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.redAccent, blurRadius: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.fiber_manual_record,
            color: Colors.grey,
            size: 8,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableLink(String text, String url, {IconData? icon}) {
    return InkWell(
      onTap: () => _launchUrl(url),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.launch, color: Colors.blue, size: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Matrix'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with improved styling
            Center(
              child: Card(
                color: Colors.grey[900],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        '🎵 Matrix 🎵',
                        style: TextStyle(
                          fontSize: 28,
                          color: Colors.yellow,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.redAccent, blurRadius: 3),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Thank you Archive.org!',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'and The Grateful Dead!!',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // About section
            const Text(
              'This app lists and plays, with gapless playback, mp3 files from Archive.org and provides a way to select a random matrix recording of choice Grateful Dead shows.',
              style: TextStyle(fontSize: 16, color: Colors.white, height: 1.5),
            ),

            _buildSectionTitle('How to Use'),

            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeatureItem('Tap "?" to play a random release'),
                    _buildFeatureItem('Long press in list will play selected show'),
                    _buildFeatureItem('Normal press will only display songs in show'),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(
                          Icons.play_circle,
                          color: Colors.yellow,
                          shadows: [
                            Shadow(color: Colors.redAccent, blurRadius: 3),
                            Shadow(color: Colors.redAccent, blurRadius: 6),
                          ],
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'will bring up music player controls',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            _buildSectionTitle('Future Features'),

            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeatureItem('Play random show at startup'),
                    _buildFeatureItem('Google Assistant integration'),
                    _buildFeatureItem('Android Auto support'),
                  ],
                ),
              ),
            ),

            _buildSectionTitle('Support & Links'),

            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildClickableLink(
                      'Consider donating to The Internet Archive',
                      'https://archive.org/donate/',
                      icon: Icons.favorite,
                    ),
                    const SizedBox(height: 8),
                    _buildClickableLink(
                      'Hunter\'s Trix info',
                      'https://www.google.com/search?q=hunter+seamons+matrix',
                      icon: Icons.info,
                    ),
                    const SizedBox(height: 8),
                    _buildClickableLink(
                      'Archive.org Terms of Use',
                      'https://archive.org/about/terms.php',
                      icon: Icons.gavel,
                    ),
                  ],
                ),
              ),
            ),

            _buildSectionTitle('Technical Info'),

            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'All audio is streamed from Archive.org',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Except for album 105, which has an icon ',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        const Icon(
                          Icons.album,
                          color: Colors.green,
                        ),
                        const Text(
                          ' (local/cached)',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Users are responsible for complying with copyright laws.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                      softWrap: true,
                    ),
                  ],
                ),
              ),
            ),

            _buildSectionTitle('Contact'),

            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Slapped together by',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(
                            const ClipboardData(text: 'jamart3d@gmail.com'));
                        _showEmailCopiedSnackBar(context);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.email, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'jamart3d@gmail.com',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.content_copy, color: Colors.blue, size: 16),
                          ],
                        ),
                      ),
                    ),
                    const Text(
                      'I take no credit for artwork or audio.',
                      style: TextStyle(
                        color: Colors.yellow,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.redAccent,
                            blurRadius: 3,
                          ),
                          Shadow(
                            color: Colors.redAccent,
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}