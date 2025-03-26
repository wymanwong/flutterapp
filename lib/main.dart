import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/restaurant/presentation/pages/restaurant_list_page.dart';
import 'features/reservations/presentation/pages/reservations_list_page.dart';
import 'features/analytics/presentation/pages/analytics_page.dart';
import 'features/users/presentation/pages/vip_profile_page.dart';
import 'features/restaurant/data/repositories/restaurant_repository.dart';
import 'features/restaurant/data/services/recommendation_service.dart';
import 'features/restaurant/presentation/pages/restaurant_form_page.dart';
import 'features/restaurant/presentation/pages/restaurant_detail_page.dart';
import 'features/restaurant/domain/models/restaurant.dart';
import 'features/users/data/repositories/vip_profile_repository.dart';
import 'features/reservations/data/repositories/reservation_repository.dart';
import 'features/notifications/services/firebase_messaging_service.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'features/settings/data/localization/app_localizations.dart';

// Background handler for Firebase Messaging - must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Need to ensure Firebase is initialized here if using other Firebase services
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Background message received: ${message.messageId}');
}

// Define providers
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final restaurantRepositoryProvider = Provider<RestaurantRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return RestaurantRepository(firestore: firestore);
});

final recommendationServiceProvider = Provider<RecommendationService>((ref) {
  final restaurantRepository = ref.watch(restaurantRepositoryProvider);
  return RecommendationService(restaurantRepository);
});

final vipProfileRepositoryProvider = Provider<VipProfileRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return VipProfileRepository(firestore: firestore);
});

final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  return ReservationRepository();
});

// Provider for the current locale that will force a rebuild
final localeProvider = StateProvider<Locale>((ref) {
  return const Locale('en', 'US'); // default locale
});

// Provider for dark mode
final darkModeProvider = StateProvider<bool>((ref) {
  return false; // default to light mode
});

