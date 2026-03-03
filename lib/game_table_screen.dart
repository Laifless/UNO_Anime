import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'models.dart';

class GameTableScreen extends StatefulWidget {
  final String roomId;
  final String universe;
  final String battleCry;
  final String characterGifUrl;
  final String username; 
  final String playerId; 

  const GameTableScreen({
    super.key,
    required this.roomId,
    required this.universe,
    required this.battleCry,
    required this.characterGifUrl,
    required this.username,
    required this.playerId, 
  });

  @override
  State<GameTableScreen> createState() => _GameTableScreenState();
}

class _GameTableScreenState extends State<GameTableScreen> {
  late DatabaseReference _gameRef;
  StreamSubscription? _gameSubscription;

  List<AnimeCard> myHand = [];
  List<AnimeCard> opponentHand = [];
  List<AnimeCard> drawPile = [];
  AnimeCard? lastPlayedCard;
  
  String currentTurnId = ""; 
  String myPlayerId = "";    
  bool _gameFinished = false;

  int opponentHandCount = 7;
  bool opponentSafe = true;

  Timer? _turnTimer;
  int _secondsLeft = 15;
  int _lastActionTime = 0;

  // --- NUOVA VARIABILE PER RICORDARE L'URLO ---
  bool _hasShoutedBattleCry = false;

  @override
  void initState() {
    super.initState();
    _gameRef = FirebaseDatabase.instance.ref('rooms/${widget.roomId}');
    _setupGame();
  }

  @override
  void dispose() {
    _gameSubscription?.cancel();
    _turnTimer?.cancel();
    super.dispose();
  }

  List<AnimeCard> _generateDeck() {
    List<AnimeCard> deck = [];
    List<Color> colors = [Colors.red, Colors.blue, Colors.green, Colors.amber];

    for (var color in colors) {
      for (int i = 0; i <= 9; i++) {
        deck.add(AnimeCard(name: "Card $i", color: color, value: i.toString(), type: CardType.normal));
      }
      deck.add(AnimeCard(name: "Skip", color: color, value: "Ø", type: CardType.special, power: SpecialPower.skip));
      deck.add(AnimeCard(name: "Draw Two", color: color, value: "+2", type: CardType.special, power: SpecialPower.drawTwo));
    }

    for (int i = 0; i < 4; i++) {
      deck.add(AnimeCard(name: "Wild", color: Colors.black, value: "W", type: CardType.wild, power: SpecialPower.changeColor));
      deck.add(AnimeCard(name: "Wild Draw Four", color: Colors.black, value: "+4", type: CardType.wild, power: SpecialPower.wildDrawFour));
    }

    deck.shuffle(); 
    return deck;
  }

  Future<void> _setupGame() async {
    if (widget.roomId == "solo") {
      myPlayerId = "player1";
      currentTurnId = "player1";
      _setupLocalGame();
    } else {
      myPlayerId = widget.playerId; 
      if (myPlayerId == "player1") _createMatchOnFirebase(); 
      _listenToMultiplayer();
    }
  }

  void _setupLocalGame() {
    drawPile = _generateDeck();
    myHand = List.generate(7, (_) => drawPile.removeLast());
    opponentHand = List.generate(7, (_) => drawPile.removeLast());
    lastPlayedCard = drawPile.firstWhere((c) => c.type == CardType.normal);
    drawPile.remove(lastPlayedCard);
    setState(() {});
    _startTimer();
  }

  void _createMatchOnFirebase() async {
    DataSnapshot check = await _gameRef.child('drawPile').get();
    if (check.exists) return;

    List<AnimeCard> fullDeck = _generateDeck();
    List<AnimeCard> p1Hand = List.generate(7, (_) => fullDeck.removeLast());
    List<AnimeCard> p2Hand = List.generate(7, (_) => fullDeck.removeLast());
    AnimeCard firstCard = fullDeck.firstWhere((c) => c.type == CardType.normal);
    fullDeck.remove(firstCard);

    await _gameRef.update({
      'turn': 'player1', 
      'lastActionTime': ServerValue.timestamp, 
      'lastPlayedCard': firstCard.toJson(),
      'drawPile': fullDeck.map((c) => c.toJson()).toList(),
      'players': {
        'player1': {'hand': p1Hand.map((c) => c.toJson()).toList(), 'unoSafe': true},
        'player2': {'hand': p2Hand.map((c) => c.toJson()).toList(), 'unoSafe': true},
      }
    });
  }

