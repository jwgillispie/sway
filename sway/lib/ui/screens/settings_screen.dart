// lib/ui/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sway/blocs/auth/auth_bloc.dart';
import 'package:sway/config/constants.dart';
import 'package:sway/config/routes.dart';
import 'package:sway/ui/widgets/custom_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  String _appVersion = '';
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _getAppVersion();
  }
  
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _isDarkMode = prefs.getBool('dark_mode') ?? false;
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _locationEnabled = prefs.getBool('location_enabled') ?? true;
      });
    } catch (e) {
      print('Error loading settings: $e');
    }
  }
  
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('dark_mode', _isDarkMode);
      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      await prefs.setBool('location_enabled', _locationEnabled);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Settings saved')),
      );
    } catch (e) {
      print('Error saving settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving settings')),
      );
    }
  }
  
  Future<void> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      
      setState(() {
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      });
    } catch (e) {
      print('Error getting app version: $e');
    }
  }
  
  void _signOut() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      context.read<AuthBloc>().add(SignOutRequested());
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }
  
  void _openPrivacyPolicy() async {
    const url = 'https://sway-app.com/privacy-policy';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open privacy policy')),
      );
    }
  }
  
  void _openTermsOfService() async {
    const url = 'https://sway-app.com/terms-of-service';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open terms of service')),
      );
    }
  }
  
  void _openSupportEmail() async {
    const email = 'support@sway-app.com';
    const subject = 'Support Request - Sway App';
    final Uri uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=$subject',
    );
    
    if (await canLaunch(uri.toString())) {
      await launch(uri.toString());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open email client')),
      );
    }
  }
  
  void _upgradeAccount() {
    // TODO: Implement premium upgrade
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upgrade to Premium'),
        content: Text('Premium features coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _clearCache() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // TODO: Implement actual cache clearing logic
      
      // Simulate cache clearing
      await Future.delayed(Duration(seconds: 1));
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cache cleared')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing cache: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              Routes.login,
              (route) => false,
            );
          }
        },
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.all(16),
              children: [
                // Account section
                _buildSectionTitle('Account'),
                
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    if (state is AuthAuthenticated) {
                      final user = state.user;
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user.profilePhoto != null
                              ? NetworkImage(user.profilePhoto!)
                              : null,
                          child: user.profilePhoto == null
                              ? Icon(Icons.person)
                              : null,
                        ),
                        title: Text(user.username),
                        subtitle: Text(user.email),
                        trailing: user.isPremium
                            ? Chip(
                                label: Text('Premium'),
                                backgroundColor: Theme.of(context).colorScheme.secondary,
                                labelStyle: TextStyle(color: Colors.white),
                              )
                            : OutlinedButton(
                                onPressed: _upgradeAccount,
                                child: Text('Upgrade'),
                              ),
                      );
                    } else if (state is AuthUnauthenticated) {
                      return ListTile(
                        leading: Icon(Icons.account_circle),
                        title: Text('Sign in to access all features'),
                        trailing: TextButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed(Routes.login);
                          },
                          child: Text('Sign In'),
                        ),
                      );
                    }
                    
                    return SizedBox.shrink();
                  },
                ),
                
                Divider(),
                
                // Appearance section
                _buildSectionTitle('Appearance'),
                
                SwitchListTile(
                  title: Text('Dark Mode'),
                  subtitle: Text('Switch between light and dark theme'),
                  value: _isDarkMode,
                  onChanged: (value) {
                    setState(() {
                      _isDarkMode = value;
                    });
                    
                    // TODO: Implement theme switching
                  },
                ),
                
                Divider(),
                
                // Notifications section
                _buildSectionTitle('Notifications'),
                
                SwitchListTile(
                  title: Text('Push Notifications'),
                  subtitle: Text('Receive notifications about new spots and reviews'),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
                
                Divider(),
                
                // Privacy section
                _buildSectionTitle('Privacy'),
                
                SwitchListTile(
                  title: Text('Location Services'),
                  subtitle: Text('Allow app to access your location'),
                  value: _locationEnabled,
                  onChanged: (value) {
                    setState(() {
                      _locationEnabled = value;
                    });
                  },
                ),
                
                ListTile(
                  title: Text('Privacy Policy'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _openPrivacyPolicy,
                ),
                
                ListTile(
                  title: Text('Terms of Service'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _openTermsOfService,
                ),
                
                Divider(),
                
                // Support section
                _buildSectionTitle('Support'),
                
                ListTile(
                  title: Text('Contact Support'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _openSupportEmail,
                ),
                
                ListTile(
                  title: Text('Clear Cache'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _clearCache,
                ),
                
                Divider(),
                
                // App info section
                _buildSectionTitle('About'),
                
                ListTile(
                  title: Text('Version'),
                  trailing: Text(_appVersion),
                ),
                
                SizedBox(height: 24),
                
                // Save settings button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: CustomButton(
                    label: 'Save Settings',
                    onPressed: _saveSettings,
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Sign out button
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    if (state is AuthAuthenticated) {
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: CustomButton(
                          label: 'Sign Out',
                          isOutlined: true,
                          onPressed: _signOut,
                          isLoading: _isLoading,
                        ),
                      );
                    }
                    
                    return SizedBox.shrink();
                  },
                ),
                
                SizedBox(height: 24),
              ],
            ),
            
            if (_isLoading && !(BlocProvider.of<AuthBloc>(context).state is AuthLoading))
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}