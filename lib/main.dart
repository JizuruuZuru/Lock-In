import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'utils/firebase_options.dart';
import 'app_gate.dart';
import 'services/sound_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Offline support. Persistence is on by default on Android and iOS but off
  // on the web, so it is set explicitly for every platform. With it enabled
  // Firestore serves reads from its local cache when the network is gone, and
  // queues writes until the device reconnects — which is what lets an admin
  // add a question offline and lets students keep playing teacher-made
  // questions with no signal.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const BrainTrainerApp());
}

class BrainTrainerApp extends StatefulWidget {
  const BrainTrainerApp({super.key});

  @override
  State<BrainTrainerApp> createState() => _BrainTrainerAppState();
}

class _BrainTrainerAppState extends State<BrainTrainerApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lock In',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        // Bundled, not downloaded - see the fonts section in pubspec.yaml.
        // Setting the family on the theme is enough; every text style
        // inherits it, so no separate textTheme override is needed.
        fontFamily: 'NotoSans',
      ),
      home: const AppGate(),
    );
  }

  @override
  void dispose() {
    // Dispose the sound service when the app is terminated
    SoundService().dispose();
    super.dispose();
  }
}