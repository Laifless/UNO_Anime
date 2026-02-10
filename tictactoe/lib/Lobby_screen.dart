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
    // 1. Controllo Pulizia Database
    DataSnapshot snapshot = await _roomRef.get();
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
      // RESET TOTALE (Tabula Rasa)
      await _roomRef.set({
        'playerNames': [widget.username],
        'status': 'waiting',
      });
    } else {
      // UNISCITI (Player 2)
      if (currentNames.length < 2) {
        await _roomRef.child('playerNames').runTransaction((Object? post) {
          List<dynamic> names = post != null ? List.from(post as List) : [];
          if (!names.contains(widget.username)) names.add(widget.username);
          return Transaction.success(names);
        });
      }
    }

    // 2. Ascolto
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

      // Se HOST e siamo in 2 -> START
      if (players.length == 2 && players.first == widget.username) {
        if (data['status'] != 'start') _roomRef.update({'status': 'start'});
      }

      // Se START -> Naviga
      if (data['status'] == 'start' && players.length == 2) {
        _goToGame();
      }
    });
  }

  void _goToGame() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    _sub?.cancel();

    bool amIHost = (players.isNotEmpty && players.first == widget.username);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameTableScreen(
          roomId: widget.roomId,
          universe: widget.universe,
          battleCry: widget.battleCry,
          characterGifUrl: "", 
          username: widget.username,
          isHost: amIHost,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      appBar: AppBar(title: const Text("LOBBY"), backgroundColor: Colors.transparent),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Stanza: ${widget.roomId}", style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 30),
            if (_isLoading) 
              const CircularProgressIndicator()
            else ...[
              ...players.map((p) => ListTile(
                title: Text(p, textAlign: TextAlign.center, 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: p == widget.username ? Colors.amber : Colors.white)),
                leading: Icon(Icons.flash_on, color: p == widget.username ? Colors.amber : Colors.grey),
              )),
              const SizedBox(height: 40),
              if (players.length < 2)
                const Text("In attesa dell'avversario...", style: TextStyle(color: Colors.white38))
              else
                const Text("START!", style: TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold))
            ]
          ],
        ),
      ),
    );
  }
}