import 'package:flutter/material.dart';
import 'package:sway/config/theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sway/config/routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sway/blocs/auth/auth_bloc.dart';
import 'package:sway/data/repositories/user_repository.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSubmitting = false;
  bool _showSignUpForm = false;
  bool _showLoginForm = false;
  String? _authError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

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
    await Future.delayed(const Duration(seconds: 2));

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
        title: const Text('Thanks for your interest!'),
        content: const Text('We\'ll keep you updated about Sway.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _toggleSignUpForm() {
    setState(() {
      _showSignUpForm = !_showSignUpForm;
      _showLoginForm = false;
      _authError = null;
    });
  }

  void _toggleLoginForm() {
    setState(() {
      _showLoginForm = !_showLoginForm;
      _showSignUpForm = false;
      _authError = null;
    });
  }

  Future<void> _signUp() async {
    if (_emailController.text.isEmpty || 
        _passwordController.text.isEmpty || 
        _nameController.text.isEmpty) {
      setState(() {
        _authError = 'All fields are required';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _authError = null;
    });

    try {
      context.read<AuthBloc>().add(
        SignUpRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          username: _nameController.text.trim(),
        ),
      );
      
      // Wait for auth state to change
      await Future.delayed(const Duration(seconds: 1));

      // Handle navigation in BlocListener
    } catch (e) {
      setState(() {
        _authError = e.toString();
        _isSubmitting = false;
      });
    }
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _authError = 'Email and password are required';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _authError = null;
    });

    try {
      context.read<AuthBloc>().add(
        SignInRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
      
      // Wait for auth state to change
      await Future.delayed(const Duration(seconds: 1));

      // Handle navigation in BlocListener
    } catch (e) {
      setState(() {
        _authError = e.toString();
        _isSubmitting = false;
      });
    }
  }

  void _launchAppStore(String platform) async {
    // TODO: Replace with actual app store links when available
    final urls = {
      'ios': Uri.parse('https://apps.apple.com/app/sway-hammock-spots'),
      'android': Uri.parse('https://play.google.com/store/apps/details?id=com.sway.hammockspots'),
    };

    final url = urls[platform];
    if (url != null && await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      // Since you don't have an app in the store yet, you can show a dialog
      // explaining that the app is coming soon
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Coming Soon!'),
          content: const Text('Sway will be available in app stores soon. Thanks for your interest!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          setState(() {
            _isSubmitting = false;
          });
          Navigator.of(context).pushReplacementNamed(Routes.home);
        } else if (state is AuthFailure) {
          setState(() {
            _authError = state.message;
            _isSubmitting = false;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            TextButton(
              onPressed: _toggleLoginForm,
              child: const Text(
                'Login',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: _toggleSignUpForm,
              child: const Text(
                'Sign Up',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        extendBodyBehindAppBar: true,
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
                      const Icon(
                        Icons.waves,
                        size: 100,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Sway: Discover Hammock Spots',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Find your perfect hammock paradise',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 24,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      
                      if (_showSignUpForm) ...[
                        _buildSignUpForm(),
                      ] else if (_showLoginForm) ...[
                        _buildLoginForm(),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.apple),
                              label: const Text('App Store'),
                              onPressed: () => _launchAppStore('ios'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.android),
                              label: const Text('Google Play'),
                              onPressed: () => _launchAppStore('android'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),
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
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: _isSubmitting ? null : _submitEmail,
                                child: _isSubmitting
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Text('Notify Me'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Features Section
              Container(
                padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 50),
                color: Colors.white,
                child: Column(
                  children: [
                    const Text(
                      'Explore. Discover. Relax.',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 48),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildFeatureCard(
                          icon: Icons.map,
                          title: 'Interactive Map',
                          description: 'Find hammock spots with our intuitive map interface.',
                        ),
                        const SizedBox(width: 24),
                        _buildFeatureCard(
                          icon: Icons.people_sharp,
                          title: 'Community Driven',
                          description: 'Discover and share spots recommended by real hammock enthusiasts.',
                        ),
                        const SizedBox(width: 24),
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
                padding: const EdgeInsets.symmetric(vertical: 50),
                child: const Center(
                  child: Text(
                    '© 2025 Sway. All rights reserved.',
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
      ),
    );
  }

  Widget _buildSignUpForm() {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          const BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Create Account',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Your Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
          ),
          if (_authError != null) ...[
            const SizedBox(height: 16),
            Text(
              _authError!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _signUp,
              child: _isSubmitting
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : const Text('Sign Up'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _toggleLoginForm,
            child: const Text('Already have an account? Log in'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          const BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Log In',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
          ),
          if (_authError != null) ...[
            const SizedBox(height: 16),
            Text(
              _authError!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _login,
              child: _isSubmitting
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : const Text('Log In'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _toggleSignUpForm,
            child: const Text('Don\'t have an account? Sign up'),
          ),
        ],
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          const BoxShadow(
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
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),
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