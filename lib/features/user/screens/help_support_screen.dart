import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/support_chat_provider.dart';

// ──────────────────────────────────────────────
// Quick-reply topics (predefined FAQ chips)
// ──────────────────────────────────────────────

class _QuickReply {
  final String labelKey;
  final IconData icon;
  final String answerKey;

  const _QuickReply(
      {required this.labelKey, required this.icon, required this.answerKey});

  String get label => labelKey.tr();
  String get answer => answerKey.tr();
}

const _quickReplies = [
  _QuickReply(
    labelKey: 'help_support.quick_booking',
    icon: Icons.calendar_today_outlined,
    answerKey: 'help_support.ans_booking',
  ),
  _QuickReply(
    labelKey: 'help_support.quick_payment',
    icon: Icons.account_balance_wallet_outlined,
    answerKey: 'help_support.ans_payment',
  ),
  _QuickReply(
    labelKey: 'help_support.quick_account',
    icon: Icons.person_outline,
    answerKey: 'help_support.ans_account',
  ),
  _QuickReply(
    labelKey: 'help_support.quick_report',
    icon: Icons.bug_report_outlined,
    answerKey: 'help_support.ans_report',
  ),
  _QuickReply(
    labelKey: 'help_support.quick_center',
    icon: Icons.location_off_outlined,
    answerKey: 'help_support.ans_center',
  ),
  _QuickReply(
    labelKey: 'help_support.quick_pricing',
    icon: Icons.attach_money_outlined,
    answerKey: 'help_support.ans_pricing',
  ),
];

// ──────────────────────────────────────────────
// Screen
// ──────────────────────────────────────────────

