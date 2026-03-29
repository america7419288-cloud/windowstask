import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_context.dart';
import '../providers/user_context_provider.dart';
import '../providers/ai_provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/shared/sticker_widget.dart';
import '../data/app_stickers.dart';
import '../widgets/shared/section_label.dart';
import '../theme/app_theme.dart';

class AIOnboardingScreen extends StatefulWidget {
  const AIOnboardingScreen({super.key});

  @override
  State<AIOnboardingScreen> createState() => _AIOnboardingScreenState();
}

class _AIOnboardingScreenState extends State<AIOnboardingScreen> {
  int _step = 0;
  UserContext _ctx = const UserContext();
  final TextEditingController _keyCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<UserContextProvider>();
    _ctx = provider.context;
    _keyCtrl.text = provider.apiKey ?? '';
    _descCtrl.text = _ctx.rawLifeDescription;
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _next() async {
    final provider = context.read<UserContextProvider>();
    final ai = context.read<AIProvider>();

    if (_step == 0) {
      if (_keyCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid API key')),
        );
        return;
      }
      await provider.saveApiKey(_keyCtrl.text.trim());
      setState(() => _step = 1);
    } else if (_step == 1) {
      setState(() => _step = 2);
    } else if (_step == 2) {
      _ctx = _ctx.copyWith(rawLifeDescription: _descCtrl.text.trim());
      await provider.saveContext(_ctx);
      await provider.completeOnboarding();
      setState(() => _step = 3);
      
      // Start initial generation
      await ai.generateSchedule(context);
      
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: _StepIndicator(currentStep: _step),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: _buildStepContent(),
              ),
            ),

            // Navigation
            Padding(
              padding: const EdgeInsets.all(32),
              child: Row(
                children: [
                  if (_step > 0 && _step < 3)
                    TextButton(
                      onPressed: () => setState(() => _step--),
                      child: Text('← Back',
                          style: AppTypography.labelLG.copyWith(color: colors.textSecondary)),
                    ),
                  const Spacer(),
                  if (_step < 3)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _next,
                      child: Text(_step == 2 ? 'Generate Schedule →' : 'Next →',
                          style: AppTypography.labelLG.copyWith(fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0: return _Step0(keyCtrl: _keyCtrl);
      case 1: return _Step1(ctx: _ctx, onUpdate: (c) => setState(() => _ctx = c));
      case 2: return _Step2(descCtrl: _descCtrl);
      case 3: return const _Step3();
      default: return const SizedBox();
    }
  }
}

// ── STEP 0: API KEY ──────────────────────────────────────────────────────────

class _Step0 extends StatelessWidget {
  final TextEditingController keyCtrl;
  const _Step0({required this.keyCtrl});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: [
        AppStickerWidget(assetPath: AppStickers.celebrationPath, size: 80, animate: true),
        const SizedBox(height: 24),
        Text('Meet your AI assistant',
            textAlign: TextAlign.center,
            style: AppTypography.displayLG.copyWith(fontWeight: FontWeight.w800, color: colors.textPrimary)),
        const SizedBox(height: 12),
        Text(
          'Taski AI uses Google Gemini to build your perfect daily schedule. You need a free Gemini API key.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMD.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(height: 40),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.shadowMD(isDark: colors.isDark),
          ),
          child: TextField(
            controller: keyCtrl,
            obscureText: true,
            style: AppTypography.mono.copyWith(fontSize: 14, color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Paste key here (AIzaSy...)',
              hintStyle: AppTypography.mono.copyWith(fontSize: 14, color: colors.textQuaternary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
              prefixIcon: const Icon(Icons.key_rounded, color: AppColors.indigo, size: 20),
            ),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => launchUrl(Uri.parse('https://aistudio.google.com/app/apikey')),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.indigo),
              const SizedBox(width: 8),
              Text('Get a free key at aistudio.google.com',
                  style: AppTypography.labelMD.copyWith(color: AppColors.indigo, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Your key is stored locally and encrypted. Never sent to our servers.',
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(color: colors.textQuaternary),
        ),
      ],
    );
  }
}

// ── STEP 1: PREFERENCES ──────────────────────────────────────────────────────

class _Step1 extends StatelessWidget {
  final UserContext ctx;
  final Function(UserContext) onUpdate;
  const _Step1({required this.ctx, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your daily rhythm', style: AppTypography.displaySM.copyWith(fontWeight: FontWeight.w800)),
        Text('Help the AI understand when you work best', style: AppTypography.bodyMD.copyWith(color: colors.textTertiary)),
        const SizedBox(height: 32),
        
        _TimePickerRow(
          label: '🌅 Wake up time',
          time: ctx.wakeUpTime,
          onChanged: (t) => onUpdate(ctx.copyWith(wakeUpTime: t)),
        ),
        _TimePickerRow(
          label: '🌙 Sleep time',
          time: ctx.sleepTime,
          onChanged: (t) => onUpdate(ctx.copyWith(sleepTime: t)),
        ),
        const Divider(height: 48),
        _TimePickerRow(
          label: '💼 Work/Study Start',
          time: ctx.workStartTime,
          onChanged: (t) => onUpdate(ctx.copyWith(workStartTime: t)),
        ),
        _TimePickerRow(
          label: '🏁 Work/Study End',
          time: ctx.workEndTime,
          onChanged: (t) => onUpdate(ctx.copyWith(workEndTime: t)),
        ),

        const SizedBox(height: 40),
        const SectionLabel(text: 'ENERGY PATTERN'),
        const SizedBox(height: 12),
        ...EnergyPattern.values.map((p) => _EnergyOption(
          pattern: p,
          isSelected: ctx.energyPattern == p,
          onTap: () => onUpdate(ctx.copyWith(energyPattern: p)),
        )),

        const SizedBox(height: 32),
        const SectionLabel(text: 'PREFERRED FOCUS DURATION'),
        const SizedBox(height: 12),
        Row(
          children: [25, 45, 60, 90].map((d) => Expanded(
            child: _DurationChip(
              minutes: d,
              isSelected: ctx.preferredTaskDurationMinutes == d,
              onTap: () => onUpdate(ctx.copyWith(preferredTaskDurationMinutes: d)),
            ),
          )).toList(),
        ),
      ],
    );
  }
}

// ── STEP 2: LIFE BIO ─────────────────────────────────────────────────────────

class _Step2 extends StatelessWidget {
  final TextEditingController descCtrl;
  const _Step2({required this.descCtrl});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What are you working toward?', style: AppTypography.displaySM.copyWith(fontWeight: FontWeight.w800)),
        Text('The more you share, the better your schedule', style: AppTypography.bodyMD.copyWith(color: colors.textTertiary)),
        const SizedBox(height: 32),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.shadowMD(isDark: colors.isDark),
          ),
          child: TextField(
            controller: descCtrl,
            maxLines: 10,
            style: AppTypography.bodyMD.copyWith(color: colors.textPrimary, height: 1.6),
            decoration: InputDecoration(
              hintText: 'Tell me about your life...\n\n'
                  'e.g. "I\'m a CS student preparing for exams. '
                  'I go to the gym 3x a week. College is 9am-2pm. '
                  'I want to study 3h per day..."',
              hintStyle: AppTypography.bodyMD.copyWith(color: colors.textQuaternary, height: 1.6),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(24),
            ),
          ),
        ),
      ],
    );
  }
}

