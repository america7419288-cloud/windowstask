import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/user_context_provider.dart';
import '../../providers/ai_provider.dart';
import '../../screens/ai_onboarding_screen.dart';
import '../../theme/colors.dart';
import '../../theme/app_theme.dart';
import 'ai_chat_panel.dart';

class AIChatBubble extends StatelessWidget {
  const AIChatBubble({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final contextProvider = context.watch<UserContextProvider>();
    final aiProvider = context.watch<AIProvider>();

    return Positioned(
      bottom: 24,
      right: 24,
      child: GestureDetector(
        onTap: () {
          if (!contextProvider.hasCompletedOnboarding) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AIOnboardingScreen()),
            );
          } else {
            showAIChatPanel(context);
          }
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulse outer ring
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.indigo.withValues(alpha: 0.2),
              ),
            ).animate(onPlay: (c) => c.repeat()).scale(
              begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2),
              duration: 2000.ms, curve: Curves.easeInOutSine,
            ).fadeOut(),

            // Main bubble
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.gradPrimary,
                boxShadow: AppColors.shadowLG(isDark: colors.isDark),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
            ),

            // Unread dot
            if (aiProvider.messages.isNotEmpty)
              Positioned(
                top: 0, right: 0,
                child: Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.background, width: 2),
                  ),
                ),
              ).animate().scale(delay: 500.ms),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0);
  }
}
