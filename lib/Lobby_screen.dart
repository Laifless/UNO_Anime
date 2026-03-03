import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'game_table_screen.dart';

class LobbyScreen extends StatefulWidget {
  final String roomId;
  final String username;
  final String universe;
  final String battleCry;

  const LobbyScreen({
    super.key, 
    required this.roomId, 
    required this.username, 
    required this.universe,
    required this.battleCry,
  });

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  late DatabaseReference _roomRef;
  StreamSubscription? _sub;
  List<String> players = [];
  bool _isLoading = true; 
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _roomRef = FirebaseDatabase.instance.ref('rooms/${widget.roomId}');
    _joinLobby();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _joinLobby() async {
    try {
      DataSnapshot snapshot = await _roomRef.get().timeout(const Duration(seconds: 10));
      bool shouldReset = false;
      List<dynamic> currentNames = [];
      String status = "waiting";

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        if (data['playerNames'] != null) currentNames = List.from(data['playerNames'] as List);
        status = data['status'] ?? "waiting";
        
        if (currentNames.isEmpty || status != 'waiting' || currentNames.contains(widget.username)) {
          shouldReset = true;
        }
      } else {
        shouldReset = true;
      }

      if (shouldReset) {
        await _roomRef.set({
          'playerNames': [widget.username],
          'status': 'waiting',
        });
      } else {
        if (currentNames.length < 2) {
          await _roomRef.child('playerNames').runTransaction((Object? post) {
            List<dynamic> names = post != null ? List.from(post as List) : [];
            if (!names.contains(widget.username)) names.add(widget.username);
            return Transaction.success(names);
          });
        }
      }

      _sub = _roomRef.onValue.listen((event) {
        if (!mounted || _hasNavigated) return;
        final data = event.snapshot.value as Map?;
        if (data == null) return;

        if (data['playerNames'] != null) {
          setState(() {
            players = List<String>.from(data['playerNames'] as List);
            _isLoading = false;
          });
        }

        if (players.length == 2 && players.first == widget.username) {
          if (data['status'] != 'start') _roomRef.update({'status': 'start'});
        }

        if (data['status'] == 'start' && players.length == 2) {
          _goToGame();
        }
      });

    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Errore: $e"), backgroundColor: Colors.red));
      }
    }
  }

  void _goToGame() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    _sub?.cancel();

    // --- LOGICA RIGIDA DEI RUOLI ---
    // Se sono il primo nella lista, sono player1. Altrimenti sono player2.
    String assignedRole = "player2"; 
    if (players.isNotEmpty && players.indexOf(widget.username) == 0) {
      assignedRole = "player1";
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameTableScreen(
          roomId: widget.roomId,
          universe: widget.universe,
          battleCry: widget.battleCry,
          characterGifUrl: "", 
          username: widget.username,
          playerId: assignedRole, // <--- PASSIAMO IL RUOLO UFFICIALE
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
                Text("STANZA: ${widget.roomId.toUpperCase()}", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),
                
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
                  child: Column(
                    children: [
                      Text("Sfidanti (${players.length}/2)", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                      const Divider(color: Colors.white12, height: 30),
                      ...players.map((p) => ListTile(
                        leading: const Icon(Icons.bolt, color: Colors.yellowAccent),
                        title: Text(p, style: const TextStyle(color: Colors.white)),
                        trailing: const Icon(Icons.check_circle, color: Colors.greenAccent),
                      )),
                      if (players.length < 2)
                        const Padding(padding: EdgeInsets.only(top: 15), child: Text("In attesa dell'avversario...", style: TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic))),
                    ],
                  ),
                ),
                
                const SizedBox(height: 50),
                if (players.length == 2) const Text("Sincronizzazione in corso...", style: TextStyle(color: Colors.orangeAccent))
                else const CircularProgressIndicator(color: Colors.redAccent, strokeWidth: 2),
              ],
            ),
      ),
    );
  }
}