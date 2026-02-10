import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'models.dart';

class GameTableScreen extends StatefulWidget {
  final String roomId;
  final String universe;
  final String battleCry;
  final String characterGifUrl;

  const GameTableScreen({
    super.key,
    required this.roomId,
    required this.universe,
    required this.battleCry,
    required this.characterGifUrl,
  });

  @override
  State<GameTableScreen> createState() => _GameTableScreenState();
}


class _GameTableScreenState extends State<GameTableScreen> {

  List<AnimeCard> _generateDeck() {
  List<AnimeCard> deck = [];
  List<Color> colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow];

  for (var color in colors) {
    // Carte numeriche da 0 a 9
    for (int i = 0; i <= 9; i++) {
      deck.add(AnimeCard(
        name: "Card $i",
        color: color,
        value: i.toString(),
        type: CardType.normal,
      ));
    }
    // Carte Speciali: Salta Turno (Ø)
    deck.add(AnimeCard(
      name: "Skip",
      color: color,
      value: "Ø",
      type: CardType.special,
      power: SpecialPower.skip,
    ));
    // Carte Speciali: Pesca Due (+2)
    deck.add(AnimeCard(
      name: "Draw Two",
      color: color,
      value: "+2",
      type: CardType.special,
      power: SpecialPower.drawTwo,
    ));
  }

  // Carte Nere (Wild)
  for (int i = 0; i < 4; i++) {
    // Cambio Colore (W)
    deck.add(AnimeCard(
      name: "Wild",
      color: Colors.black,
      value: "W",
      type: CardType.wild,
      power: SpecialPower.changeColor,
    ));
    // Pesca Quattro (+4)
    deck.add(AnimeCard(
      name: "Wild Draw Four",
      color: Colors.black,
      value: "+4",
      type: CardType.wild,
      power: SpecialPower.wildDrawFour,
    ));
  }

