import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../settings/data/localization/app_localizations.dart';
import '../../../../main.dart';  // Import to access providers

// Provider for app language (local to settings)
final settingsLanguageProvider = StateProvider<Locale>((ref) {
  // Default to English
  return const Locale('en', 'US');
});

// Provider for shared preferences
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String _currentLanguage = 'English';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('languageCode') ?? 'en';
      final countryCode = prefs.getString('countryCode') ?? 'US';
      
      setState(() {
        if (languageCode == 'zh') {
          _currentLanguage = '中文';
        } else {
          _currentLanguage = 'English';
        }
        
        // Update the local provider
        ref.read(settingsLanguageProvider.notifier).state = Locale(languageCode, countryCode);
      });
    } catch (e) {
      print('Error loading settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changeLanguage(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String languageCode;
      String countryCode;
      String displayName;
      
      if (language == 'Chinese' || language == '中文') {
        languageCode = 'zh';
        countryCode = 'CN';
        displayName = '中文';
      } else {
        languageCode = 'en';
        countryCode = 'US';
        displayName = 'English';
      }
      
      // Save to preferences
      await prefs.setString('languageCode', languageCode);
      await prefs.setString('countryCode', countryCode);
      
      setState(() {
        _currentLanguage = displayName;
      });
      
      // Update the app-wide locale provider
      ref.read(localeProvider.notifier).state = Locale(languageCode, countryCode);
      
      // Signal that the app needs to rebuild
      ref.read(appNeedsRebuildProvider.notifier).state = true;
      
      // Show language changed notification
      final translations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${translations.translate('language_changed')} $displayName'),
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Navigate to the dashboard after a short delay to force rebuild
      await Future.delayed(const Duration(milliseconds: 500));
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
      }
    } catch (e) {
      print('Error changing language: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error changing language: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(translations.translate('settings')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/dashboard');
            }
          },
        ),
      ),
      drawer: _buildNavigationDrawer(context),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        translations.translate('language_settings'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: translations.translate('select_language'),
                          border: const OutlineInputBorder(),
                        ),
                        value: _currentLanguage,
                        items: [
                          DropdownMenuItem(
                            value: 'English',
                            child: Text(translations.translate('english')),
                          ),
                          DropdownMenuItem(
                            value: '中文',
                            child: Text(translations.translate('chinese')),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            _changeLanguage(value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        translations.translate('app_info'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: Text(translations.translate('version')),
                        subtitle: const Text('1.0.0'),
                      ),
                      ListTile(
                        title: Text(translations.translate('build_number')),
                        subtitle: const Text('100'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildNavigationDrawer(BuildContext context) {
    final translations = AppLocalizations.of(context);
    return NavigationDrawer(
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.restaurant,
                color: Colors.white,
                size: 50,
              ),
              const SizedBox(height: 10),
              Text(
                translations.translate('restaurant_availability_system'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.dashboard),
          title: Text(translations.translate('dashboard')),
          onTap: () {
            Navigator.pushReplacementNamed(context, '/dashboard');
          },
        ),
        ListTile(
          leading: const Icon(Icons.restaurant),
          title: Text(translations.translate('restaurants')),
          onTap: () {
            Navigator.pushReplacementNamed(context, '/restaurants');
          },
        ),
        ListTile(
          leading: const Icon(Icons.book_online),
          title: Text(translations.translate('reservations')),
          onTap: () {
            Navigator.pushReplacementNamed(context, '/reservations');
          },
        ),
        ListTile(
          leading: const Icon(Icons.people),
          title: Text(translations.translate('users')),
          onTap: () {
            Navigator.pushReplacementNamed(context, '/users');
          },
        ),
        ListTile(
          leading: const Icon(Icons.settings),
          title: Text(translations.translate('settings')),
          onTap: () {
            Navigator.pushReplacementNamed(context, '/settings');
          },
        ),
      ],
    );
  }
} 