import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/domain/assistant_controller.dart';
import '../domain/chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _uuid = const Uuid();
  final _chatHistoryRepo = ServiceLocator.instance.chatHistoryRepository;
  final List<ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _sending = false;
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadPersistedHistory();
  }

  Future<void> _loadPersistedHistory() async {
    final past = await _chatHistoryRepo.recent(limit: 50);
    if (!mounted) return;
    setState(() {
      _messages.addAll(past);
      _loadingHistory = false;
    });
    _scrollToBottom();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _sending) return;
    final userMessage = ChatMessage(id: _uuid.v4(), role: 'user', content: text, timestamp: DateTime.now());
    setState(() {
      _messages.add(userMessage);
      _sending = true;
    });
    await _chatHistoryRepo.add(role: 'user', content: text);
    if (!mounted) return;
    _inputController.clear();
    _scrollToBottom();

    final settings = ServiceLocator.instance.settingsRepository;
    final provider = ServiceLocator.instance.resolveAiProvider(
      provider: await settings.getAiProvider(),
      apiKey: await settings.getAiApiKey(),
    );

    // Real, persistent memory: pull the last messages from SQLite (not
    // just this screen's session) so the AI has genuine continuity across
    // app restarts and across the Home mic flow too.
    final history = _messages.map((m) => {'role': m.role, 'content': m.content}).toList();
    final result = await provider.chat(userMessage: text, history: history);

    // Awaited so scrolling to the bottom happens AFTER the new message is
    // actually added to _messages and setState has run — otherwise the
    // scroll would fire against the stale list and miss the new message.
    await result.when(
      success: (reply) async {
        await _chatHistoryRepo.add(role: 'assistant', content: reply);
        if (!mounted) return;
        setState(() {
          _messages.add(ChatMessage(id: _uuid.v4(), role: 'assistant', content: reply, timestamp: DateTime.now()));
          _sending = false;
        });
      },
      failure: (msg, _) async {
        await _chatHistoryRepo.add(role: 'assistant', content: msg);
        if (!mounted) return;
        setState(() {
          _messages.add(ChatMessage(id: _uuid.v4(), role: 'assistant', content: msg, timestamp: DateTime.now()));
          _sending = false;
        });
      },
    );
    if (!mounted) return;
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JARVIS AI Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await _chatHistoryRepo.clear();
              if (!mounted) return;
              setState(() => _messages.clear());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loadingHistory
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'JARVIS se kuch bhi pucho...',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: _messages.length + (_sending ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length) {
                            return const _TypingBubble();
                          }
                          return _ChatBubble(message: _messages[index]);
                        },
                      ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(hintText: 'Ask anything...'),
                      onSubmitted: _send,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.mic),
                    onPressed: () async {
                      final controller = context.read<AssistantController>();
                      await controller.startListening();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => _send(_inputController.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        padding: const EdgeInsets.all(AppSpacing.sm),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          gradient: isUser ? AppColors.orbGradient : null,
          color: isUser ? null : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.content,
          style: TextStyle(color: isUser ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const SizedBox(
          width: 24,
          height: 12,
          child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
        ),
      ),
    );
  }
}
