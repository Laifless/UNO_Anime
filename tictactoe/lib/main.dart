import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'home_screen.dart';

void main() async {
  // Necessario per assicurarsi che i servizi nativi (come Firebase) siano pronti prima di runApp
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Inizializzazione manuale ottimizzata
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyBlIJMsIWmaMpTIVnGYvaeNXCGYyiSRKtQ",
          appId: "1:439223159038:android:97a70eaec081396ac67daf",
          messagingSenderId: "439223159038",
          projectId: "server-ec79f",
          // Assicurati che non ci siano spazi vuoti in questo URL
          databaseURL: "https://server-ec79f-default-rtdb.europe-west1.firebasedatabase.app/",
          storageBucket: "server-ec79f.firebasestorage.app",
        ),
      );
    }
    debugPrint("Firebase inizializzato correttamente");
  } catch (e) {
    // Fornisce un errore chiaro in console se il database non risponde
    debugPrint("ERRORE CRITICO FIREBASE: $e"); 
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
      // Usiamo dark() come base per garantire la leggibilità dei testi chiari
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.cyanAccent,
        scaffoldBackgroundColor: const Color(0xFF0B0C10), 
        // Aggiungiamo il supporto per i bottoni moderni
        useMaterial3: true, 
      ),
      home: const HomeScreen(),
    );
  }
}