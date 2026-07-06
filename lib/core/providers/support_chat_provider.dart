import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ──────────────────────────────────────────────────────────────────
// Firestore data model
// ──────────────────────────────────────────────────────────────────

enum MessageSender { user, support }

class SupportMessage {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final bool isRead;

  const SupportMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.isRead = false,
  });

  factory SupportMessage.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return SupportMessage(
      id: doc.id,
      text: data['text'] as String? ?? '',
      sender: (data['sender'] as String?) == 'support'
          ? MessageSender.support
          : MessageSender.user,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'text': text,
        'sender': sender == MessageSender.support ? 'support' : 'user',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': isRead,
      };
}

// ──────────────────────────────────────────────────────────────────
// Firestore chat service
//
// Firestore structure:
//   support_chats/{chatId}/messages/{messageId}
//   support_chats/{chatId}  → { userId, userName, lastMessage,
//                               lastMessageAt, status, unreadBySupport }
// ──────────────────────────────────────────────────────────────────

class SupportChatService {
  final FirebaseFirestore _db;

  SupportChatService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _db.collection('support_chats');

  CollectionReference<Map<String, dynamic>> _messages(String chatId) =>
      _chats.doc(chatId).collection('messages');

  /// Ensures a chat document exists for [userId] and returns its ID.
  Future<String> ensureChatSession({
    required String userId,
    required String userName,
  }) async {
    // Re-use existing open session if present.
    final existing = await _chats
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'open')
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return existing.docs.first.id;

    final ref = await _chats.add({
      'userId': userId,
      'userName': userName,
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'status': 'open',
      'unreadBySupport': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Real-time stream of messages, ordered by time ascending.
  Stream<List<SupportMessage>> messagesStream(String chatId) {
    return _messages(chatId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => SupportMessage.fromFirestore(
                d as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  /// Sends a user message and updates the chat document.
  Future<void> sendUserMessage({
    required String chatId,
    required String text,
  }) async {
    final batch = _db.batch();

    final msgRef = _messages(chatId).doc();
    batch.set(msgRef, {
      'text': text,
      'sender': 'user',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    batch.update(_chats.doc(chatId), {
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadBySupport': FieldValue.increment(1),
    });

    await batch.commit();
  }

  /// Sends an automated bot response after a short delay.
  Future<void> sendBotMessage({
    required String chatId,
    required String text,
  }) async {
    await _messages(chatId).add({
      'text': text,
      'sender': 'support',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': true,
    });
    await _chats.doc(chatId).update({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  }
}

// ──────────────────────────────────────────────────────────────────
// Providers
// ──────────────────────────────────────────────────────────────────

final supportChatServiceProvider = Provider<SupportChatService>((_) {
  return SupportChatService();
});

/// Resolves (or creates) the chat session ID for the current user.
/// Pass the user's Supabase ID + display name.
final supportChatSessionProvider =
    FutureProvider.family<String, ({String userId, String userName})>(
        (ref, args) async {
  final service = ref.read(supportChatServiceProvider);
  return service.ensureChatSession(
    userId: args.userId,
    userName: args.userName,
  );
});

/// Live message stream for a given chatId.
final supportMessagesProvider =
    StreamProvider.family<List<SupportMessage>, String>((ref, chatId) {
  final service = ref.read(supportChatServiceProvider);
  return service.messagesStream(chatId);
});
