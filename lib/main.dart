import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/fcm_service.dart';
import 'utils/app_theme.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Format tanggal berbahasa Indonesia.
  await initializeDateFormatting('id_ID', null);

  // Handler notifikasi saat aplikasi di background/terminated.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const SapaAlumniApp());
}

class SapaAlumniApp extends StatefulWidget {
  const SapaAlumniApp({super.key});

  @override
  State<SapaAlumniApp> createState() => _SapaAlumniAppState();
}

class _SapaAlumniAppState extends State<SapaAlumniApp> {
  @override
  void initState() {
    super.initState();
    FcmService.instance.listenForeground(scaffoldMessengerKey);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SAPA Alumni',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: AppTheme.light(),
      home: const SplashScreen(),
    );
  }
}