  void _listenToMultiplayer() {
    _gameSubscription = _gameRef.onValue.listen((event) {
      if (!mounted || event.snapshot.value == null) return;
      final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);

      if (data['status'] == 'finished' && !_gameFinished) {
         _gameFinished = true;
         String winner = data['winner'] ?? "Sconosciuto";
         bool iWon = (winner == widget.username);
         _turnTimer?.cancel();
         _showEndGame(iWon, winner); // Richiama la nuova grafica!
         return;
      }

      setState(() {
        currentTurnId = data['turn'] ?? "player1";
        if (data['lastPlayedCard'] != null) lastPlayedCard = AnimeCard.fromJson(data['lastPlayedCard']);
        if (data['drawPile'] != null) drawPile = (data['drawPile'] as List).map((c) => AnimeCard.fromJson(c)).toList();

        var players = data['players'] as Map?;
        if (players != null) {
          var myData = players[myPlayerId] as Map?;
          if (myData != null && myData['hand'] != null) {
            myHand = (myData['hand'] as List).map((c) => AnimeCard.fromJson(c)).toList();
          } else {
            myHand = [];
          }
          
          String oppId = (myPlayerId == "player1") ? "player2" : "player1";
          var oppData = players[oppId] as Map?;
          if (oppData != null && oppData['hand'] != null) {
            opponentHandCount = (oppData['hand'] as List).length;
            opponentSafe = oppData['unoSafe'] ?? true;
            opponentHand = List.generate(opponentHandCount, (_) => AnimeCard(name: "", color: Colors.grey, value: ""));
          } else {
            opponentHand = [];
          }
        }
      });

      int serverTime = data['lastActionTime'] ?? 0;
      if (serverTime != _lastActionTime) {
        _lastActionTime = serverTime;
        _startTimer();
      }
    });
  }

  void playCard(int index) async {
    if (currentTurnId != myPlayerId) return; 
    AnimeCard selected = myHand[index];
    
    if (selected.canBePlayedOn(lastPlayedCard)) {
      _turnTimer?.cancel(); 
      Color? newColor;
      
      if (selected.color.value == Colors.black.value) {
        newColor = await _showColorPicker();
        if (newColor == null) { _startTimer(); return; }
        selected.color = newColor;
      }

      myHand.removeAt(index);
      bool isSkipPower = (selected.power == SpecialPower.skip || selected.power == SpecialPower.drawTwo || selected.power == SpecialPower.wildDrawFour);
      
      if (widget.roomId == "solo") {
        setState(() {
          lastPlayedCard = selected;
          _applyPower(selected.power, false);
          currentTurnId = isSkipPower ? myPlayerId : "player2";
          
          if (myHand.isEmpty) {
            _showEndGame(true, widget.username);
          } else if (currentTurnId == "player2") {
            _botTurn();
          } else {
            _startTimer(); 
          }
        });
      } 
      else {
        if (myHand.isEmpty) {
          await _gameRef.update({'status': 'finished', 'winner': widget.username});
          return;
        }

        Map<String, dynamic> updates = {};
        updates['lastPlayedCard'] = selected.toJson();
        updates['players/$myPlayerId/hand'] = myHand.map((c) => c.toJson()).toList();
        
        // --- LOGICA DI SICUREZZA UNO PERFETTA ---
        if (myHand.length == 1) {
          // Se rimani con 1 carta, sei salvo SOLO SE hai urlato prima di giocarla
          updates['players/$myPlayerId/unoSafe'] = _hasShoutedBattleCry;
          _hasShoutedBattleCry = false; // Reset per il prossimo turno
        } else {
          // Se hai più di 1 carta sei sempre salvo
          updates['players/$myPlayerId/unoSafe'] = true;
          _hasShoutedBattleCry = false;
        }
        // ----------------------------------------

        updates['lastActionTime'] = ServerValue.timestamp; 

        int cardsToDraw = 0;
        if (selected.power == SpecialPower.drawTwo) { cardsToDraw = 2; } 
        else if (selected.power == SpecialPower.wildDrawFour) { cardsToDraw = 4; } 

        if (cardsToDraw > 0) {
          String oppId = (myPlayerId == "player1") ? "player2" : "player1";
          DataSnapshot snap = await _gameRef.child('players/$oppId/hand').get();
          List<AnimeCard> oppHandData = [];
          if (snap.exists && snap.value != null) {
            oppHandData = (snap.value as List).map((c) => AnimeCard.fromJson(c as Map)).toList();
          }
          for (int i = 0; i < cardsToDraw; i++) {
             if (drawPile.isEmpty) drawPile = _generateDeck()..shuffle();
             oppHandData.add(drawPile.removeLast());
          }
          updates['players/$oppId/hand'] = oppHandData.map((c) => c.toJson()).toList();
          updates['drawPile'] = drawPile.map((c) => c.toJson()).toList();
          updates['players/$oppId/unoSafe'] = true; 
        }

        updates['turn'] = isSkipPower ? myPlayerId : (myPlayerId == "player1" ? "player2" : "player1");
        await _gameRef.update(updates);
      }
    }
  }

  void drawCard() async {
    if (currentTurnId != myPlayerId) return;
    _turnTimer?.cancel(); 
    
    // Se pesco, azzero l'urlo eventuale per sicurezza
    _hasShoutedBattleCry = false;

    if (drawPile.isEmpty) drawPile = _generateDeck()..shuffle();
    
    AnimeCard drawn = drawPile.removeLast();
    myHand.add(drawn);
    String nextTurn = (myPlayerId == "player1" ? "player2" : "player1");

    if (widget.roomId == "solo") {
      setState(() {
        currentTurnId = nextTurn;
        _botTurn();
      });
    } else {
      await _gameRef.update({
        'drawPile': drawPile.map((c) => c.toJson()).toList(),
        'players/$myPlayerId/hand': myHand.map((c) => c.toJson()).toList(),
        'players/$myPlayerId/unoSafe': true, 
        'turn': nextTurn,
        'lastActionTime': ServerValue.timestamp, 
      });
    }
  }

  void _applyPower(SpecialPower p, bool isBotTarget) {
    int cards = 0;
    if (p == SpecialPower.drawTwo) cards = 2;
    if (p == SpecialPower.wildDrawFour) cards = 4;

    for (int i = 0; i < cards; i++) {
      if (drawPile.isEmpty) drawPile = _generateDeck()..shuffle();
      if (isBotTarget) myHand.add(drawPile.removeLast());
      else opponentHand.add(drawPile.removeLast());
    }
  }

  void _botTurn() async {
    _turnTimer?.cancel(); 
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted || currentTurnId != "player2") return;
    
    int idx = _calculateBestBotMove();
    setState(() {
      if (idx != -1) {
        AnimeCard c = opponentHand.removeAt(idx);
        if (c.color.value == Colors.black.value) c.color = _getBestColorForBot();
        lastPlayedCard = c;
        _applyPower(c.power, true); 
        
        bool isSkipPower = (c.power == SpecialPower.skip || c.power == SpecialPower.drawTwo || c.power == SpecialPower.wildDrawFour);
        currentTurnId = isSkipPower ? "player2" : "player1";
        
        if (opponentHand.isEmpty) {
          _showEndGame(false, "IL BOT");
        } else if (currentTurnId == "player2") {
          _botTurn(); 
        } else {
          _startTimer(); 
        }
      } else {
        if (drawPile.isEmpty) drawPile = _generateDeck()..shuffle();
        opponentHand.add(drawPile.removeLast());
        currentTurnId = "player1";
        _startTimer(); 
      }
    });
  }

  int _calculateBestBotMove() => opponentHand.indexWhere((c) => c.canBePlayedOn(lastPlayedCard));
  Color _getBestColorForBot() => Colors.red;

  void _shoutBattleCry() {
    setState(() {
      _hasShoutedBattleCry = true;
    });

    // Se sono a 1 carta (me ne ero scordato prima di lanciare), aggiorno Firebase per salvarmi in extremis!
    if (myHand.length == 1 && widget.roomId != "solo") {
      _gameRef.child('players/$myPlayerId/unoSafe').set(true);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("URLE: ${widget.battleCry}!!!"), backgroundColor: Colors.amber)
    );
  }

  void _catchOpponent() async {
    if (widget.roomId == "solo") return;
    if (opponentHandCount == 1 && !opponentSafe) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PRESO! L'avversario pesca 2 carte!"), backgroundColor: Colors.red));
      String oppId = (myPlayerId == "player1") ? "player2" : "player1";
      DataSnapshot snap = await _gameRef.child('players/$oppId/hand').get();
      List<AnimeCard> oppHandData = [];
      if (snap.exists && snap.value != null) oppHandData = (snap.value as List).map((c) => AnimeCard.fromJson(c as Map)).toList();
      
      for (int i = 0; i < 2; i++) {
         if (drawPile.isEmpty) drawPile = _generateDeck()..shuffle();
         oppHandData.add(drawPile.removeLast());
      }
      await _gameRef.update({
        'players/$oppId/hand': oppHandData.map((c) => c.toJson()).toList(),
        'players/$oppId/unoSafe': true,
        'drawPile': drawPile.map((c) => c.toJson()).toList(),
        'lastActionTime': ServerValue.timestamp, 
      });
    }
  }

  void _startTimer() {
    _turnTimer?.cancel();
    _secondsLeft = 15;
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else if (currentTurnId == myPlayerId) {
          t.cancel();
          drawCard(); 
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isMyTurn = currentTurnId == myPlayerId;
    
    // --- LOGICA PULSANTE ULTIMATE INTELLIGENTE ---
    bool canPlayAnyCard = lastPlayedCard != null && myHand.any((c) => c.canBePlayedOn(lastPlayedCard));
    // Compare SOLO se ho 2 carte e posso giocarne una, OPPURE se ho 1 carta in mano e me ne ero scordato
    bool showShout = (myHand.length == 2 && canPlayAnyCard) || myHand.length == 1; 

    // --- LOGICA PULSANTE CONTESTA ---
    bool showCatch = opponentHandCount == 1 && !opponentSafe && widget.roomId != "solo";

    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      appBar: AppBar(
        backgroundColor: isMyTurn ? Colors.greenAccent.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              isMyTurn ? "🔥 TOCCA A TE! 🔥" : "⏳ TURNO AVVERSARIO ⏳",
              style: TextStyle(
                color: isMyTurn ? Colors.greenAccent : Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              "Stanza: ${widget.roomId}",
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildArea("AVVERSARIO", opponentHand, true),
            
            if (showCatch)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: _catchOpponent,
                  icon: const Icon(Icons.warning, color: Colors.white),
                  label: const Text("CONTESTA!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                ),
              ),

            const Spacer(),
            _buildCenterTable(),
            const Spacer(),
            
            if (showShout)
              ElevatedButton(
                onPressed: _hasShoutedBattleCry ? null : _shoutBattleCry, // Si disattiva se l'hai già premuto
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasShoutedBattleCry ? Colors.grey : Colors.amber, 
                  shape: const StadiumBorder()
                ),
                child: Text("${widget.battleCry}!", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),

            _buildPlayerArea(isMyTurn),
          ],
        ),
      ),
    );
  }

  Widget _buildArea(String label, List hand, bool isOpponent) {
    return Column(children: [
      Text("$label (${hand.length})", style: const TextStyle(color: Colors.white54)),
      SizedBox(height: 80, child: ListView.builder(
        scrollDirection: Axis.horizontal, 
        itemCount: hand.length, 
        itemBuilder: (c, i) => _cardBack())),
    ]);
  }

  Widget _buildCenterTable() => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
    GestureDetector(onTap: drawCard, child: _cardBack(isDeck: true)),
    const SizedBox(width: 40),
    if (lastPlayedCard != null) _cardFront(lastPlayedCard!),
  ]);

  Widget _buildPlayerArea(bool isMyTurn) => Column(children: [
    Text("TEMPO: $_secondsLeft", style: TextStyle(color: isMyTurn ? Colors.greenAccent : Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
    SizedBox(height: 150, child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: myHand.length,
      itemBuilder: (c, i) => GestureDetector(onTap: () => playCard(i), child: _cardFront(myHand[i])),
    )),
  ]);

  Widget _cardFront(AnimeCard card) => Container(
    width: 80, height: 120, margin: const EdgeInsets.all(4),
    decoration: BoxDecoration(color: card.color, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white, width: 2)),
    child: Center(child: Text(card.value, style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold))),
  );

  Widget _cardBack({bool isDeck = false}) => Container(
    width: 80, height: 120, margin: const EdgeInsets.all(4),
    decoration: BoxDecoration(color: Colors.indigo.shade900, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.cyanAccent)),
    child: Center(child: Text(isDeck ? "DRAW" : "UNO", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
  );

  Future<Color?> _showColorPicker() async => await showDialog<Color>(
    context: context,
    builder: (c) => SimpleDialog(
      title: const Text("Scegli Colore"), 
      children: [Colors.red, Colors.blue, Colors.green, Colors.amber].map((color) => 
      SimpleDialogOption(onPressed: () => Navigator.pop(c, color), child: Container(height: 40, color: color))).toList()),
  );

  // --- NUOVA SCHERMATA FINALE EPICA ---
  void _showEndGame(bool iWon, String winnerName) {
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (c) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: iWon ? [Colors.green.shade900, Colors.black] : [Colors.red.shade900, Colors.black],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: iWon ? Colors.greenAccent : Colors.redAccent, width: 2)
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iWon ? Icons.emoji_events : Icons.sentiment_very_dissatisfied, size: 80, color: iWon ? Colors.amber : Colors.grey),
              const SizedBox(height: 20),
              Text(
                iWon ? "VITTORIA!" : "SCONFITTA", 
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: iWon ? Colors.greenAccent : Colors.redAccent, letterSpacing: 2)
              ),
              const SizedBox(height: 10),
              Text(
                iWon ? "Hai dominato la battaglia!" : "La vittoria va a $winnerName...", 
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: iWon ? Colors.greenAccent : Colors.redAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                ),
                onPressed: () {
                  Navigator.pop(c);
                  Navigator.pop(context); // Torna alla home
                }, 
                child: const Text("ESCI DALLA STANZA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
              )
            ],
          ),
        )
      )
    );
  }
}