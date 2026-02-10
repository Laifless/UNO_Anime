import 'package:flutter/material.dart';
import 'Lobby_screen.dart';

class AnimeHero {
  final String name;
  final String ultimateName;
  final String gifUrl;
  final Color themeColor;

  AnimeHero({
    required this.name, 
    required this.ultimateName, 
    required this.gifUrl, 
    this.themeColor = Colors.indigoAccent
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentStep = 0; 
  String selectedUniverse = "Dragon Ball";
  AnimeHero? selectedHero;

  final Map<String, List<AnimeHero>> universeHeroes = {
    "Dragon Ball": [
      AnimeHero(name: "Goku", ultimateName: "KAMEHAMEHA", gifUrl: "", themeColor: Colors.orange),
      AnimeHero(name: "Vegeta", ultimateName: "FINAL FLASH", gifUrl: "", themeColor: Colors.blue),
    ],
    "Naruto": [
      AnimeHero(name: "Naruto", ultimateName: "RASENGAN", gifUrl: "", themeColor: Colors.orangeAccent),
      AnimeHero(name: "Sasuke", ultimateName: "CHIDORI", gifUrl: "", themeColor: Colors.purple),
    ],
    "One Piece": [
      AnimeHero(name: "Luffy", ultimateName: "GEAR 5", gifUrl: "", themeColor: Colors.red),
      AnimeHero(name: "Zoro", ultimateName: "SANTORYU", gifUrl: "", themeColor: Colors.green),
    ],
    "Bleach": [
      AnimeHero(name: "Ichigo", ultimateName: "BANKAI", gifUrl: "", themeColor: Colors.black87),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            const Text("ANIME BATTLE", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.cyanAccent, letterSpacing: 2)),
            const Text("CARD GAME", style: TextStyle(fontSize: 16, color: Colors.cyan)),
            const SizedBox(height: 40),
            
            Expanded(
              child: SingleChildScrollView(
                child: currentStep == 0 ? _buildUniverseSelection() : _buildHeroSelection(),
              ),
            ),

            if (currentStep == 1)
              _btn("ENTRA NELLA LOBBY", () {
                if (selectedHero == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LobbyScreen(
                      roomId: "battle_room_1", 
                      username: selectedHero!.name,
                      universe: selectedUniverse,
                      battleCry: selectedHero!.ultimateName, // Passiamo la mossa speciale
                    ),
                  ),
                );
              }, color: Colors.redAccent),

            if (currentStep > 0)
              TextButton(
                onPressed: () => setState(() { currentStep = 0; selectedHero = null; }),
                child: const Text("CAMBIA UNIVERSO", style: TextStyle(color: Colors.white54)),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUniverseSelection() {
    return Column(
      children: universeHeroes.keys.map((u) => _btn(u, () {
        setState(() { selectedUniverse = u; currentStep = 1; });
      })).toList(),
    );
  }

  Widget _buildHeroSelection() {
    return Column(
      children: universeHeroes[selectedUniverse]!.map((hero) {
        bool isSelected = selectedHero?.name == hero.name;
        return GestureDetector(
          onTap: () => setState(() => selectedHero = hero),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isSelected ? hero.themeColor.withOpacity(0.2) : Colors.white10,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: isSelected ? hero.themeColor : Colors.white12),
            ),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: hero.themeColor, child: const Icon(Icons.bolt, color: Colors.white)),
                const SizedBox(width: 20),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(hero.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(hero.ultimateName, style: TextStyle(color: hero.themeColor, fontSize: 12)),
                ]),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _btn(String txt, VoidCallback tap, {Color color = Colors.indigo}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color, 
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
        ),
        onPressed: tap,
        child: Text(txt, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}