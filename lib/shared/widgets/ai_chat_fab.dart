import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/constants.dart';
import '../../core/services/ai_service.dart';
import '../../core/utils/ai_prompts.dart';

class AiChatFab extends ConsumerStatefulWidget {
  /// Optional context item name to pre-fill prompts (e.g. from item detail page).
  final String? contextItemName;

  const AiChatFab({super.key, this.contextItemName});

  @override
  ConsumerState<AiChatFab> createState() => _AiChatFabState();
}

class _AiChatFabState extends ConsumerState<AiChatFab> {
  bool _isOpen = false;

  void _toggle() => setState(() => _isOpen = !_isOpen);

  @override
  Widget build(BuildContext context) {
    if (!_isOpen) {
      return FloatingActionButton(
        onPressed: _toggle,
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.auto_awesome, color: Colors.white),
      );
    }

    // When open, give the Stack explicit size so the chat panel
    // is within bounds and can receive touch events.
    return SizedBox(
      width: 320,
      height: 540,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: _ChatPanel(
              onClose: _toggle,
              contextItemName: widget.contextItemName,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: FloatingActionButton(
              onPressed: _toggle,
              backgroundColor: AppColors.accent,
              child: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatPanel extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final String? contextItemName;
  const _ChatPanel({required this.onClose, this.contextItemName});

  @override
  ConsumerState<_ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends ConsumerState<_ChatPanel> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _aiService = AiService();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _showQuickPrompts = true;

  List<String> get _quickPrompts {
    final item = widget.contextItemName;
    if (item != null) {
      return [
        'How should I place $item?',
        'What goes well with $item?',
        'Suggest a color palette for $item',
      ];
    }
    return [
      'Suggest a living room layout',
      'Modern color palette ideas',
      'How to style a small bedroom?',
    ];
  }

  @override
  void initState() {
    super.initState();
    final item = widget.contextItemName;
    final greeting = item != null
        ? "Hi! I see you're looking at **$item**. Ask me about placement ideas, styling tips, or anything else!"
        : "Hi! I'm your AI Design Assistant. Ask me about interior design, color palettes, furniture placement, or any design ideas!";
    _messages.add(_ChatMessage(text: greeting, isUser: false));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? overrideText]) async {
    final text = (overrideText ?? _controller.text).trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isLoading = true;
      _showQuickPrompts = false;
    });
    if (overrideText == null) _controller.clear();
    _scrollToBottom();

    try {
      final response = await _aiService.sendMessage(text);
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(text: response, isUser: false));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(text: "Sorry, I couldn't process that. Please try again.", isUser: false));
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _captureAndAnalyze() async {
    if (_isLoading) return;
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(source: ImageSource.camera, maxWidth: 1024);
      if (photo == null) return;
      final bytes = await photo.readAsBytes();

      setState(() {
        _messages.add(_ChatMessage(text: '📷 Analyzing your room...', isUser: true));
        _isLoading = true;
        _showQuickPrompts = false;
      });
      _scrollToBottom();

      final response = await _aiService.analyzeImage(bytes, AiPrompts.roomAnalysisPrompt);
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(text: response, isUser: false));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(text: "Couldn't analyze the image. Please try again.", isUser: false));
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
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
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        width: 320,
        height: 460,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text("AI Design Assistant", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                  GestureDetector(
                    onTap: widget.onClose,
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),

            // QUICK PROMPT CHIPS
            if (_showQuickPrompts)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _quickPrompts.map((p) => ActionChip(
                    label: Text(p, style: const TextStyle(fontSize: 11)),
                    backgroundColor: AppColors.backgroundBeige,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onPressed: () => _send(p),
                  )).toList(),
                ),
              ),

            // MESSAGES
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == _messages.length) {
                    return const Padding(
                      padding: EdgeInsets.all(8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                        ),
                      ),
                    );
                  }
                  final msg = _messages[i];
                  return _MessageBubble(message: msg);
                },
              ),
            ),

            // INPUT
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
              ),
              child: Row(
                children: [
                  // Camera button for room analysis
                  GestureDetector(
                    onTap: _captureAndAnalyze,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundBeige,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_outlined, color: AppColors.accent, size: 18),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: "Ask about design...",
                        hintStyle: const TextStyle(color: AppColors.hintColor, fontSize: 14),
                        filled: true,
                        fillColor: AppColors.backgroundBeige,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _send(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                      child: const Icon(Icons.send, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 240),
        decoration: BoxDecoration(
          color: message.isUser ? AppColors.accent : AppColors.backgroundBeige,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : AppColors.darkText,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}
