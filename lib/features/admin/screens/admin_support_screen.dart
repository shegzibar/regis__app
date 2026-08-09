import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../bootstrap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/support_chat_provider.dart';
import '../../../data/models/user.dart';
import '../widgets/admin_user_bookings_sheet.dart';

class AdminSupportScreen extends ConsumerStatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  ConsumerState<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends ConsumerState<AdminSupportScreen> {
  String? _selectedChatId;

  @override
  Widget build(BuildContext context) {
    // If Firebase is not initialized, show a setup guide instead of crashing
    if (!firebaseIsReady) {
      return const _FirebaseNotConfiguredView();
    }

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Row(
        children: [
          // Left Pane: Chat List
          Container(
            width: 320,
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: AppColors.darkBorder, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'admin.support.title'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final chatsSnap = ref.watch(adminChatsProvider);

                      return chatsSnap.when(
                        data: (chats) {
                          if (chats.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.inbox_outlined,
                                    color: AppColors.textMuted,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'admin.support.no_chats'.tr(),
                                    style: const TextStyle(color: AppColors.textMuted),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: chats.length,
                            itemBuilder: (context, index) {
                              final chat = chats[index];
                              final isSelected = _selectedChatId == chat.id;

                              return _ChatTile(
                                chat: chat,
                                isSelected: isSelected,
                                onTap: () {
                                  setState(() => _selectedChatId = chat.id);
                                  if (chat.unreadBySupport > 0) {
                                    ref.read(supportChatServiceProvider).markAsRead(chat.id);
                                  }
                                },
                              );
                            },
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(color: AppColors.green),
                        ),
                        error: (err, _) => _FirebaseErrorView(error: err.toString()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Right Pane: Chat Messages
          Expanded(
            child: _selectedChatId == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.support_agent,
                          size: 64,
                          color: AppColors.textMuted.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'admin.support.select_chat'.tr(),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : _ChatDetailView(
                    chatId: _selectedChatId!,
                    onResolve: () {
                      ref
                          .read(supportChatServiceProvider)
                          .resolveChat(_selectedChatId!);
                      setState(() => _selectedChatId = null);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Firebase not configured helper view
// ─────────────────────────────────────────────────────────────────────────────

class _FirebaseNotConfiguredView extends StatelessWidget {
  const _FirebaseNotConfiguredView();

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('1. Create a Firebase project', 'Go to console.firebase.google.com and create a new project named "Forya".'),
      ('2. Add a Web/Android app', 'Register your app in the Firebase console and download the google-services.json (Android) or enable web support.'),
      ('3. Run FlutterFire CLI', 'Run: dart pub global activate flutterfire_cli\nThen: flutterfire configure'),
      ('4. This adds firebase_options.dart', 'FlutterFire will create lib/firebase_options.dart with your project credentials.'),
      ('5. Update bootstrap.dart', 'Call Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform) in initializeForya().'),
    ];

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Firebase is not configured for this platform.',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'CX Support requires Firebase Firestore to be set up. Follow these steps:',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 24),
              ...steps.map((step) => _SetupStep(title: step.$1, body: step.$2)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.terminal, color: AppColors.green, size: 18),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'flutterfire configure',
                        style: TextStyle(
                          color: AppColors.green,
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: AppColors.textMuted, size: 18),
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(text: 'flutterfire configure'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetupStep extends StatelessWidget {
  final String title;
  final String body;

  const _SetupStep({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: const BoxDecoration(
              color: AppColors.green,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Firestore error view
// ─────────────────────────────────────────────────────────────────────────────

class _FirebaseErrorView extends StatelessWidget {
  final String error;

  const _FirebaseErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, color: AppColors.textMuted, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Could not load chats',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat list tile
// ─────────────────────────────────────────────────────────────────────────────

class _ChatTile extends StatelessWidget {
  final SupportChatSession chat;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChatTile({
    required this.chat,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: isSelected
            ? AppColors.green.withValues(alpha: 0.1)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.green.withValues(alpha: 0.2),
              child: Text(
                chat.userName.isNotEmpty ? chat.userName[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: AppColors.green, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: chat.unreadBySupport > 0
                          ? Colors.white
                          : AppColors.textMuted,
                      fontWeight: chat.unreadBySupport > 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (chat.unreadBySupport > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${chat.unreadBySupport}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat detail (right pane)
// ─────────────────────────────────────────────────────────────────────────────

class _ChatDetailView extends ConsumerStatefulWidget {
  final String chatId;
  final VoidCallback onResolve;

  const _ChatDetailView({
    required this.chatId,
    required this.onResolve,
  });

  @override
  ConsumerState<_ChatDetailView> createState() => _ChatDetailViewState();
}

class _ChatDetailViewState extends ConsumerState<_ChatDetailView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    await ref.read(supportChatServiceProvider).sendAdminMessage(
          chatId: widget.chatId,
          text: text,
        );

    // Scroll to bottom after sending
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesSnap = ref.watch(supportMessagesProvider(widget.chatId));
    final chatsSnap = ref.watch(adminChatsProvider);
    final chat = chatsSnap.valueOrNull?.where((c) => c.id == widget.chatId).firstOrNull;

    return Column(
      children: [
        // Header
        Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: const BoxDecoration(
            border:
                Border(bottom: BorderSide(color: AppColors.darkBorder)),
          ),
          child: Row(
            children: [
              const Icon(Icons.chat_bubble_outline,
                  color: AppColors.green, size: 20),
              const SizedBox(width: 12),
              Text(
                'admin.support.title'.tr(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (chat != null)
                TextButton.icon(
                  onPressed: () {
                    // Build a basic user from the chat session — the sheet loads
                    // bookings and wallet data internally, so no async needed here.
                    final user = AppUser(
                      id: chat.userId,
                      name: chat.userName,
                      role: 'user',
                      createdAt: DateTime.now(),
                    );
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => AdminUserBookingsSheet(
                        user: user,
                        roleColor: AppColors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_outline, size: 18),
                  label: const Text('View Profile'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.green,
                  ),
                ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: widget.onResolve,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text('admin.support.resolve_chat'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Messages
        Expanded(
          child: messagesSnap.when(
            data: (messages) {
              if (messages.isEmpty) {
                return const Center(
                  child: Text(
                    'No messages yet.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                );
              }
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(24),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg.sender == MessageSender.support;

                  return Align(
                    alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 480),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isMe ? AppColors.green : AppColors.darkCard,
                        borderRadius: BorderRadius.circular(16).copyWith(
                          bottomRight: isMe
                              ? const Radius.circular(0)
                              : const Radius.circular(16),
                          bottomLeft: !isMe
                              ? const Radius.circular(0)
                              : const Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Text(
                              'User',
                              style: TextStyle(
                                color: AppColors.green.withValues(alpha: 0.8),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (!isMe) const SizedBox(height: 4),
                          Text(
                            msg.text,
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(msg.timestamp),
                            style: TextStyle(
                              color: isMe
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.green),
            ),
            error: (err, _) => _FirebaseErrorView(error: err.toString()),
          ),
        ),

        // Input
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.darkBorder)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'admin.support.type_message'.tr(),
                    hintStyle:
                        const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.darkCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 16),
              FloatingActionButton(
                onPressed: _sendMessage,
                backgroundColor: AppColors.green,
                elevation: 0,
                child: const Icon(Icons.send, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
