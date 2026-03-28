import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/admin_table.dart';

class CodesTab extends StatefulWidget {
  const CodesTab({super.key});

  @override
  State<CodesTab> createState() => _CodesTabState();
}

class _CodesTabState extends State<CodesTab> {
  // Use a Key to force FutureBuilder rebuild
  Key _futureKey = UniqueKey();

  Future<List<dynamic>> _loadCodes() async {
    return await Supabase.instance.client
        .from('redeem_codes')
        .select()
        .order('created_at', ascending: false);
  }

  void _refresh() {
    setState(() {
      _futureKey = UniqueKey();
    });
  }

  Future<void> _toggleCode(String id, bool value) async {
    await Supabase.instance.client
        .from('redeem_codes')
        .update({'is_active': value}).eq('id', id);
    _refresh();
  }

  Future<void> _deleteCode(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Code?'),
        content: const Text('Are you sure you want to delete this code?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await Supabase.instance.client.from('redeem_codes').delete().eq('id', id);
      _refresh();
    }
  }

  void _showCreateCodeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _CreateCodeDialog(
        onSave: (data) async {
          try {
            await Supabase.instance.client.from('redeem_codes').insert(data);
            _refresh();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to create code: $e', style: const TextStyle(color: Colors.white))),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              const Text(
                'Redeem Codes',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showCreateCodeDialog(context),
                icon: const Icon(Icons.add_circle, size: 16),
                label: const Text('Create Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27389A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FutureBuilder(
              key: _futureKey,
              future: _loadCodes(),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF27389A)));
                }
                final codes = snap.data as List;
                return AdminTable(
                  columns: const ['Code', 'Description', 'Claims', 'Max', 'Active', 'Expires', 'Rewards', 'Actions'],
                  rows: codes.map((c) => [
                    Text(
                      c['code'] ?? '',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    c['description'] ?? '-',
                    '${c['current_claims'] ?? 0}',
                    c['max_claims']?.toString() ?? '∞',
                    ToggleCell(
                      value: c['is_active'] as bool? ?? false,
                      onToggle: (v) => _toggleCode(c['id'], v),
                    ),
                    c['expires_at'] != null ? DateTime.parse(c['expires_at']).toString().substring(0, 10) : 'Never',
                    RewardsChip(rewards: {
                      if (c['reward_xp'] != null && c['reward_xp'] > 0) 'xp': c['reward_xp'],
                      if (c['reward_sticker_packs'] != null) 'pack_ids': c['reward_sticker_packs'],
                      if (c['reward_sticker_ids'] != null) 'sticker_ids': c['reward_sticker_ids'],
                      if (c['reward_premium_features'] != null) 'premium_features': c['reward_premium_features'],
                    }),
                    ActionCell(
                      onEdit: null, // Edit code is complicated due to rewards schema format
                      onDelete: () => _deleteCode(c['id']),
                    ),
                  ]).toList(),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _CreateCodeDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const _CreateCodeDialog({required this.onSave});

  @override
  State<_CreateCodeDialog> createState() => _CreateCodeDialogState();
}

class _CreateCodeDialogState extends State<_CreateCodeDialog> {
  final _codeCtrl = TextEditingController(text: 'TASKI-XXXX-XXXX');
  final _descCtrl = TextEditingController();
  final _maxClaimsCtrl = TextEditingController(text: '0'); // 0 = unlimited
  final _xpCtrl = TextEditingController(text: '0');
  final _packIdsCtrl = TextEditingController(); // comma separated
  final _stickerIdsCtrl = TextEditingController(); // comma separated
  bool _premiumBadge = false;
  bool _premiumTrail = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E2128),
      title: const Text('Create Code', style: TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field('Code', _codeCtrl),
            _field('Description', _descCtrl),
            _field('Max Claims (0 for unlimited)', _maxClaimsCtrl, isNumber: true),
            
            const Divider(color: Colors.white24, height: 32),
            const Text('Rewards', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            _field('XP Amount', _xpCtrl, isNumber: true),
            _field('Pack IDs (comma separated)', _packIdsCtrl),
            _field('Sticker IDs (comma separated)', _stickerIdsCtrl),
            
            CheckboxListTile(
              title: const Text('Unlock Premium Badge', style: TextStyle(color: Colors.white70, fontSize: 13)),
              value: _premiumBadge,
              onChanged: (v) => setState(() => _premiumBadge = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: const Color(0xFF27389A),
            ),
            CheckboxListTile(
              title: const Text('Unlock Premium Trail', style: TextStyle(color: Colors.white70, fontSize: 13)),
              value: _premiumTrail,
              onChanged: (v) => setState(() => _premiumTrail = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: const Color(0xFF27389A),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
        ElevatedButton(
          onPressed: () {
            final xp = int.tryParse(_xpCtrl.text) ?? 0;
            final packIds = _packIdsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
            final stickerIds = _stickerIdsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
            
            final List<String> premium = [];
            if (_premiumBadge) premium.add('badge');
            if (_premiumTrail) premium.add('trail');

            final maxClaims = int.tryParse(_maxClaimsCtrl.text) ?? 0;
            
            final data = {
              'code': _codeCtrl.text,
              'description': _descCtrl.text,
              'reward_xp': xp,
              'reward_sticker_packs': packIds,
              'reward_sticker_ids': stickerIds,
              'reward_premium_features': premium,
              'is_active': true,
              'current_claims': 0,
              if (maxClaims > 0) 'max_claims': maxClaims,
            };
            
            widget.onSave(data);
            Navigator.pop(context);
          },
          child: const Text('Create'),
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: const Color(0xFF111318),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          isDense: true,
        ),
      ),
    );
  }
}
