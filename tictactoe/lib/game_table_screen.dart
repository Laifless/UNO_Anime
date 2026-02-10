import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'models.dart';
import 'end_game_screen.dart';

class GameTableScreen extends StatefulWidget {
  final String roomId, universe, battleCry, characterGifUrl, username;
  final bool isHost;

  const GameTableScreen({
    super.key,
    required this.roomId,
    required this.universe,
    required this.battleCry,
    required this.characterGifUrl,
    required this.username,
    required this.isHost,
  });

  @override
  State<GameTableScreen> createState() => _GameTableScreenState();
}

class _GameTableScreenState extends State<GameTableScreen> {
  late DatabaseReference _gameRef;
  StreamSubscription? _sub;
  
  List<AnimeCard> myHand = [], drawPile = [];
  AnimeCard? lastPlayedCard;
  String currentTurnId = "player1"; 
  String myPlayerId = "";
  bool _gameFinished = false;
  
  // STATO PER UNO/BATTLE CRY
  int opponentHandCount = 7;
  bool opponentSafe = true;

  @override
  void initState() {
    super.initState();
    _gameRef = FirebaseDatabase.instance.ref('rooms/${widget.roomId}');
    myPlayerId = widget.isHost ? "player1" : "player2";
    if (widget.isHost) _initFirebaseData();
    _listenToGame();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _listenToGame() {
    _sub = _gameRef.onValue.listen((event) {
      if (!mounted || event.snapshot.value == null) return;
      final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);

      if (data['status'] == 'finished' && !_gameFinished) {
         _gameFinished = true;
         String winner = data['winner'] ?? "";
         Navigator.pushReplacement(
           context, 
           MaterialPageRoute(builder: (c) => EndGameScreen(isVictory: winner == widget.username, winnerName: winner))
         );
         return;
      }

      setState(() {
        currentTurnId = data['turn']?.toString() ?? "player1";
        
        if (data['lastPlayedCard'] != null) lastPlayedCard = AnimeCard.fromJson(data['lastPlayedCard']);
        if (data['drawPile'] != null) drawPile = (data['drawPile'] as List).map((c) => AnimeCard.fromJson(c)).toList();

        var playersData = data['players'] as Map?;
        if (playersData != null) {
           // Mia mano
           if (playersData[myPlayerId] != null) {
             var handData = playersData[myPlayerId]['hand'] as List?;
             myHand = handData != null ? handData.map((c) => AnimeCard.fromJson(c)).toList() : [];
           }
           // Avversario (per controlli UNO)
           String oppId = (myPlayerId == "player1") ? "player2" : "player1";
           if (playersData[oppId] != null) {
             var oppData = playersData[oppId] as Map;
             var oppHandList = oppData['hand'] as List?;
             opponentHandCount = oppHandList?.length ?? 0;
             opponentSafe = oppData['unoSafe'] ?? true;
           }
        }
      });
    });
  }

  void _initFirebaseData() async {
    DataSnapshot check = await _gameRef.child('drawPile').get();
    if (check.exists) return;

    List<AnimeCard> deck = _generateDeck();
    deck.shuffle();
    List<AnimeCard> p1 = [], p2 = [];
    for(int i=0; i<7; i++) p1.add(deck.removeLast());
    for(int i=0; i<7; i++) p2.add(deck.removeLast());
    AnimeCard first = deck.removeLast();
    while (first.type != CardType.normal) {
      deck.insert(0, first);
      first = deck.removeLast();
    }

    await _gameRef.update({
      'turn': 'player1',
      'lastPlayedCard': first.toJson(),
      'drawPile': deck.map((c) => c.toJson()).toList(),
      'players': {
        'player1': {'hand': p1.map((c) => c.toJson()).toList(), 'unoSafe': true},
        'player2': {'hand': p2.map((c) => c.toJson()).toList(), 'unoSafe': true},
      },
    });
  }

