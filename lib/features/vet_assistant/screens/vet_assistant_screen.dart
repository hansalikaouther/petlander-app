import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/models/animal.dart';
import '../../../shared/widgets/animal_icon.dart';
import '../data/chat_engine.dart';
import '../data/symptom_database.dart';
import '../providers/chat_providers.dart';

class VetAssistantScreen extends ConsumerStatefulWidget {
  const VetAssistantScreen({super.key});

  @override
  ConsumerState<VetAssistantScreen> createState() => _VetAssistantScreenState();
}

class _VetAssistantScreenState extends ConsumerState<VetAssistantScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send([String? quickText]) async {
    final text = quickText ?? _inputCtrl.text;
    if (text.trim().isEmpty) return;
    _inputCtrl.clear();
    await ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future<void>.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🤖 '),
            Text('Assistant Vet IA'),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Nouvelle conversation',
            onPressed: () => ref.read(chatProvider.notifier).reset(),
          ),
        ],
      ),
      body: Column(
        children: [
          _AnimalTypeFilter(
            selected: state.selectedType,
            onChanged: (t) => ref.read(chatProvider.notifier).selectAnimalType(t),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemCount: state.messages.length + (state.isTyping ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == state.messages.length) return const _TypingIndicator();
                return _MessageBubble(message: state.messages[i], index: i);
              },
            ),
          ),
          _QuickSymptoms(
            type: state.selectedType,
            onSelect: (label) => _send(label),
          ),
          _InputBar(
            controller: _inputCtrl,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _AnimalTypeFilter extends StatelessWidget {
  final AnimalType? selected;
  final ValueChanged<AnimalType?> onChanged;
  const _AnimalTypeFilter({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        children: [
          _chip(context, 'Tous', selected == null, () => onChanged(null), null),
          ...AnimalType.values.where((t) => t != AnimalType.autre).map((t) =>
              _chip(context, t.label, selected == t, () => onChanged(t), t)),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, bool active, VoidCallback onTap, AnimalType? t) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: t != null ? AnimalIcon(type: t, size: 24, animated: false) : null,
        label: Text(label),
        backgroundColor: active
            ? AppColors.primary.withValues(alpha: 0.5)
            : Theme.of(context).colorScheme.surface,
        side: BorderSide(
          color: active ? AppColors.primaryDark : AppColors.primary.withValues(alpha: 0.3),
        ),
        onPressed: onTap,
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final int index;
  const _MessageBubble({required this.message, required this.index});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final bg = isUser
        ? AppColors.primary.withValues(alpha: 0.4)
        : (message.urgency != null
            ? _urgencyColor(message.urgency!).withValues(alpha: 0.18)
            : Theme.of(context).colorScheme.surfaceContainerLow);
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return FadeInUp(
      duration: const Duration(milliseconds: 350),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18),
              ),
              border: Border.all(
                color: isUser
                    ? AppColors.primaryDark.withValues(alpha: 0.3)
                    : AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: align,
              children: [
                if (!isUser)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text('🤖', style: TextStyle(fontSize: 14)),
                        ),
                        const SizedBox(width: 6),
                        Text('Assistant Vet',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                _RichText(text: message.text),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _urgencyColor(UrgencyLevel u) {
    switch (u) {
      case UrgencyLevel.low: return AppColors.success;
      case UrgencyLevel.medium: return AppColors.warning;
      case UrgencyLevel.high: return Colors.deepOrange;
      case UrgencyLevel.critical: return AppColors.danger;
    }
  }
}

/// Mini-renderer pour le texte avec **gras** et _italique_.
class _RichText extends StatelessWidget {
  final String text;
  const _RichText({required this.text});

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      _appendStyledLine(spans, lines[i]);
      if (i < lines.length - 1) spans.add(const TextSpan(text: '\n'));
    }
    return SelectableText.rich(
      TextSpan(
        style: AppTextStyles.bodyMedium.copyWith(height: 1.4),
        children: spans,
      ),
    );
  }

  void _appendStyledLine(List<InlineSpan> spans, String line) {
    final pattern = RegExp(r'(\*\*([^*]+)\*\*|_([^_]+)_)');
    var lastEnd = 0;
    for (final match in pattern.allMatches(line)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: line.substring(lastEnd, match.start)));
      }
      if (match.group(2) != null) {
        spans.add(TextSpan(
          text: match.group(2),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ));
      } else if (match.group(3) != null) {
        spans.add(TextSpan(
          text: match.group(3),
          style: const TextStyle(fontStyle: FontStyle.italic),
        ));
      }
      lastEnd = match.end;
    }
    if (lastEnd < line.length) {
      spans.add(TextSpan(text: line.substring(lastEnd)));
    }
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(delay: 0),
            SizedBox(width: 4),
            _Dot(delay: 200),
            SizedBox(width: 4),
            _Dot(delay: 400),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _ctrl,
        curve: Interval(widget.delay / 1000, 1, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 8, height: 8,
        decoration: const BoxDecoration(
          color: AppColors.primaryDark,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _QuickSymptoms extends StatelessWidget {
  final AnimalType? type;
  final ValueChanged<String> onSelect;
  const _QuickSymptoms({required this.type, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final list = type != null
        ? SymptomDatabase.forType(type!)
        : SymptomDatabase.entries;
    final top = list.take(8).toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: AppColors.primary.withValues(alpha: 0.2))),
      ),
      child: SizedBox(
        height: 44,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: top.length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: ActionChip(
              label: Text(top[i].label, style: AppTextStyles.caption),
              onPressed: () => onSelect(top[i].label),
              backgroundColor: AppColors.accent.withValues(alpha: 0.3),
              side: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const _InputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: AppColors.primary.withValues(alpha: 0.2))),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Décris les symptômes...',
                  prefixIcon: const Icon(Icons.chat_bubble_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.primaryDark,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onSend,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.send, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
