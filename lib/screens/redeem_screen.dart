import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';
import '../providers/user_provider.dart';
import '../models/redeem_result.dart';
import '../services/redeem_service.dart';
import '../widgets/shared/sticker_widget.dart';
import '../data/sticker_packs.dart';

enum _RedeemState { input, loading, success }

class RedeemScreen extends StatefulWidget {
  const RedeemScreen({super.key});

  @override
  State<RedeemScreen> createState() => _RedeemScreenState();
}

class _RedeemScreenState extends State<RedeemScreen> with TickerProviderStateMixin {
  _RedeemState _state = _RedeemState.input;
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  String? _errorMessage;
  RedeemResult? _result;

  // Animation controllers
  late AnimationController _shakeCtrl;
  late AnimationController _successCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successCtrl,
      curve: Curves.elasticOut,
    ));
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    // Focus on input after a short delay
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _successCtrl.dispose();
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _ctrl.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter a code');
      _shake();
      return;
    }

    setState(() {
      _state = _RedeemState.loading;
      _errorMessage = null;
    });

    final result = await RedeemService.instance.claimCode(code);

    if (result.success) {
      // Apply rewards locally
      if (mounted) {
        await RedeemService.instance.applyRewards(
          result.rewards!,
          context.read<UserProvider>(),
        );

        setState(() {
          _result = result;
          _state = _RedeemState.success;
        });

        // Trigger success animation
        _successCtrl.forward();
      }
    } else {
      setState(() {
        _state = _RedeemState.input;
        _errorMessage = _errorText(result.error!);
      });
      _shake();
    }
  }

  void _shake() {
    _shakeCtrl.reset();
    _shakeCtrl.forward();
  }

  String _errorText(RedeemError e) {
    switch (e) {
      case RedeemError.invalidFormat:
        return 'Invalid format. Use TASKI-XXXX-XXXX';
      case RedeemError.notFound:
        return 'Code not found. Check for typos';
      case RedeemError.alreadyClaimed:
        return 'Already claimed on this device';
      case RedeemError.expired:
        return 'This code has expired';
      case RedeemError.exhausted:
        return 'All claims have been used';
      case RedeemError.disabled:
        return 'This code is no longer active';
      case RedeemError.networkError:
        return 'No internet connection';
      case RedeemError.serverError:
        return 'Server error. Try again';
    }
  }

  Widget _buildInput(BuildContext context) {
    final colors = context.appColors;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header illustration
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: BorderRadius.circular(28),
              boxShadow: AppColors.ambientShadow(
                opacity: 0.25,
                blur: 24,
                offset: const Offset(0, 8),
              ),
            ),
            child: const Center(
              child: Text('🎁', style: TextStyle(fontSize: 48)),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text('Redeem a Code',
              style: AppTypography.displayMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),

          Text('Enter your code to unlock exclusive stickers, XP, and more',
              style: AppTypography.bodyLarge.copyWith(
                color: colors.textTertiary,
                height: 1.5,
              ),
              textAlign: TextAlign.center),
          const SizedBox(height: 40),

          // Code input field
          AnimatedBuilder(
            animation: _shakeCtrl,
            builder: (_, child) {
              final shake = sin(_shakeCtrl.value * pi * 8) * 8;
              return Transform.translate(
                offset: Offset(shake, 0),
                child: child,
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: colors.isDark ? AppColors.surfaceContainerDk : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _errorMessage != null
                    ? [
                        BoxShadow(
                          color: AppColors.error.withValues(alpha: 0.20),
                          blurRadius: 16,
                          spreadRadius: 2,
                        )
                      ]
                    : AppColors.ambientShadow(opacity: 0.06, blur: 16, offset: const Offset(0, 4)),
                border: _errorMessage != null
                    ? Border.all(
                        color: AppColors.error.withValues(alpha: 0.4),
                        width: 1.5,
                      )
                    : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: TextField(
                controller: _ctrl,
                focusNode: _focusNode,
                textAlign: TextAlign.center,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  letterSpacing: 2,
                ),
                decoration: InputDecoration(
                  hintText: 'TASKI-XXXX-XXXX',
                  hintStyle: GoogleFonts.jetBrainsMono(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    color: colors.textQuaternary,
                    letterSpacing: 2,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onChanged: (v) {
                  final formatted = RedeemService.formatInput(v);
                  if (formatted != v) {
                    _ctrl.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(
                        offset: formatted.length,
                      ),
                    );
                  }
                  setState(() => _errorMessage = null);
                },
                onSubmitted: (_) => _submit(),
                maxLength: 17,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
              ),
            ),
          ),

          // Error message
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _errorMessage != null
                ? Padding(
                    key: ValueKey(_errorMessage),
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 14,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 6),
                        Text(_errorMessage!,
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.error,
                            )),
                      ],
                    ),
                  )
                : const SizedBox(key: ValueKey('empty'), height: 12),
          ),
          const SizedBox(height: 32),

          // Submit button
          GestureDetector(
            onTap: _submit,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppColors.ambientShadow(
                  opacity: 0.25,
                  blur: 20,
                  offset: const Offset(0, 6),
                ),
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.redeem_rounded, size: 18, color: Colors.white),
                    SizedBox(width: 10),
                    Text('Redeem Code',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        )),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
              'Codes are case-insensitive. Each code can only be redeemed once per device.',
              style: AppTypography.caption.copyWith(
                color: colors.textQuaternary,
                height: 1.5,
              ),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.05),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Center(
                child: Text('🎁', style: TextStyle(fontSize: 48)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Validating code...',
              style: AppTypography.titleMedium.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 8),
          Text('Connecting to server',
              style: AppTypography.bodyMedium.copyWith(
                color: colors.textTertiary,
              )),
          const SizedBox(height: 24),
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    final colors = context.appColors;
    final rewards = _result!.rewards!;

    return ScaleTransition(
      scale: _scaleAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientSuccess,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: AppColors.ambientShadow(
                    opacity: 0.30,
                    blur: 32,
                    offset: const Offset(0, 12),
                  ),
                ),
                child: const Center(
                  child: Text('🎉', style: TextStyle(fontSize: 64)),
                ),
              ),
              const SizedBox(height: 24),

              Text('Code Redeemed!',
                  style: AppTypography.displayMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),

              if (_result!.codeDescription != null)
                Text(_result!.codeDescription!,
                    style: AppTypography.bodyLarge.copyWith(
                      color: colors.textTertiary,
                    ),
                    textAlign: TextAlign.center),
              const SizedBox(height: 32),

              // Rewards card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.isDark ? AppColors.surfaceContainerDk : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppColors.ambientShadow(
                    opacity: 0.06,
                    blur: 20,
                    offset: const Offset(0, 6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('YOU RECEIVED',
                        style: AppTypography.labelSmall.copyWith(
                          color: colors.textTertiary,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: 16),

                    if (rewards.xp > 0)
                      _RewardRow(
                        icon: Icons.bolt_rounded,
                        iconColor: AppColors.xpGold,
                        label: '+${rewards.xp} XP',
                        subtitle: 'Added to your balance',
                      ),

                    ...rewards.stickerPacks.map((packId) {
                      // Note: We use the ID for the label if pack name isn't easily found
                      return _RewardRow(
                        icon: Icons.auto_awesome,
                        iconColor: AppColors.primary,
                        label: 'Sticker Pack Unlock',
                        subtitle: 'Exclusive animated stickers unlocked',
                      );
                    }),

                    ...rewards.stickerIds.map((id) => _RewardRow(
                          icon: Icons.emoji_emotions,
                          iconColor: AppColors.tertiary,
                          label: 'Sticker Unlocked',
                          subtitle: id,
                          preview: id,
                        )),

                    ...rewards.premiumFeatures.map((f) => _RewardRow(
                          icon: Icons.workspace_premium,
                          iconColor: AppColors.xpGold,
                          label: _featureLabel(f),
                          subtitle: 'Premium feature activated',
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppColors.ambientShadow(
                      opacity: 0.20,
                      blur: 16,
                      offset: const Offset(0, 4),
                    ),
                  ),
                  child: const Center(
                    child: Text('Start Using Rewards →',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        )),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _featureLabel(String feature) {
    switch (feature) {
      case 'dark_aurora':
        return 'Aurora Dark Theme';
      default:
        return feature;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: colors.textSecondary,
          ),
        ),
        title: Text('Redeem Code',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            )),
        centerTitle: true,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
        child: switch (_state) {
          _RedeemState.input => _buildInput(context),
          _RedeemState.loading => _buildLoading(context),
          _RedeemState.success => _buildSuccess(context),
        },
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final String? preview; // sticker id

  const _RewardRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    this.preview,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final sticker = preview != null ? StickerRegistry.findById(preview!) : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: sticker != null
              ? Center(
                  child: StickerWidget(
                    localSticker: sticker,
                    size: 32,
                    animate: true,
                  ),
                )
              : Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTypography.titleSmall.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: AppTypography.caption.copyWith(
                    color: colors.textTertiary,
                  )),
            ],
          ),
        ),
        const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.tertiary),
      ]),
    );
  }
}