class HelpSupportScreen extends ConsumerStatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  ConsumerState<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends ConsumerState<HelpSupportScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isBotTyping = false;
  String? _chatId;
  late final Future<String> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = _getOrCreateSession();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Session init ─────────────────────────────

  Future<String> _getOrCreateSession() async {
    if (_chatId != null) return _chatId!;

    final user = ref.read(authStateProvider);
    final userId = user?.id ?? 'anonymous_${DateTime.now().millisecondsSinceEpoch}';
    final userName = user?.name ?? 'Guest';

    final chatId = await ref
        .read(supportChatSessionProvider((userId: userId, userName: userName))
            .future);
    if (mounted) setState(() => _chatId = chatId);

    // Send greeting if session is new (no messages yet)
    final service = ref.read(supportChatServiceProvider);
    final messages = await service.messagesStream(chatId).first;
    if (messages.isEmpty) {
      await service.sendBotMessage(
        chatId: chatId,
        text: 'help_support.greeting'.tr(),
      );
    }

    return chatId;
  }

  // ── Send ─────────────────────────────────────

  Future<void> _sendUserMessage(String text) async {
    if (text.trim().isEmpty) return;
    _inputController.clear();

    final chatId = await _sessionFuture;
    final service = ref.read(supportChatServiceProvider);
    await service.sendUserMessage(chatId: chatId, text: text.trim());
    _scrollToBottom();
  }

  Future<void> _onQuickReply(_QuickReply reply) async {
    final chatId = await _sessionFuture;
    final service = ref.read(supportChatServiceProvider);

    await service.sendUserMessage(chatId: chatId, text: reply.label);
    _scrollToBottom();

    if (!mounted) return;
    setState(() => _isBotTyping = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    await service.sendBotMessage(chatId: chatId, text: reply.answer);
    if (mounted) setState(() => _isBotTyping = false);
    _scrollToBottom();
  }

  Future<void> _onSendPressed() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    await _sendUserMessage(text);

    // Generic acknowledgement from bot
    if (!mounted) return;
    setState(() => _isBotTyping = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final chatId = _chatId;
    if (chatId != null) {
      await ref.read(supportChatServiceProvider).sendBotMessage(
            chatId: chatId,
            text: 'help_support.ack_message'.tr(),
          );
    }
    if (mounted) setState(() => _isBotTyping = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: _buildAppBar(context),
      body: FutureBuilder<String>(
        future: _sessionFuture,
        builder: (context, sessionSnap) {
          if (sessionSnap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.green),
            );
          }
          if (sessionSnap.hasError) {
            return Center(
              child: Text(
                'help_support.chat_error'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          final chatId = sessionSnap.data!;
          final messagesAsync =
              ref.watch(supportMessagesProvider(chatId));

          return Column(
            children: [
              Expanded(
                child: messagesAsync.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.green)),
                  error: (e, _) => Center(
                    child: Text('Error: $e',
                        style:
                            const TextStyle(color: AppColors.textMuted)),
                  ),
                  data: (messages) {
                    if (messages.isEmpty) {
                      return _buildEmptyState();
                    }
                    WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _scrollToBottom());
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: messages.length,
                      itemBuilder: (_, i) {
                        final msg = messages[i];
                        return _MessageBubble(
                          key: ValueKey(msg.id),
                          text: msg.text,
                          isUser:
                              msg.sender == MessageSender.user,
                          time: msg.timestamp,
                        );
                      },
                    );
                  },
                ),
              ),
              if (_isBotTyping) _buildTypingIndicator(),
              _buildQuickRepliesRow(),
              _buildInputBar(),
            ],
          );
        },
      ),
    );
  }

  // ── AppBar ───────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.darkCard,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.green, Color(0xFF1B5E20)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.green.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child:
                const Icon(Icons.support_agent, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Forya Support',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'help_support.online_status'.tr(),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
          onPressed: () {},
          tooltip: 'Options',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppColors.darkBorder, height: 1),
      ),
    );
  }

  // ── Empty State ──────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.green.withValues(alpha: 0.2), Colors.transparent],
              ),
            ),
            child:
                const Icon(Icons.support_agent, size: 44, color: AppColors.green),
          ),
          const SizedBox(height: 16),
          Text(
            'help_support.here_to_help'.tr(),
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'help_support.pick_topic'.tr(),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Typing Indicator ─────────────────────────

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 6),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.support_agent,
                size: 16, color: AppColors.green),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }

  // ── Quick Replies Row ────────────────────────

  Widget _buildQuickRepliesRow() {
    return Container(
      color: AppColors.darkBg,
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _quickReplies.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final qr = _quickReplies[index];
            return GestureDetector(
              onTap: () => _onQuickReply(qr),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(qr.icon, size: 14, color: AppColors.green),
                    const SizedBox(width: 6),
                    Text(
                      qr.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Input Bar ────────────────────────────────

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.darkCard,
        border: Border(top: BorderSide(color: AppColors.darkBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _onSendPressed(),
                decoration: InputDecoration(
                  hintText: 'help_support.type_message'.tr(),
                  hintStyle: const TextStyle(
                      color: AppColors.textMuted, fontSize: 14),
                  filled: true,
                  fillColor: AppColors.darkBg,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        const BorderSide(color: AppColors.darkBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        const BorderSide(color: AppColors.darkBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        const BorderSide(color: AppColors.green, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _onSendPressed,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.green, Color(0xFF1B5E20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.green.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Message Bubble Widget (animated)
// ──────────────────────────────────────────────

class _MessageBubble extends StatefulWidget {
  final String text;
  final bool isUser;
  final DateTime time;

  const _MessageBubble({
    super.key,
    required this.text,
    required this.isUser,
    required this.time,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _opacityAnim =
        CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: widget.isUser ? const Offset(0.3, 0) : const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: widget.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!widget.isUser) ...[
                Container(
                  width: 30,
                  height: 30,
                decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.support_agent,
                      size: 16, color: AppColors.green),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: widget.isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.72,
                      ),
                      decoration: BoxDecoration(
                        gradient: widget.isUser
                            ? const LinearGradient(
                                colors: [
                                  AppColors.green,
                                  Color(0xFF1B5E20)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: widget.isUser ? null : AppColors.darkCard,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: widget.isUser
                              ? const Radius.circular(16)
                              : const Radius.circular(4),
                          bottomRight: widget.isUser
                              ? const Radius.circular(4)
                              : const Radius.circular(16),
                        ),
                        border: widget.isUser
                            ? null
                            : Border.all(color: AppColors.darkBorder),
                        boxShadow: widget.isUser
                            ? [
                                BoxShadow(
                                  color:
                                      AppColors.green.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        widget.text,
                        style: TextStyle(
                          color: widget.isUser
                              ? Colors.white
                              : const Color(0xFFE0E0E0),
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatTime(widget.time),
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              if (widget.isUser) const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ──────────────────────────────────────────────
// Typing Dots Animation
// ──────────────────────────────────────────────

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_controller.value - i * 0.2).clamp(0.0, 1.0);
            final opacity = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.3, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
