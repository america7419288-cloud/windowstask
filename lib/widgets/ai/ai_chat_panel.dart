import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/ai_provider.dart';
import '../../providers/user_context_provider.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/app_theme.dart';
import 'message_bubble.dart';

void showAIChatPanel(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const AIChatPanel(),
  );
}

class AIChatPanel extends StatefulWidget {
  const AIChatPanel({super.key});

  @override
  State<AIChatPanel> createState() => _AIChatPanelState();
}

class _AIChatPanelState extends State<AIChatPanel> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final ai = context.watch<AIProvider>();
    final query = MediaQuery.of(context);

    // Scroll automatically when new messages arrive
    if (ai.messages.isNotEmpty) _scrollToBottom();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: AppColors.shadowLG(isDark: colors.isDark),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: colors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: AppColors.indigo, size: 24),
                    const SizedBox(width: 12),
                    Text('Taski AI Assistant', style: AppTypography.headlineSM.copyWith(fontWeight: FontWeight.w800)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      onPressed: () => ai.resetChat(),
                      tooltip: 'Reset Chat',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),

              // Chat history or Empty State
              Expanded(
                child: ai.messages.isEmpty 
                  ? _EmptyChat(onAction: () => ai.generateSchedule(context))
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      itemCount: ai.messages.length + (ai.isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == ai.messages.length) {
                          return const ThinkingBubble();
                        }
                        return MessageBubble(message: ai.messages[index]);
                      },
                    ),
              ),

              // Input field
              _ChatInput(
                controller: _ctrl,
                isLoading: ai.isLoading,
                onSend: (text) {
                  ai.sendMessage(context, text);
                  _ctrl.clear();
                },
              ),
              SizedBox(height: query.viewInsets.bottom + 16),
            ],
          ),
        );
      },
    );
  }
}

class ThinkingBubble extends StatelessWidget {
  const ThinkingBubble({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: const BoxDecoration(gradient: AppColors.gradPrimary, shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.appColors.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => Container(
                width: 6, height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(color: context.appColors.textQuaternary, shape: BoxShape.circle),
              ).animate(onPlay: (c) => c.repeat()).scale(
                begin: const Offset(1, 1), end: const Offset(1.5, 1.5),
                duration: 600.ms, delay: (i * 200).ms, curve: Curves.easeInOut,
              ).then().scale(begin: const Offset(1.5, 1.5), end: const Offset(1, 1))),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  final VoidCallback onAction;
  const _EmptyChat({required this.onAction});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome_rounded, size: 64, color: AppColors.indigoDim),
            const SizedBox(height: 24),
            Text('Ready to focus?', style: AppTypography.headlineMD.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text(
              'I can build you a perfect plan for today based on your rhythm and goals.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMD.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigo,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onAction,
              icon: const Icon(Icons.bolt_rounded, size: 20, color: Colors.white),
              label: Text('Build a plan for today', style: AppTypography.labelLG.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final Function(String) onSend;

  const _ChatInput({required this.controller, required this.isLoading, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.indigo.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isLoading,
                style: AppTypography.bodyMD.copyWith(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Ask your assistant...',
                  hintStyle: AppTypography.bodyMD.copyWith(color: colors.textQuaternary),
                  border: InputBorder.none,
                ),
                onSubmitted: onSend,
              ),
            ),
            IconButton(
              onPressed: isLoading ? null : () => onSend(controller.text),
              icon: Icon(
                Icons.send_rounded,
                color: isLoading ? colors.textQuaternary : AppColors.indigo,
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