  void playCard(int index) async {
    if (currentTurnId != myPlayerId) return;
    AnimeCard selected = myHand[index];
    
    if (selected.canBePlayedOn(lastPlayedCard)) {
      if (selected.color.value == Colors.black.value) {
        Color? newColor = await _showColorPicker();
        if (newColor == null) return;
        selected.color = newColor;
      }

      myHand.removeAt(index);
      if (myHand.isEmpty) {
        await _gameRef.update({'status': 'finished', 'winner': widget.username});
        return;
      }

      Map<String, dynamic> updates = {};
      updates['lastPlayedCard'] = selected.toJson();
      updates['players/$myPlayerId/hand'] = myHand.map((c) => c.toJson()).toList();
      
      // UNO Safe logic
      if (myHand.length == 1) updates['players/$myPlayerId/unoSafe'] = false;
      else updates['players/$myPlayerId/unoSafe'] = true;

      bool skipTurn = false;
      int cardsToDraw = 0;

      if (selected.power == SpecialPower.drawTwo) {
        cardsToDraw = 2; skipTurn = true;
      } else if (selected.power == SpecialPower.wildDrawFour) {
        cardsToDraw = 4; skipTurn = true;
      } else if (selected.power == SpecialPower.ultimate) {
        cardsToDraw = 6; skipTurn = true;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("ULTIMATE ATTIVATA!")));
      } else if (selected.power == SpecialPower.skip) {
        skipTurn = true;
      }

      if (cardsToDraw > 0) {
        String oppId = (myPlayerId == "player1") ? "player2" : "player1";
        DataSnapshot snap = await _gameRef.child('players/$oppId/hand').get();
        List<AnimeCard> oppHand = [];
        if (snap.exists && snap.value != null) {
          oppHand = (snap.value as List).map((c) => AnimeCard.fromJson(c as Map)).toList();
        }
        for (int i = 0; i < cardsToDraw; i++) {
           if (drawPile.isEmpty) drawPile = _generateDeck()..shuffle();
           oppHand.add(drawPile.removeLast());
        }
        updates['players/$oppId/hand'] = oppHand.map((c) => c.toJson()).toList();
        updates['drawPile'] = drawPile.map((c) => c.toJson()).toList();
        updates['players/$oppId/unoSafe'] = true; 
      }

      String nextTurn = (myPlayerId == "player1") ? "player2" : "player1";
      updates['turn'] = skipTurn ? myPlayerId : nextTurn;

