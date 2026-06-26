import 'package:flutter/material.dart';

class RoomOptionDef {
  final String id;
  final String dbType;
  final String labelKey;
  final IconData icon;
  final double defaultPrice;

  const RoomOptionDef({
    required this.id,
    required this.dbType,
    required this.labelKey,
    required this.icon,
    required this.defaultPrice,
  });
}

const roomOptions = [
  RoomOptionDef(
    id: 'ps5',
    dbType: 'ps5',
    labelKey: 'owner_onboarding.room_ps5',
    icon: Icons.sports_esports,
    defaultPrice: 80,
  ),
  RoomOptionDef(
    id: 'ps4',
    dbType: 'ps5',
    labelKey: 'owner_onboarding.room_ps4',
    icon: Icons.videogame_asset,
    defaultPrice: 60,
  ),
  RoomOptionDef(
    id: 'pc',
    dbType: 'pc',
    labelKey: 'owner_onboarding.room_pc',
    icon: Icons.computer,
    defaultPrice: 50,
  ),
  RoomOptionDef(
    id: 'vip',
    dbType: 'vip',
    labelKey: 'owner_onboarding.room_vip',
    icon: Icons.star,
    defaultPrice: 120,
  ),
];
