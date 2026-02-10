import 'package:flutter/material.dart';

enum CardType { normal, special, wild }
enum SpecialPower { none, skip, drawTwo, wildDrawFour, changeColor, ultimate }

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

  bool canBePlayedOn(AnimeCard? lastCard) {
    if (lastCard == null) return true;
    // La carta nera (Wild o Ultimate) va su tutto
    if (color.value == Colors.black.value) return true;
    return color.value == lastCard.color.value || value == lastCard.value;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'color': color.value,
    'value': value,
    'type': type.index,
    'power': power.index,
  };

  factory AnimeCard.fromJson(Map<dynamic, dynamic> json) => AnimeCard(
    name: json['name'] as String? ?? "",
    color: Color(json['color'] as int? ?? 0xFF000000),
    value: json['value'] as String? ?? "",
    type: CardType.values[json['type'] as int? ?? 0],
    power: SpecialPower.values[json['power'] as int? ?? 0],
  );
}