// Provider to track when the app needs to be rebuilt
final appNeedsRebuildProvider = StateProvider<bool>((ref) => false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
    
    // Initialize Firebase Messaging background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Request notification permissions for iOS
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Get FCM token for this device
    String? token = await FirebaseMessaging.instance.getToken();
    print('FCM Token: $token');
    
    print('IMPORTANT: If you are experiencing permission issues, please check your Firestore security rules.');
    print('For development, you should set Firestore security rules to allow public read/write access:');
    print('''
    service cloud.firestore {
      match /databases/{database}/documents {
        match /{document=**} {
          allow read, write: if true;
        }
      }
    }
    ''');
    
    // Enable Firestore persistence and logging
    print('Configuring Firestore settings...');
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    print('Firestore settings configured');
    
    // Test Firestore connection
    try {
      print('Testing Firestore connection...');
      final testDoc = FirebaseFirestore.instance.collection('_test_connection').doc();
      print('Created test document reference: ${testDoc.path}');
      
      print('Attempting to write to Firestore...');
      await testDoc.set({'timestamp': FieldValue.serverTimestamp(), 'test': true});
      print('Successfully wrote to Firestore');
      
      print('Attempting to read from Firestore...');
      final result = await testDoc.get();
      print('Successfully read from Firestore. Document exists: ${result.exists}');
      if (result.exists) {
        print('Document data: ${result.data()}');
      }
      
      print('Attempting to delete test document...');
      await testDoc.delete();
      print('Successfully deleted test document');
      
      print('Firestore connection test result: SUCCESS');
    } catch (e) {
      print('Firestore connection test error: $e');
      if (e.toString().contains('permission-denied')) {
        print('ERROR: Permission denied. Please update your Firestore security rules in the Firebase Console.');
        print('Go to: https://console.firebase.google.com/project/restaurant-availability-sys/firestore/rules');
        print('And set the rules to:');
        print('''
        rules_version = '2';
        service cloud.firestore {
          match /databases/{database}/documents {
            match /{document=**} {
              allow read, write: if true;
            }
          }
        }
        ''');
      }
    }

    // Load saved language preference
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode') ?? 'en';
    final countryCode = prefs.getString('countryCode') ?? 'US';
    
  } catch (e) {
    print('Firebase initialization error: $e');
  }
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    _loadSavedLocale();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen for locale changes
    final locale = ref.watch(localeProvider);
    print('Locale changed to: ${locale.languageCode}-${locale.countryCode}');
  }

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('languageCode') ?? 'en';
      final countryCode = prefs.getString('countryCode') ?? 'US';
      
      print('Loading saved locale: $languageCode-$countryCode');
      ref.read(localeProvider.notifier).state = Locale(languageCode, countryCode);
    } catch (e) {
      print('Error loading locale: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(darkModeProvider);
    final currentLocale = ref.watch(localeProvider);
    final needsRebuild = ref.watch(appNeedsRebuildProvider);
    
    // Reset the rebuild flag
    if (needsRebuild) {
      // Using Future.microtask to avoid rebuilding during build
      Future.microtask(() {
        ref.read(appNeedsRebuildProvider.notifier).state = false;
      });
    }
    
    return MaterialApp(
      title: 'Restaurant Availability System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      locale: currentLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('zh', 'CN'),
      ],
      home: const DashboardPage(),
      routes: {
        '/dashboard': (context) => const DashboardPage(),
        '/restaurants': (context) => const RestaurantListPage(),
        '/reservations': (context) => const ReservationsListPage(),
        '/users': (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Users'),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add),
                tooltip: 'VIP Profile',
                onPressed: () => Navigator.of(context).pushReplacementNamed('/vip_profile'),
              ),
            ],
          ),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Users section coming soon'),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: null, // Will be implemented 
                  child: Text('User Management'),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: null, // Will be implemented
                  child: Text('Role Management'),
                ),
              ],
            ),
          ),
          drawer: _buildNavigationDrawer(context, 3),
        ),
        '/analytics': (context) => const AnalyticsPage(),
        '/settings': (context) => const SettingsPage(),
        '/vip_profile': (context) => const VipProfilePage(userId: 'current_user'),
        '/restaurant/detail': (context) {
          final restaurantId = ModalRoute.of(context)?.settings.arguments as String?;
          if (restaurantId != null) {
            // Get a provider reference 
            final providerContainer = ProviderScope.containerOf(context);
            // Use the provider to fetch the restaurant by ID
            final restaurantRepo = providerContainer.read(restaurantRepositoryProvider);
            
            // Return a FutureBuilder to load and display the restaurant
            return FutureBuilder<Restaurant?>(
              future: restaurantRepo.getRestaurantById(restaurantId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('Error')),
                    body: Center(child: Text('Error loading restaurant: ${snapshot.error}')),
                  );
                } else if (snapshot.hasData && snapshot.data != null) {
                  return RestaurantDetailPage(restaurant: snapshot.data!);
                } else {
                  return Scaffold(
                    appBar: AppBar(title: const Text('Not Found')),
                    body: const Center(child: Text('Restaurant not found')),
                  );
                }
              },
            );
          } else {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(child: Text('No restaurant ID provided')),
            );
          }
        },
        '/restaurant_availability': (context) => const RestaurantListPage(), // Link to availability page
      },
    );
  }
  
  // Common navigation drawer builder
  static Widget _buildNavigationDrawer(BuildContext context, int selectedIndex) {
    final translations = AppLocalizations.of(context);
    
    return NavigationDrawer(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        final routes = [
          '/dashboard',
          '/restaurants',
          '/reservations',
          '/users',
          '/analytics',
          '/settings',
        ];
        
        if (index >= 0 && index < routes.length) {
          Navigator.of(context).pushReplacementNamed(routes[index]);
        }
      },
      children: [
        NavigationDrawerDestination(
          icon: const Icon(Icons.dashboard),
          label: Text(translations.translate('dashboard')),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.restaurant),
          label: Text(translations.translate('restaurants')),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.book_online),
          label: Text(translations.translate('reservations')),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.people),
          label: Text(translations.translate('users')),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.analytics),
          label: Text(translations.translate('analytics')),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.settings),
          label: Text(translations.translate('settings')),
        ),
      ],
    );
  }
}
