import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/controllers/theme_controller.dart';
import 'core/services/localization_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/sync_service.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/step_tracking/controllers/step_tracking_controller.dart';
import 'features/weight/controllers/weight_controller.dart';
import 'features/steps/controllers/steps_controller.dart';
import 'features/goals/controllers/goals_controller.dart';
import 'features/step_tracking/presentation/pages/home_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'features/profile/presentation/pages/profile_form_page.dart';
import 'features/weight/presentation/pages/weight_entries_page.dart';
import 'features/steps/presentation/pages/steps_entries_page.dart';
import 'features/goals/presentation/pages/goals_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Firebase and Sync services
  final firebaseService = FirebaseService();
  await firebaseService.initialize();
  
  final syncService = SyncService();
  await syncService.initialize();
  
  runApp(const StepsTrackerApp());
}

class StepsTrackerApp extends StatelessWidget {
  const StepsTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => LocalizationService()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => StepTrackingController()),
        ChangeNotifierProvider(create: (_) => WeightController()),
        ChangeNotifierProvider(create: (_) => StepsController()),
        ChangeNotifierProvider(create: (_) => GoalsController()),
      ],
      child: Consumer2<ThemeController, LocalizationService>(
        builder: (context, themeController, localizationService, child) {
          return MaterialApp(
            title: 'Steps Tracker',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF2E7D32),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            themeMode: themeController.themeMode,
            locale: localizationService.locale,
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('ar', 'SA'),
            ],
            home: const AuthWrapper(),
            routes: {
              '/auth': (context) => const AuthPage(),
              '/profile-form': (context) => const ProfileFormPage(),
              '/main': (context) => const MainNavigationPage(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        if (authController.isSignedIn) {
          if (authController.hasProfile) {
            return const MainNavigationPage();
          } else {
            return const ProfileFormPage();
          }
        } else {
          return const AuthPage();
        }
      },
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const WeightEntriesPage(),
    const StepsEntriesPage(),
    const GoalsPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_weight),
            label: 'Weight',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_walk),
            label: 'Steps',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag),
            label: 'Goals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
