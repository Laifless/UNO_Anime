import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Inizializzazione con i dati reali del tuo file JSON
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyBlIJMsIWmaMpTIVnGYvaeNXCGYyiSRKtQ",
          appId: "1:439223159038:android:97a70eaec081396ac67daf",
          messagingSenderId: "439223159038", // Preso dal project_number
          projectId: "server-ec79f",
          databaseURL: "https://server-ec79f-default-rtdb.firebaseio.com", // URL standard basato sull'ID
          storageBucket: "server-ec79f.firebasestorage.app",
        ),
      );
    }
  } catch (e) {
    debugPrint("Errore durante l'inizializzazione Firebase: $e");
  }
  
  runApp(const AnimeUnoApp());
}

class AnimeUnoApp extends StatelessWidget {
  const AnimeUnoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anime Battle UNO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFF0B0C10), // Il tuo colore scuro di sfondo
      ),
      home: const HomeScreen(),
    );
  }
}