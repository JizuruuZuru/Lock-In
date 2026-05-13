import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'utils/firebase_options.dart';
import 'onboarding_gate.dart';
import 'services/sound_service.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
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
        fontFamily: GoogleFonts.notoSans().fontFamily,
        textTheme: GoogleFonts.notoSansTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const OnboardingGate(),
    );
  }

  @override
  void dispose() {
    // Dispose the sound service when the app is terminated
    SoundService().dispose();
    super.dispose();
  }
}