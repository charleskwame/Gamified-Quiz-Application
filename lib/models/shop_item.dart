import 'package:flutter/material.dart';

/// Represents a purchasable item in the quiz shop.
class ShopItem {
  final String id;
  final String name;
  final String description;
  final String iconAsset;
  final Color color;
  final int price;

  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.iconAsset,
    required this.color,
    required this.price,
  });

  /// List of placeholder shop items available for display.
  static const List<ShopItem> placeholderItems = [
    ShopItem(
      id: 'shield',
      name: 'Shield',
      description: 'Protects you from one wrong answer penalty',
      iconAsset: 'lib/assets/icon/shield.svg',
      color: Color(0xFF6366F1),
      price: 50,
    ),
    ShopItem(
      id: 'skip_question',
      name: 'Skip Question',
      description: 'Skip a difficult question without penalty',
      iconAsset: 'lib/assets/icon/skip.svg',
      color: Color(0xFF4ADE80),
      price: 50,
    ),
    ShopItem(
      id: 'no_deductions',
      name: 'No Deductions',
      description: 'Negates all point deductions for one quiz',
      iconAsset: 'lib/assets/icon/no-deductions.svg',
      color: Color(0xFFF59E0B),
      price: 75,
    ),
    ShopItem(
      id: 'pause_timer',
      name: 'Pause Timer',
      description: 'Pauses the quiz timer to give yourself more time',
      iconAsset: 'lib/assets/icon/pause.svg',
      color: Color(0xFF8B5CF6),
      price: 80,
    ),
  ];
}
