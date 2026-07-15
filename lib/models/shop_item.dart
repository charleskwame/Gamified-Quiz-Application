import 'package:flutter/material.dart';

/// Represents a purchasable item in the quiz shop.
class ShopItem {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final int price;

  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.price,
  });

  /// List of placeholder shop items available for display.
  static const List<ShopItem> placeholderItems = [
    ShopItem(
      id: 'shield',
      name: 'Shield',
      description: 'Protects you from one wrong answer penalty',
      icon: Icons.shield_rounded,
      color: Color(0xFF808080),
      price: 50,
    ),
    ShopItem(
      id: 'skip_question',
      name: 'Skip Question',
      description: 'Skip a difficult question without penalty',
      icon: Icons.skip_next_rounded,
      color: Color(0xFF9E9E9E),
      price: 50,
    ),
    ShopItem(
      id: 'no_deductions',
      name: 'No Deductions',
      description: 'Negates all point deductions for one quiz',
      icon: Icons.block_rounded,
      color: Color(0xFFB0B0B0),
      price: 75,
    ),
  ];
}
