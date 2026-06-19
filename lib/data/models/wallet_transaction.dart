import 'package:flutter/foundation.dart';

@immutable
class WalletTransaction {
  final String id;
  final String walletId;
  final String type; // 'earned' or 'redeemed'
  final int amount;
  final String? note;
  final String? cyberName;
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    this.note,
    this.cyberName,
    required this.createdAt,
  });

  factory WalletTransaction.fromMap(Map<String, dynamic> map) {
    return WalletTransaction(
      id: map['id'] as String,
      walletId: map['wallet_id'] as String,
      type: map['type'] as String,
      amount: (map['amount'] as num).toInt(),
      note: map['note'] as String?,
      cyberName: map['cyber_name'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'wallet_id': walletId,
      'type': type,
      'amount': amount,
      'note': note,
      'cyber_name': cyberName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
