import 'package:flutter/material.dart';

enum CardType { normal, special, wild }
enum SpecialPower { none, skip, drawTwo, wildDrawFour, changeColor }

class AnimeCard {
  final String name;
  Color color;
  final String value;
  final CardType type;
  final SpecialPower power;

  AnimeCard({
    required this.name,
    required this.color,
    required this.value,
    this.type = CardType.normal,
    this.power = SpecialPower.none,
  });

  // Per giocare una carta sopra un'altra
  bool canBePlayedOn(AnimeCard? lastCard) {
    if (lastCard == null) return true;
    return color == Colors.black || color == lastCard.color || value == lastCard.value;
  }

  // Conversione per Firebase
  Map<String, dynamic> toJson() => {
    'name': name,
    'color': color.value,
    'value': value,
    'type': type.index,
    'power': power.index,
  };

  factory AnimeCard.fromJson(Map<dynamic, dynamic> json) => AnimeCard(
    name: json['name'],
    color: Color(json['color']),
    value: json['value'],
    type: CardType.values[json['type']],
    power: SpecialPower.values[json['power']],
  );
}