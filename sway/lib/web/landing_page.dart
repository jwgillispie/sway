import 'package:flutter/material.dart';
import 'package:sway/config/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _emailController = TextEditingController();
  bool _isSubmitting = false;

  void _submitEmail() async {
    if (_emailController.text.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    // TODO: Implement email collection logic
    // This could be:
    // 1. Send to a backend API
    // 2. Use a service like Mailchimp
    // 3. Store in a database
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _isSubmitting = false;
    });

    // Show success dialog
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thanks for your interest!'),
        content: Text('We\'ll keep you updated about Sway.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _launchAppStore(String platform) async {
    // TODO: Replace with actual app store links
    final urls = {
      'ios': 'https://apps.apple.com/app/sway-hammock-spots',
      'android': 'https://play.google.com/store/apps/details?id=com.sway.hammockspots',
    };

    final url = urls[platform];
    if (url != null && await canLaunch(url)) {
      await launch(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Container(
              height: MediaQuery.of(context).size.height,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.7),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.waves,
                      size: 100,
                      color: Colors.white,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Sway: Discover Hammock Spots',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Find your perfect hammock paradise in Malta',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 24,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 48),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(Icons.apple),
                          label: Text('App Store'),
                          onPressed: () => _launchAppStore('ios'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        ElevatedButton.icon(
                          icon: Icon(Icons.android),
                          label: Text('Google Play'),
                          onPressed: () => _launchAppStore('android'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 48),
                    Container(
                      width: 500,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                fillColor: Colors.white,
                                filled: true,
                                hintText: 'Enter your email for updates',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitEmail,
                            child: _isSubmitting
                                ? CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text('Notify Me'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Features Section
            Container(
              padding: EdgeInsets.symmetric(vertical: 100, horizontal: 50),
              color: Colors.white,
              child: Column(
                children: [
                  Text(
                    'Explore. Discover. Relax.',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  SizedBox(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildFeatureCard(
                        icon: Icons.map,
                        title: 'Interactive Map',
                        description: 'Find hammock spots across Malta with our intuitive map interface.',
                      ),
                      SizedBox(width: 24),
                      _buildFeatureCard(
                        icon: Icons.people_sharp,
                        title: 'Community Driven',
                        description: 'Discover and share spots recommended by real hammock enthusiasts.',
                      ),
                      SizedBox(width: 24),
                      _buildFeatureCard(
                        icon: Icons.camera_alt,
                        title: 'Photo Reviews',
                        description: 'See real photos and detailed reviews of each hammock location.',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              color: AppColors.primary,
              padding: EdgeInsets.symmetric(vertical: 50),
              child: Center(
                child: Text(
                  '© 2024 Sway. All rights reserved.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: 300,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 64,
            color: AppColors.primary,
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.text.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}