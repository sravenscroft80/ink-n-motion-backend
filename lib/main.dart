import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/cupertino.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ink_n_motion/firebase_options.dart';

import 'package:ink_n_motion/screens/home_screen.dart';

import 'package:ink_n_motion/screens/splash_screen.dart';

import 'package:ink_n_motion/services/billing_service.dart';

import 'package:ink_n_motion/services/firebase_auth_service.dart';

import 'package:ink_n_motion/services/navigation.dart';

import 'package:ink_n_motion/services/storage_service.dart';

import 'package:ink_n_motion/services/user_service.dart';

import 'package:ink_n_motion/state/providers.dart';

import 'package:ink_n_motion/utils/design_tokens.dart';



Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();



  final storage = StorageService();

  await storage.ensureInitialized();



  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (error, stackTrace) {
    debugPrint('Firebase.initializeApp failed: $error');
    debugPrint('$stackTrace');
  }

  final authService = FirebaseAuthService();

  try {
    await authService.initialize();
  } catch (error, stackTrace) {
    debugPrint('FirebaseAuthService.initialize failed: $error');
    debugPrint('$stackTrace');
  }

  await BillingService.init();

  final userService = UserService(authService: authService);

  try {
    if (authService.isAvailable && authService.uid != null) {
      final revenueCatUserId =
          await BillingService.linkToFirebaseUser(authService.uid!) ??
              await BillingService.currentAppUserId();

      if (revenueCatUserId != null) {
        // await userService.linkRevenueCatAppUserId(revenueCatUserId);
      }
    }
  } catch (error, stackTrace) {
    debugPrint('Firebase/RevenueCat linking failed: $error');
    debugPrint('$stackTrace');
  }



  runApp(

    ProviderScope(

      overrides: [

        storageServiceProvider.overrideWithValue(storage),

        firebaseAuthServiceProvider.overrideWithValue(authService),

        userServiceProvider.overrideWithValue(userService),

      ],

      child: const InkNMotionApp(),

    ),

  );

}



class InkNMotionApp extends StatelessWidget {

  const InkNMotionApp({super.key});



  @override

  Widget build(BuildContext context) {

    return CupertinoApp(

      title: 'Ink‑N‑Motion',

      theme: buildInkCupertinoTheme(),

      debugShowCheckedModeBanner: false,

      home: const SplashScreen(),

      routes: HomeScreen.discoverPillarScreens,

      onGenerateRoute: InkNavigation.onGenerateRoute,

    );

  }

}

