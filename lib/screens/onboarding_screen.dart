import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../providers/user_provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../data/app_stickers.dart';
import '../widgets/shared/deco_sticker.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  final _nameController = TextEditingController();
  Color _selectedAccent = AppColors.primary;

  static const List<Color> _presetColors = [
    Color(0xFF27389A), // Indigo (default)
    Color(0xFF6366F1), // Violet
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFFEF4444), // Red
    Color(0xFFF59E0B), // Amber
    Color(0xFF22C55E), // Green
    Color(0xFF14B8A6), // Teal
    Color(0xFF06B6D4), // Cyan
    Color(0xFF3B82F6), // Blue
    Color(0xFF505F76), // Slate
    Color(0xFF78716C), // Stone
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentStep < 2) {
      _pageController.animateToPage(
        _currentStep + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
      setState(() => _currentStep++);
    }
  }

  Future<void> _finish() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final profile = UserProfile(
      name: name,
      accentHex: _selectedAccent.toARGB32().toRadixString(16).substring(2),
      createdAt: DateTime.now(),
      lastActiveDate: DateTime.now(),
      currentStreak: 1,
      hasCompletedOnboarding: true,
    );

    await context.read<UserProvider>().saveProfile(profile);

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Step indicator dots
            _StepIndicator(current: _currentStep, total: 3),
            const SizedBox(height: 8),
            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  height: 3,
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / 3,
                    backgroundColor: AppColors.surfaceContainer,
                    valueColor: AlwaysStoppedAnimation(_selectedAccent),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcomePage(),
                  _buildNamePage(),
                  _buildAccentPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Sticker
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: SizedBox(
              width: 120,
              height: 120,
              child: AppStickers.celebrationStickers.isNotEmpty
                  ? DecoSticker(
                      sticker: AppStickers.celebrationStickers.first,
                      size: 120,
                      animate: true,
                    )
                  : const Icon(Icons.celebration_rounded,
                      size: 80, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'Welcome to Taski',
            style: AppTypography.displayLarge.copyWith(
              color: AppColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Your mindful workspace',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _GradientButton(
            label: 'Get Started →',
            gradient: AppColors.gradientPrimary,
            onTap: _nextPage,
          ),
        ],
      ),
    );
  }

  Widget _buildNamePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'What should we\ncall you?',
            style: AppTypography.displayMedium.copyWith(
              color: AppColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          // Name field — bottom accent only
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: _selectedAccent,
                  width: 2,
                ),
              ),
            ),
            child: TextField(
              controller: _nameController,
              textAlign: TextAlign.center,
              style: AppTypography.displayMedium.copyWith(
                color: AppColors.onSurface,
                fontSize: 24,
              ),
              decoration: InputDecoration(
                hintText: 'Your name',
                hintStyle: AppTypography.displayMedium.copyWith(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                  fontSize: 24,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _nextPage(),
            ),
          ),
          const SizedBox(height: 48),
          _GradientButton(
            label: 'Continue →',
            gradient: AppColors.gradientPrimary,
            onTap: () {
              if (_nameController.text.trim().isNotEmpty) {
                _nextPage();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccentPage() {
    final name = _nameController.text.trim().isEmpty
        ? 'Friend'
        : _nameController.text.trim().split(' ').first;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Make it yours',
            style: AppTypography.displayMedium.copyWith(
              color: AppColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Live preview
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: AppTypography.headlineSmall.copyWith(
              color: _selectedAccent,
            ),
            child: Text('Good morning, $name'),
          ),
          const SizedBox(height: 40),
          // Color grid
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: _presetColors.map((color) {
              final isSelected = _selectedAccent.toARGB32() == color.toARGB32();
              return GestureDetector(
                onTap: () => setState(() => _selectedAccent = color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: AppColors.onSurface, width: 3)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 48),
          _GradientButton(
            label: 'Start using Taski →',
            gradient: LinearGradient(
              colors: [_selectedAccent, _selectedAccent.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: _finish,
          ),
        ],
      ),
    );
  }
}

// ── Step Indicator Dots ─────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = i <= current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary
                : AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ── Gradient CTA Button ─────────────────────────────
class _GradientButton extends StatelessWidget {
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;
  const _GradientButton({
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppColors.ambientShadow(
            opacity: 0.15,
            blur: 20,
            offset: const Offset(0, 8),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: Colors.white,
            fontSize: 15,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

