// lib/screens/landing/landing_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sway/services/auth_service.dart';
import 'package:sway/widgets/auth/signup_form.dart';
import 'package:url_launcher/url_launcher.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool _showSignUpForm = false;
  bool _isMenuOpen = false;
  bool _isSubmittingEmail = false;
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _toggleSignUpForm() {
    setState(() {
      _showSignUpForm = !_showSignUpForm;
      if (_isMenuOpen) {
        _isMenuOpen = false;
      }
    });
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }
  
  Future<void> _submitEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingEmail = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.addToWaitlist(email);
      
      if (mounted) {
        setState(() {
          _isSubmittingEmail = false;
          _emailController.clear();
        });
        
        _showSuccessDialog("Thanks for your interest!", 
          "We've added you to our early access waitlist. We'll notify you when the app is ready to launch!");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmittingEmail = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 768;
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Responsive App Bar
            _buildResponsiveAppBar(context, authService, isMobile),

            // Expanded Mobile Menu (when open)
            if (isMobile && _isMenuOpen)
              _buildMobileMenu(context, authService),

            // Hero Section
            _buildHeroSection(context, screenSize, isMobile, authService),

            // Features Section
            _buildFeaturesSection(context, isMobile),

            // Call to Action
            _buildCallToAction(context, isMobile),

            // Footer
            _buildFooter(context, isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveAppBar(BuildContext context, AuthService authService, bool isMobile) {
    return Container(
      color: Theme.of(context).colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Sway',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isMobile)
            IconButton(
              icon: Icon(
                _isMenuOpen ? Icons.close : Icons.menu,
                color: Colors.white,
              ),
              onPressed: _toggleMenu,
            )
          else
            Row(
              children: [
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Features',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'About',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                if (authService.currentUser == null)
                  TextButton(
                    onPressed: _toggleSignUpForm,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('Sign Up'),
                  )
                else
                  TextButton(
                    onPressed: () => authService.signOut(),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('Sign Out'),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMobileMenu(BuildContext context, AuthService authService) {
    return Container(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.9),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          ListTile(
            title: const Text(
              'Features',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              _toggleMenu();
            },
          ),
          ListTile(
            title: const Text(
              'About',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              _toggleMenu();
            },
          ),
          const Divider(color: Colors.white24),
          ListTile(
            title: Text(
              authService.currentUser == null ? 'Sign Up' : 'Sign Out',
              style: const TextStyle(color: Colors.white),
            ),
            onTap: () {
              _toggleMenu();
              if (authService.currentUser == null) {
                _toggleSignUpForm();
              } else {
                authService.signOut();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, Size screenSize, bool isMobile, AuthService authService) {
    return Container(
      constraints: BoxConstraints(
        minHeight: isMobile ? screenSize.height * 0.6 : screenSize.height * 0.7,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2A9D8F), // Primary color
            Color(0xFF264653), // Darker shade
          ],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -100,
            top: -100,
            child: Opacity(
              opacity: 0.1,
              child: Icon(
                Icons.waves,
                size: 500,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: isMobile
                ? _buildMobileHeroContent(context, authService)
                : _buildDesktopHeroContent(context, authService),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeroContent(BuildContext context, AuthService authService) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Find Your Perfect Hammock Spot',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 28,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Discover and share the best places to hang your hammock.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _toggleSignUpForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text('Join Our Community'),
            ),
          ],
        ),
        const SizedBox(height: 32),
        if (_showSignUpForm)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Create an Account',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A9D8F),
                  ),
                ),
                const SizedBox(height: 24),
                SignUpForm(
                  onSignUpSuccess: () {
                    setState(() {
                      _showSignUpForm = false;
                    });
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopHeroContent(BuildContext context, AuthService authService) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Find Your Perfect Hammock Spot',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 42,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 700,
              child: Text(
                'Discover beautiful spots, share your favorites, and connect with the hammock community.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _toggleSignUpForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Join Our Community'),
            ),
          ],
        ),
        const SizedBox(height: 40),
        if (_showSignUpForm)
          Container(
            width: 450,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Create an Account',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A9D8F),
                  ),
                ),
                const SizedBox(height: 24),
                SignUpForm(
                  onSignUpSuccess: () {
                    setState(() {
                      _showSignUpForm = false;
                    });
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFeaturesSection(BuildContext context, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Text(
            'Why Use Sway',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Find, share, and enjoy the perfect spots for your hammock adventures',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          isMobile
              ? _buildMobileFeatureCards(context)
              : _buildDesktopFeatureCards(context),
        ],
      ),
    );
  }

  Widget _buildMobileFeatureCards(BuildContext context) {
    return Column(
      children: [
        _buildFeatureCardMobile(
          context,
          Icons.map_outlined,
          'Discover Spots',
          'Find hammock spots near you with our interactive map.',
        ),
        _buildFeatureCardMobile(
          context,
          Icons.add_location_outlined,
          'Share Locations',
          'Add your favorite hammock spots to help others find great places.',
        ),
        _buildFeatureCardMobile(
          context,
          Icons.star_outline,
          'Rate and Review',
          'Share your experiences and discover highly-rated spots.',
        ),
        _buildFeatureCardMobile(
          context,
          Icons.photo_camera_outlined,
          'Photo Galleries',
          'See photos of each spot to know exactly what to expect.',
        ),
        _buildFeatureCardMobile(
          context,
          Icons.nature_people_outlined,
          'Community',
          'Connect with other hammock enthusiasts and share tips.',
        ),
        _buildFeatureCardMobile(
          context,
          Icons.notifications_outlined,
          'Stay Updated',
          'Get notified about new spots in your favorite areas.',
        ),
      ],
    );
  }

  Widget _buildDesktopFeatureCards(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _buildFeatureCard(
              context,
              Icons.map_outlined,
              'Discover Spots',
              'Find hammock spots near you with our interactive map.',
            ),
            _buildFeatureCard(
              context,
              Icons.add_location_outlined,
              'Share Locations',
              'Add your favorite hammock spots to help others find great places.',
            ),
            _buildFeatureCard(
              context,
              Icons.star_outline,
              'Rate and Review',
              'Share your experiences and discover highly-rated spots.',
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            _buildFeatureCard(
              context,
              Icons.photo_camera_outlined,
              'Photo Galleries',
              'See photos of each spot to know exactly what to expect.',
            ),
            _buildFeatureCard(
              context,
              Icons.nature_people_outlined,
              'Community',
              'Connect with other hammock enthusiasts and share tips.',
            ),
            _buildFeatureCard(
              context,
              Icons.notifications_outlined,
              'Stay Updated',
              'Get notified about new spots in your favorite areas.',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCardMobile(
      BuildContext context, IconData icon, String title, String description) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
      BuildContext context, IconData icon, String title, String description) {
    return Expanded(
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallToAction(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 64, 
        horizontal: isMobile ? 24 : 32
      ),
      color: const Color(0xFFEDE7F6),
      child: Column(
        children: [
          Text(
            'Be the First to Know',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: isMobile ? double.infinity : 600,
            child: Text(
              'Join our waitlist to be notified when we launch. Get early access to the best hammock spot finder app!',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            width: isMobile ? double.infinity : 500,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your email',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isSubmittingEmail ? null : _submitEmail,
                  child: _isSubmittingEmail
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.0,
                          ),
                        )
                      : const Text('Join Waitlist'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: const Color(0xFF264653),
      child: Column(
        children: [
          isMobile
              ? Column(
                  children: [
                    const Text(
                      'Sway',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.facebook, color: Colors.white),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.web, color: Colors.white),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.email, color: Colors.white),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sway',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.facebook, color: Colors.white),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.web, color: Colors.white),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.email, color: Colors.white),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
          const Divider(color: Colors.white24, height: 32),
          const Text(
            '© 2025 Sway. All rights reserved.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}