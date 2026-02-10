import 'package:flutter/material.dart';
import 'home_screen.dart';

class EndGameScreen extends StatelessWidget {
  final bool isVictory;
  final String winnerName;

  const EndGameScreen({super.key, required this.isVictory, required this.winnerName});

  @override
  Widget build(BuildContext context) {
    final Color color = isVictory ? Colors.amber : Colors.red;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isVictory ? Icons.emoji_events : Icons.close, size: 100, color: color),
            Text(isVictory ? "VITTORIA!" : "SCONFITTA...", style: TextStyle(fontSize: 40, color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text("Vincitore: $winnerName", style: const TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20)),
              onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false),
              child: const Text("TORNA AL MENU", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}