// ── STEP 3: LOADING ──────────────────────────────────────────────────────────

class _Step3 extends StatelessWidget {
  const _Step3();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          const SizedBox(
            width: 80, height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation(AppColors.indigo),
              backgroundColor: AppColors.indigoDim,
            ),
          ),
          const SizedBox(height: 40),
          Text('Building your schedule...', 
              style: AppTypography.headlineMD.copyWith(fontWeight: FontWeight.w800, color: colors.textPrimary)),
          const SizedBox(height: 16),
          _RotatingTips(),
        ],
      ),
    );
  }
}

// ── HELPERS ──────────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: currentStep == i ? 24 : 8,
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: currentStep == i ? AppColors.gradPrimary : null,
          color: currentStep != i ? colors.divider : null,
        ),
      )),
    );
  }
}

class _TimePickerRow extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final Function(TimeOfDay) onChanged;

  const _TimePickerRow({required this.label, required this.time, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.titleSM.copyWith(color: colors.textSecondary)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.surfaceElevated,
              foregroundColor: colors.textPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final picked = await showTimePicker(context: context, initialTime: time);
              if (picked != null) onChanged(picked);
            },
            child: Text(time.format(context), style: AppTypography.mono.copyWith(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _EnergyOption extends StatelessWidget {
  final EnergyPattern pattern;
  final bool isSelected;
  final VoidCallback onTap;

  const _EnergyOption({required this.pattern, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.indigoDim : colors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: AppColors.indigo.withValues(alpha: 0.3), width: 1.5) : null,
        ),
        child: Row(
          children: [
            Text(pattern.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pattern.name, style: AppTypography.titleSM.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.indigo : colors.textPrimary,
                  )),
                  Text(pattern.displayName, style: AppTypography.caption.copyWith(color: colors.textTertiary)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.indigo, size: 20),
          ],
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final int minutes;
  final bool isSelected;
  final VoidCallback onTap;

  const _DurationChip({required this.minutes, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? null : colors.surfaceElevated,
          gradient: isSelected ? AppColors.gradPrimary : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text('$minutes min', style: AppTypography.labelMD.copyWith(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : colors.textSecondary,
          )),
        ),
      ),
    );
  }
}

class _RotatingTips extends StatefulWidget {
  @override
  State<_RotatingTips> createState() => _RotatingTipsState();
}

class _RotatingTipsState extends State<_RotatingTips> {
  final List<String> tips = [
    'Analyzing your energy patterns...',
    'Scheduling around your commitments...',
    'Balancing goals and rest...',
    'Optimizing task order...',
    'Almost ready...',
  ];
  int index = 0;
  late final Stream<int> _stream;

  @override
  void initState() {
    super.initState();
    _stream = Stream.periodic(const Duration(seconds: 3), (i) => (i + 1) % tips.length);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return StreamBuilder<int>(
      stream: _stream,
      initialData: 0,
      builder: (context, snapshot) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Text(
            tips[snapshot.data ?? 0],
            key: ValueKey(snapshot.data),
            style: AppTypography.bodyMD.copyWith(color: colors.textTertiary),
          ),
        );
      }
    );
  }
}
