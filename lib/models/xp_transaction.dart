import 'dart:convert';
import 'package:crypto/crypto.dart';

enum XPSource {
  taskCompletion,
  streakBonus,
  achievementUnlock,
  focusSession,
  dailyPlanningBonus,
  migration,
  redeemCode,
}

class XPTransaction {
  final String id;
  final int amount;
  final XPSource source;
  final String? taskId;
    // null for non-task sources
  final String? achievementId;
  final DateTime earnedAt;
  final String signature;
    // HMAC-SHA256 of the transaction

  const XPTransaction({
    required this.id,
    required this.amount,
    required this.source,
    this.taskId,
    this.achievementId,
    required this.earnedAt,
    required this.signature,
  });

  // The signing secret — embedded in
  // code, not stored in data files
  // Attacker would need to decompile
  // the app to find this
  static const _signingSecret =
      'T4sk1_XP_S1gn1ng_K3y_v1_#\$%^&*';

  // Create a new signed transaction
  factory XPTransaction.create({
    required int amount,
    required XPSource source,
    String? taskId,
    String? achievementId,
  }) {
    final id = _generateId();
    final now = DateTime.now();
    final signature = _sign(
      id: id,
      amount: amount,
      source: source.name,
      taskId: taskId,
      earnedAt: now,
    );
    return XPTransaction(
      id: id,
      amount: amount,
      source: source,
      taskId: taskId,
      achievementId: achievementId,
      earnedAt: now,
      signature: signature,
    );
  }

  // Verify this transaction hasn't
  // been tampered with
  bool get isValid {
    final expected = _sign(
      id: id,
      amount: amount,
      source: source.name,
      taskId: taskId,
      earnedAt: earnedAt,
    );
    return signature == expected;
  }

  static String _sign({
    required String id,
    required int amount,
    required String source,
    String? taskId,
    required DateTime earnedAt,
  }) {
    // Build canonical string to sign
    final canonical =
        '$id|$amount|$source'
        '|${taskId ?? "none"}'
        '|${earnedAt.millisecondsSinceEpoch}'
        '|$_signingSecret';

    final bytes = utf8.encode(canonical);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static String _generateId() {
    final now = DateTime.now()
        .millisecondsSinceEpoch;
    final random = now ^
        now.hashCode ^
        0xDEADBEEF;
    return random.toRadixString(16);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'source': source.name,
    'taskId': taskId,
    'achievementId': achievementId,
    'earnedAt': earnedAt
        .millisecondsSinceEpoch,
    'signature': signature,
  };

  factory XPTransaction.fromJson(
      Map<String, dynamic> j) =>
    XPTransaction(
      id: j['id'] as String,
      amount: j['amount'] as int,
      source: XPSource.values.byName(
          j['source'] as String),
      taskId: j['taskId'] as String?,
      achievementId:
          j['achievementId'] as String?,
      earnedAt: DateTime
          .fromMillisecondsSinceEpoch(
          j['earnedAt'] as int),
      signature: j['signature'] as String,
    );
}
