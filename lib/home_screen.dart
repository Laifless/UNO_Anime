import 'package:flutter/material.dart';
import 'Lobby_screen.dart'; // Collegamento alla lobby
import 'models.dart';

// Modello per l'Eroe
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

  // Il tuo database originale completo
  final Map<String, List<AnimeHero>> universeHeroes = {
    "Dragon Ball": [
      AnimeHero(name: "Goku", ultimateName: "KAMEHAMEHA", gifUrl: "", themeColor: Colors.orange),
      AnimeHero(name: "Vegeta", ultimateName: "FINAL FLASH", gifUrl: "", themeColor: Colors.blue),
    ],
    "Naruto": [
      AnimeHero(name: "Naruto Uzumaki", ultimateName: "RASENGAN", gifUrl: "", themeColor: Colors.orangeAccent),
      AnimeHero(name: "Sasuke Uchiha", ultimateName: "CHIDORI", gifUrl: "", themeColor: Colors.purple),
    ],
    "One Piece": [
      AnimeHero(name: "Luffy", ultimateName: "GEAR 5", gifUrl: "", themeColor: Colors.red),
      AnimeHero(name: "Zoro", ultimateName: "SANTORYU", gifUrl: "", themeColor: Colors.green),
    ],
    "Bleach": [
      AnimeHero(name: "Ichigo Kurosaki", ultimateName: "BANKAI", gifUrl: "", themeColor: Colors.orange),
      AnimeHero(name: "Sosuke Aizen", ultimateName: "KYOKA SUIGETSU", gifUrl: "", themeColor: Colors.deepPurple),
    ],
    "Jujutsu Kaisen": [
      AnimeHero(name: "Satoru Gojo", ultimateName: "VOID INFERNO", gifUrl: "", themeColor: Colors.blue),
      AnimeHero(name: "Ryomen Sukuna", ultimateName: "MALEVOLENT SHRINE", gifUrl: "", themeColor: Colors.red),
    ],
    "Tokyo Ghoul": [
      AnimeHero(name: "Ken Kaneki", ultimateName: "KAGUNE UNLEASHED", gifUrl: "", themeColor: Colors.grey),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "ANIME BATTLE UNO",
              style: TextStyle(
                fontSize: 36, 
                fontWeight: FontWeight.bold, 
                color: Colors.cyanAccent,
                letterSpacing: 3,
                shadows: [Shadow(color: Colors.cyan, blurRadius: 10)]
              ),
            ),
            const SizedBox(height: 40),
            
            // Step 0: Scelta Universo | Step 1: Scelta Eroe
            Expanded(
              child: SingleChildScrollView(
                child: currentStep == 0 ? _buildUniverseSelection() : _buildHeroSelection(),
              ),
            ),

            const SizedBox(height: 20),
            
            if (currentStep == 1) 
              _btn("ENTRA NELLA LOBBY", () {}, color: Colors.redAccent),
            
            if (currentStep > 0)
              TextButton(
                onPressed: () => setState(() {
                  currentStep = 0;
                  selectedHero = null;
                }),
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
        setState(() {
          selectedUniverse = u;
          currentStep = 1;
        });
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
              color: isSelected ? hero.themeColor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? hero.themeColor : Colors.white12,
                width: 2
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: hero.themeColor,
                  child: const Icon(Icons.bolt, color: Colors.white),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hero.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(hero.ultimateName, style: TextStyle(color: hero.themeColor, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _btn(String txt, VoidCallback tap, {Color color = Colors.indigo}) {
    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          elevation: 10,
          shadowColor: color.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: () {
          if (txt == "ENTRA NELLA LOBBY") {
            if (selectedHero == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Scegli il tuo guerriero!")),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LobbyScreen(
                  roomId: "battle_room_1", 
                  username: selectedHero!.name,
                  universe: selectedUniverse,
                ),
              ),
            );
          } else {
            tap();
          }
        },
        child: Text(txt, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}