      await _gameRef.update(updates);
    }
  }

  void drawCard() async {
    if (currentTurnId != myPlayerId || drawPile.isEmpty) return;
    myHand.add(drawPile.removeLast());
    await _gameRef.update({
      'drawPile': drawPile.map((c) => c.toJson()).toList(),
      'players/$myPlayerId/hand': myHand.map((c) => c.toJson()).toList(),
      'players/$myPlayerId/unoSafe': true, 
      'turn': myPlayerId == "player1" ? "player2" : "player1",
    });
  }

  void _shoutUno() {
    if (myHand.length <= 2) {
      _gameRef.child('players/$myPlayerId/unoSafe').set(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("URLE: ${widget.battleCry}!!!"), backgroundColor: Colors.amber, duration: const Duration(seconds: 2))
      );
    }
  }

  void _catchOpponent() async {
    if (opponentHandCount == 1 && !opponentSafe) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PRESO! Pesca 2 carte!"), backgroundColor: Colors.red));
      String oppId = (myPlayerId == "player1") ? "player2" : "player1";
      DataSnapshot snap = await _gameRef.child('players/$oppId/hand').get();
      List<AnimeCard> oppHand = [];
      if (snap.exists && snap.value != null) {
        oppHand = (snap.value as List).map((c) => AnimeCard.fromJson(c as Map)).toList();
      }
      for (int i = 0; i < 2; i++) {
         if (drawPile.isEmpty) drawPile = _generateDeck()..shuffle();
         oppHand.add(drawPile.removeLast());
      }
      await _gameRef.update({
        'players/$oppId/hand': oppHand.map((c) => c.toJson()).toList(),
        'players/$oppId/unoSafe': true,
        'drawPile': drawPile.map((c) => c.toJson()).toList(),
      });
    }
  }

  Future<Color?> _showColorPicker() async {
    return await showDialog<Color>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SimpleDialog(
        title: const Text("Scegli Colore Chakra"),
        children: [Colors.red, Colors.blue, Colors.green, Colors.amber].map((c) => 
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, c),
            child: Container(height: 40, color: c, margin: const EdgeInsets.symmetric(vertical: 4)),
          )
        ).toList(),
      ),
    );
  }

  List<AnimeCard> _generateDeck() {
    List<AnimeCard> d = [];
    List<Color> colors = [Colors.red, Colors.blue, Colors.green, Colors.amber]; // Ambra invece di giallo
    for (var c in colors) {
      for (int i = 0; i <= 9; i++) {
        d.add(AnimeCard(name: "$i", color: c, value: i.toString()));
        if (i != 0) d.add(AnimeCard(name: "$i", color: c, value: i.toString()));
      }
      for(int i=0; i<2; i++) {
        d.add(AnimeCard(name: "Skip", color: c, value: "🚫", type: CardType.special, power: SpecialPower.skip));
        d.add(AnimeCard(name: "+2", color: c, value: "+2", type: CardType.special, power: SpecialPower.drawTwo));
      }
    }
    for(int i=0; i<4; i++) {
      d.add(AnimeCard(name: "Wild", color: Colors.black, value: "🌈", type: CardType.wild, power: SpecialPower.changeColor));
      d.add(AnimeCard(name: "+4", color: Colors.black, value: "+4", type: CardType.wild, power: SpecialPower.wildDrawFour));
    }
    d.add(AnimeCard(name: "ULT", color: Colors.black, value: "⚡", type: CardType.wild, power: SpecialPower.ultimate));
    d.add(AnimeCard(name: "ULT", color: Colors.black, value: "⚡", type: CardType.wild, power: SpecialPower.ultimate));
    return d;
  }

  @override
  Widget build(BuildContext context) {
    bool isMyTurn = currentTurnId == myPlayerId;
    bool showShout = myHand.length <= 2; 
    bool showCatch = opponentHandCount == 1 && !opponentSafe;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(isMyTurn ? "TOCCA A TE" : "TURNO AVVERSARIO"),
        backgroundColor: isMyTurn ? Colors.amber[800] : Colors.grey[900],
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          if (showCatch)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: _catchOpponent,
              icon: const Icon(Icons.warning, color: Colors.white),
              label: const Text("CONTESTA!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
            ),

          if (lastPlayedCard != null) _cardUI(lastPlayedCard!, true) else const CircularProgressIndicator(),
          const Spacer(),

          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text("Deck: ${drawPile.length}", style: const TextStyle(color: Colors.white54)),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: isMyTurn ? drawCard : null,
              style: ElevatedButton.styleFrom(backgroundColor: isMyTurn ? Colors.green : Colors.grey),
              child: const Text("PESCA"),
            ),
            const SizedBox(width: 20),
            if (showShout)
              ElevatedButton(
                onPressed: _shoutUno,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, shape: const StadiumBorder()),
                child: Text("${widget.battleCry}!", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
          ]),
          
          const SizedBox(height: 20),
          SizedBox(height: 160, child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: myHand.length,
            itemBuilder: (c, i) => GestureDetector(onTap: () => playCard(i), child: _cardUI(myHand[i], false)),
          ))
        ],
      ),
    );
  }

  Widget _cardUI(AnimeCard c, bool big) {
    return Container(
      width: big?100:85, height: big?150:130, margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: c.color, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white)),
      child: Center(child: Text(c.value, style: TextStyle(fontSize: big?36:22, fontWeight: FontWeight.bold, color: Colors.white))),
    );
  }
}