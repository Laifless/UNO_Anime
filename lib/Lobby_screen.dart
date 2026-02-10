import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'game_table_screen.dart';

class LobbyScreen extends StatefulWidget {
  final String roomId;
  final String username;
  final String universe;

  const LobbyScreen({
    super.key, 
    required this.roomId, 
    required this.username, 
    required this.universe
  });

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  late DatabaseReference _roomRef;
  List<String> players = [];
  bool _isLoading = true; // Per evitare il salto immediato
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _roomRef = FirebaseDatabase.instance.ref('rooms/${widget.roomId}');
    _joinLobby();
  }

  void _joinLobby() async {
    // 1. Entriamo nella stanza usando una transazione sicura
    try {
      await _roomRef.child('playerNames').runTransaction((Object? post) {
        List<dynamic> currentNames = post != null ? List.from(post as List) : [];
        if (!currentNames.contains(widget.username)) {
          if (currentNames.length < 2) {
            currentNames.add(widget.username);
          }
        }
        return Transaction.success(currentNames);
      });

      // 2. Una volta entrati, iniziamo ad ascoltare i cambiamenti
      _roomRef.onValue.listen((event) {
        final data = event.snapshot.value as Map?;
        if (data == null || !mounted) return;

        setState(() {
          if (data['playerNames'] != null) {
            players = List<String>.from(data['playerNames'] as List);
          }
          _isLoading = false; // Caricamento terminato
        });

        // 3. LOGICA HOST: Se sono il primo e siamo in 2, preparo il match
        if (players.length == 2 && players.first == widget.username) {
          if (data['status'] != 'playing' && !_isStarting) {
            _prepareMatch();
          }
        }

        // 4. LOGICA GUEST: Se lo stato è playing, vado al tavolo
        if (data['status'] == 'playing') {
          _navigateToGame();
        }
      });
    } catch (e) {
      debugPrint("Errore Firebase: $e");
    }
  }

  void _prepareMatch() async {
    _isStarting = true;
    // L'host imposta lo stato e pulisce eventuali vecchi dati della partita
    await _roomRef.update({
      'status': 'playing',
      'lastUpdate': ServerValue.timestamp,
    });
  }

  void _navigateToGame() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameTableScreen(
          roomId: widget.roomId,
          universe: widget.universe,
          battleCry: "La mia forza è assoluta!",
          characterGifUrl: "", 
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      body: Center(
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.cyanAccent)
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.hub, size: 80, color: Colors.cyanAccent),
                const SizedBox(height: 20),
                Text(
                  "STANZA: ${widget.roomId.toUpperCase()}",
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                
                // BOX GIOCATORI
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12)
                  ),
                  child: Column(
                    children: [
                      Text("Sfidanti (${players.length}/2)", 
                        style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                      const Divider(color: Colors.white12, height: 30),
                      ...players.map((p) => ListTile(
                        leading: const Icon(Icons.bolt, color: Colors.yellowAccent),
                        title: Text(p, style: const TextStyle(color: Colors.white)),
                        trailing: const Icon(Icons.check_circle, color: Colors.greenAccent),
                      )),
                      if (players.length < 2)
                        const Padding(
                          padding: EdgeInsets.only(top: 15),
                          child: Text("In attesa dell'avversario...", 
                            style: TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic)),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 50),
                if (players.length == 2)
                  const Text("Sincronizzazione in corso...", style: TextStyle(color: Colors.orangeAccent))
                else
                  const CircularProgressIndicator(color: Colors.redAccent, strokeWidth: 2),
              ],
            ),
      ),
    );
  }
}