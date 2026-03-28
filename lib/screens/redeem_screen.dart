import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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
import '../widgets/shared/taski_button.dart';
import '../widgets/shared/section_label.dart';
import '../data/sticker_packs.dart';
import '../data/app_stickers.dart';
import '../utils/date_utils.dart';

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
  List<_RecentCode> _recentCodes = [];

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
    _loadRecentCodes();
  }

  Future<void> _loadRecentCodes() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('recent_redeem_codes') ?? [];
    if (mounted) {
      setState(() {
        _recentCodes = list.map((e) => _RecentCode.fromJson(jsonDecode(e))).toList();
      });
    }
  }

  Future<void> _saveRecentCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final newCode = _RecentCode(code, DateTime.now());
    _recentCodes.insert(0, newCode);
    if (_recentCodes.length > 3) _recentCodes.removeLast();
    await prefs.setStringList('recent_redeem_codes', _recentCodes.map((e) => jsonEncode(e.toJson())).toList());
    if (mounted) setState(() {});
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
        
        await _saveRecentCode(result.codeDescription ?? code);

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

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Widget _buildInput(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: SizedBox(
          width: 480,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Gift sticker
              AppStickerWidget(
                assetPath: AppStickers.celebrationPath,
                size: 100,
                animate: true,
              ),
              const SizedBox(height: 24),

              // Title
              Text('Redeem a Code',
                style: AppTypography.displayLG.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center),
              const SizedBox(height: 8),

              Text(
                'Enter your code to unlock'
                ' exclusive stickers, XP,'
                ' and more',
                style: AppTypography.bodyMD.copyWith(
                  color: colors.textTertiary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center),
              const SizedBox(height: 36),

              // Code input (shake on error)
              AnimatedBuilder(
                animation: _shakeCtrl,
                builder: (_, child) =>
                  Transform.translate(
                    offset: Offset(
                      sin(_shakeCtrl.value * pi * 8) * 8, 0),
                    child: child),
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _errorMessage != null
                      ? [BoxShadow(
                          color: AppColors.error.withValues(alpha: .25),
                          blurRadius: 16,
                        )]
                      : AppColors.shadowMD(isDark: colors.isDark),
                    border: _errorMessage != null
                        ? Border.all(
                            color: AppColors.error.withValues(alpha: .4),
                            width: 1.5)
                        : null,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focusNode,
                    textAlign: TextAlign.center,
                    style: AppTypography.mono.copyWith(
                      color: colors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'TASKI-XXXX-XXXX',
                      hintStyle: AppTypography.mono.copyWith(
                        color: colors.textQuaternary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
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
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 14,
                              color: AppColors.error),
                          const SizedBox(width: 6),
                          Text(_errorMessage!,
                            style: AppTypography.labelMD.copyWith(
                              color: AppColors.error,
                            )),
                        ]))
                  : const SizedBox(height: 10),
              ),

              const SizedBox(height: 24),

              // Submit button (centered, NOT full width)
              TaskiButton(
                label: 'Redeem Code',
                icon: Icons.redeem_rounded,
                onTap: _submit,
              ),

              const SizedBox(height: 40),

              // What codes unlock
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(children: [
                  Text('What can codes unlock?',
                    style: AppTypography.labelMD.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w700,
                    )),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    _UnlockChip(emoji: '🎭', label: 'Stickers', colors: colors),
                    const SizedBox(width: 10),
                    _UnlockChip(emoji: '⚡', label: 'XP Bonus', colors: colors),
                    const SizedBox(width: 10),
                    _UnlockChip(emoji: '✨', label: 'Premium', colors: colors),
                  ]),
                  const SizedBox(height: 12),
                  Text(
                    'Follow @taski on Twitter'
                    ' for exclusive drop codes',
                    style: AppTypography.caption.copyWith(
                      color: colors.textQuaternary,
                    ),
                    textAlign: TextAlign.center),
                ]),
              ),

              // Recent redemptions
              if (_recentCodes.isNotEmpty) ...[
                const SizedBox(height: 20),
                const SectionLabel(text: 'Recently Redeemed'),
                const SizedBox(height: 10),
                ..._recentCodes.map((r) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      const Icon(Icons.check_circle,
                          size: 13,
                          color: AppColors.success),
                      const SizedBox(width: 8),
                      Text(r.codeUsed, // Assuming codeUsed is the field name
                        style: AppTypography.mono.copyWith(
                          fontSize: 12,
                          color: colors.textSecondary,
                        )),
                      const Spacer(),
                      Text(_timeAgo(r.claimedAt),
                        style: AppTypography.caption.copyWith(
                          color: colors.textTertiary,
                        )),
                    ]),
                  )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _UnlockChip({
    required String emoji,
    required String label,
    required AppColorsExtension colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Text(label,
              style: AppTypography.labelMD.copyWith(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              )),
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
                  color: colors.surfaceElevated,
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

class _RecentCode {
  final String codeUsed;
  final DateTime claimedAt;
  _RecentCode(this.codeUsed, this.claimedAt);

  Map<String, dynamic> toJson() => {
    'code': codeUsed,
    'date': claimedAt.toIso8601String(),
  };

  factory _RecentCode.fromJson(Map<String, dynamic> json) => _RecentCode(
    json['code'] as String,
    DateTime.parse(json['date'] as String),
  );
}
