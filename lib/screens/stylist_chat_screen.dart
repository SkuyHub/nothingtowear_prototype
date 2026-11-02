import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'outfit_builder_screen.dart';

/// "AI Stylist Chat" box shown at the bottom of the Stylist tab.
/// Sending a message (or tapping a suggestion) opens the conversation.
class StylistChatCard extends StatefulWidget {
  const StylistChatCard({super.key});

  @override
  State<StylistChatCard> createState() => _StylistChatCardState();
}

class _StylistChatCardState extends State<StylistChatCard> {
  final _controller = TextEditingController();

  static const _suggestions = [
    'Accessorize Silk Pants',
    'Casual Dinner in Jaksel',
    'What to Wear Today',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final t = (text ?? _controller.text).trim();
    if (t.isEmpty) return;
    _controller.clear();
    FocusScope.of(context).unfocus();
    pushScreen(context, StylistChatScreen(initialMessage: t));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, size: 20),
              SizedBox(width: 10),
              Text('AI Stylist Chat', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _send(_suggestions[i]),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '"${_suggestions[i]}"',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(left: 4, right: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Voice input',
                  icon: const Icon(Icons.mic_none, color: AppColors.muted),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Voice input is not available in the demo')),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: _send,
                    textInputAction: TextInputAction.send,
                    decoration: const InputDecoration(
                      hintText: 'Ask Your Stylist Anything',
                      border: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.arrow_upward, size: 18, color: kOnAccent),
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

class _Msg {
  const _Msg(this.text, {required this.fromUser, this.reply});

  final String text;
  final bool fromUser;
  final StylistReply? reply;
}

class StylistChatScreen extends StatefulWidget {
  const StylistChatScreen({super.key, required this.initialMessage});

  final String initialMessage;

  @override
  State<StylistChatScreen> createState() => _StylistChatScreenState();
}

class _StylistChatScreenState extends State<StylistChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [];
  bool _typing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ask(widget.initialMessage));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _ask(String text) async {
    final app = context.read<AppState>();
    setState(() {
      _msgs.add(_Msg(text, fromUser: true));
      _typing = true;
    });
    _toBottom();
    final r = await app.askStylist(text);
    if (!mounted) return;
    setState(() {
      _msgs.add(_Msg(r.text, fromUser: false, reply: r));
      _typing = false;
    });
    _toBottom();
  }

  void _submit() {
    final t = _controller.text.trim();
    if (t.isEmpty || _typing) return;
    _controller.clear();
    _ask(t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Stylist')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _msgs.length + (_typing ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _msgs.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Styling...', style: TextStyle(color: AppColors.muted)),
                    ),
                  );
                }
                return _bubble(_msgs[i]);
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(hintText: 'Ask Your Stylist Anything'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _typing ? null : _submit,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: kOnAccent,
                    ),
                    icon: const Icon(Icons.arrow_upward),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(_Msg m) {
    final layout = m.reply?.layout;
    return Align(
      alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: m.fromUser ? AppColors.accent : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              m.text,
              style: TextStyle(color: m.fromUser ? kOnAccent : AppColors.text),
            ),
            if (layout != null && layout.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 180,
                width: double.infinity,
                child: OutfitPreview(layout: layout, radius: 12),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => pushScreen(
                    context,
                    OutfitBuilderScreen(
                      initialLayout: layout,
                      method: m.reply!.method,
                      title: 'AI suggestion',
                    ),
                  ),
                  child: const Text('Open in canvas'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