  deck.shuffle(); // Mescola il mazzo
  return deck;
}
  late DatabaseReference _gameRef;
  StreamSubscription? _gameSubscription;

  List<AnimeCard> myHand = [];
  List<AnimeCard> opponentHand = [];
  List<AnimeCard> drawPile = [];
  AnimeCard? lastPlayedCard;
  
  String currentTurnId = ""; 
  String myPlayerId = "";    
  bool isHost = false;
  bool _ultimateShouted = false;

  // Timer e Stato Locale
  Timer? _turnTimer;
  int _secondsLeft = 15;

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

  // --- INIZIALIZZAZIONE ---

  Future<void> _setupGame() async {
    if (widget.roomId == "solo") {
      myPlayerId = "player1";
      currentTurnId = "player1";
      _setupLocalGame();
    } else {
      await _setupMultiplayer();
    }
    _startTimer();
  }

  void _setupLocalGame() {
    drawPile = _generateDeck();
    myHand = List.generate(7, (_) => drawPile.removeLast());
    opponentHand = List.generate(7, (_) => drawPile.removeLast());
    lastPlayedCard = drawPile.firstWhere((c) => c.type == CardType.normal);
    drawPile.remove(lastPlayedCard);
    setState(() {});
  }

  Future<void> _setupMultiplayer() async {
    DataSnapshot snapshot = await _gameRef.get();
    if (!snapshot.exists) {
      isHost = true;
      myPlayerId = "player1";
      _createMatchOnFirebase();
    } else {
      isHost = false;
      myPlayerId = "player2";
    }

    _gameSubscription = _gameRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return;
      if (!mounted) return;

      setState(() {
        currentTurnId = data['turn'] ?? "player1";
        if (data['lastPlayedCard'] != null) {
          lastPlayedCard = AnimeCard.fromJson(data['lastPlayedCard']);
        }
        if (data['drawPile'] != null) {
          drawPile = (data['drawPile'] as List).map((c) => AnimeCard.fromJson(c)).toList();
        }

        var players = data['players'] as Map?;
        if (players != null) {
          var myData = players[myPlayerId] as Map?;
          if (myData != null && myData['hand'] != null) {
            myHand = (myData['hand'] as List).map((c) => AnimeCard.fromJson(c)).toList();
          }
          String oppId = (myPlayerId == "player1") ? "player2" : "player1";
          var oppData = players[oppId] as Map?;
          if (oppData != null && oppData['hand'] != null) {
            opponentHand = List.generate((oppData['hand'] as List).length, (_) => AnimeCard(name: "", color: Colors.grey, value: ""));
          }
        }
      });
      _startTimer();
    });
  }

  void _createMatchOnFirebase() {
    List<AnimeCard> fullDeck = _generateDeck();
    List<AnimeCard> p1Hand = List.generate(7, (_) => fullDeck.removeLast());
    List<AnimeCard> p2Hand = List.generate(7, (_) => fullDeck.removeLast());
    AnimeCard firstCard = fullDeck.firstWhere((c) => c.type == CardType.normal);
    fullDeck.remove(firstCard);

    _gameRef.set({
      'turn': 'player1',
      'lastPlayedCard': firstCard.toJson(),
      'drawPile': fullDeck.map((c) => c.toJson()).toList(),
      'players': {
        'player1': {'hand': p1Hand.map((c) => c.toJson()).toList()},
        'player2': {'hand': p2Hand.map((c) => c.toJson()).toList()},
      }
    });
  }

  // --- LOGICA DI GIOCO ---

  void playCard(int index) async {
    if (currentTurnId != myPlayerId) return;

    AnimeCard selected = myHand[index];
    if (selected.canBePlayedOn(lastPlayedCard)) {
      _turnTimer?.cancel();
      Color? newColor;
      if (selected.color == Colors.black) {
        newColor = await _showColorPicker();
        if (newColor == null) { _startTimer(); return; }
        selected.color = newColor;
      }

      myHand.removeAt(index);
      String nextTurn = (selected.power == SpecialPower.skip) ? myPlayerId : (myPlayerId == "player1" ? "player2" : "player1");

      if (widget.roomId == "solo") {
        setState(() {
          lastPlayedCard = selected;
          _applyPower(selected.power, false);
          currentTurnId = nextTurn;
          if (myHand.isEmpty) _showEndGame("HAI VINTO!");
          else if (currentTurnId == "player2") _botTurn();
        });
      } else {
        if (selected.power == SpecialPower.drawTwo || selected.power == SpecialPower.wildDrawFour) {
          await _applyPowerToOpponent(selected.power);
        }
        await _gameRef.update({
          'lastPlayedCard': selected.toJson(),
          'turn': nextTurn,
          'players/$myPlayerId/hand': myHand.map((c) => c.toJson()).toList(),
        });
        if (myHand.isEmpty) _showEndGame("HAI VINTO!");
      }
    }
  }

  void drawCard() async {
    if (currentTurnId != myPlayerId || drawPile.isEmpty) return;
if (drawPile.isEmpty) {
    // Logica di emergenza: se il mazzo è vuoto, rigeneralo o rimescola gli scarti
    // Per ora, rigeneriamo un mazzo per non bloccare il gioco
    drawPile = _generateDeck(); 
  }
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
        'turn': nextTurn,
      });
    }
  }

  void _applyPower(SpecialPower p, bool isBotTarget) {
    int cards = (p == SpecialPower.drawTwo) ? 2 : (p == SpecialPower.wildDrawFour ? 4 : 0);
    for (int i = 0; i < cards; i++) {
      if (drawPile.isNotEmpty) {
        if (isBotTarget) myHand.add(drawPile.removeLast());
        else opponentHand.add(drawPile.removeLast());
      }
    }
  }

  Future<void> _applyPowerToOpponent(SpecialPower power) async {
    String oppId = (myPlayerId == "player1") ? "player2" : "player1";
    int count = (power == SpecialPower.drawTwo) ? 2 : 4;
    DataSnapshot snap = await _gameRef.child('players/$oppId/hand').get();
    List hand = List.from(snap.value as List? ?? []);
    for (int i = 0; i < count; i++) {
      if (drawPile.isNotEmpty) hand.add(drawPile.removeLast().toJson());
    }
    await _gameRef.update({
      'drawPile': drawPile.map((c) => c.toJson()).toList(),
      'players/$oppId/hand': hand,
    });
  }

  void _startTimer() {
    _turnTimer?.cancel();
    _secondsLeft = 15;
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) _secondsLeft--;
        else if (currentTurnId == myPlayerId) drawCard();
      });
    });
  }

  // --- BOT LOGIC ---
  void _botTurn() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted || currentTurnId != "player2") return;
    int idx = _calculateBestBotMove();
    setState(() {
      if (idx != -1) {
        AnimeCard c = opponentHand.removeAt(idx);
        if (c.color == Colors.black) c.color = _getBestColorForBot();
        lastPlayedCard = c;
        _applyPower(c.power, true);
        currentTurnId = (c.power == SpecialPower.skip) ? "player2" : "player1";
        if (opponentHand.isEmpty) _showEndGame("IL BOT HA VINTO!");
        else if (currentTurnId == "player2") _botTurn();
      } else {
        if (drawPile.isNotEmpty) opponentHand.add(drawPile.removeLast());
        currentTurnId = "player1";
      }
      _startTimer();
    });
  }

  int _calculateBestBotMove() => opponentHand.indexWhere((c) => c.canBePlayedOn(lastPlayedCard));
  Color _getBestColorForBot() => Colors.red;

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    bool isMyTurn = currentTurnId == myPlayerId;
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      appBar: AppBar(title: Text("Stanza: ${widget.roomId}"), backgroundColor: Colors.transparent),
      body: SafeArea(
        child: Column(
          children: [
            _buildArea("AVVERSARIO", opponentHand, true),
            const Spacer(),
            _buildCenterTable(),
            const Spacer(),
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
    Text("TEMPO: $_secondsLeft", style: TextStyle(color: isMyTurn ? Colors.cyanAccent : Colors.red)),
    SizedBox(height: 150, child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: myHand.length,
      itemBuilder: (c, i) => GestureDetector(onTap: () => playCard(i), child: _cardFront(myHand[i])),
    )),
    ElevatedButton(onPressed: _ultimateShouted ? null : () {
      setState(() => _ultimateShouted = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.battleCry)));
    }, child: const Text("ULTIMATE")),
  ]);

  Widget _cardFront(AnimeCard card) => Container(
    width: 80, height: 120, margin: const EdgeInsets.all(4),
    decoration: BoxDecoration(color: card.color, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white, width: 2)),
    child: Center(child: Text(card.value, style: const TextStyle(fontSize: 24, color: Colors.white))),
  );

  Widget _cardBack({bool isDeck = false}) => Container(
    width: 80, height: 120, margin: const EdgeInsets.all(4),
    decoration: BoxDecoration(color: Colors.indigo.shade900, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.cyanAccent)),
    child: Center(child: Text(isDeck ? "DRAW" : "UNO", style: const TextStyle(color: Colors.white, fontSize: 10))),
  );

  Future<Color?> _showColorPicker() async => await showDialog<Color>(
    context: context,
    builder: (c) => SimpleDialog(title: const Text("Scegli Colore"), children: [Colors.red, Colors.blue, Colors.green, Colors.yellow].map((color) => 
      SimpleDialogOption(onPressed: () => Navigator.pop(c, color), child: Container(height: 40, color: color))).toList()),
  );

  void _showEndGame(String msg) => showDialog(context: context, builder: (c) => AlertDialog(title: Text(msg))).then((_) => Navigator.pop(context));
}