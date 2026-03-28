import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/admin_table.dart';

class PacksTab extends StatefulWidget {
  const PacksTab({super.key});

  @override
  State<PacksTab> createState() => _PacksTabState();
}

class _PacksTabState extends State<PacksTab> {
  List<Map<String, dynamic>> _packs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await Supabase.instance.client
        .from('sticker_packs')
        .select()
        .order('display_order');
    setState(() {
      _packs = List<Map<String, dynamic>>.from(res);
    });
  }

  Future<void> _toggleField(String id, String field, bool value) async {
    await Supabase.instance.client
        .from('sticker_packs')
        .update({field: value}).eq('id', id);
    await _load();
  }

  Future<void> _updateOrder(String id, int value) async {
    await Supabase.instance.client
        .from('sticker_packs')
        .update({'display_order': value}).eq('id', id);
    await _load();
  }

  Future<void> _deletePack(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pack?'),
        content: const Text('Are you sure you want to delete this pack?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await Supabase.instance.client.from('sticker_packs').delete().eq('id', id);
      await _load();
    }
  }

  void _showAddPackDialog(BuildContext context, [Map<String, dynamic>? editPack]) {
    showDialog(
      context: context,
      builder: (_) => _PackDialog(
        initialPack: editPack,
        onSave: (data) async {
          if (editPack == null) {
            await Supabase.instance.client.from('sticker_packs').insert(data);
          } else {
            await Supabase.instance.client.from('sticker_packs').update(data).eq('id', editPack['id']);
          }
          await _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with Add button
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              const Text(
                'Sticker Packs',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showAddPackDialog(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Pack'),
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

        // Packs table
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AdminTable(
              columns: const ['Name', 'XP Cost', 'Active', 'Featured', 'Order', 'Stickers', 'Actions'],
              rows: _packs.map((p) => [
                p['name'] as String? ?? '-',
                '${p['xp_cost'] ?? 0} XP',
                ToggleCell(
                  value: p['is_active'] as bool? ?? false,
                  onToggle: (v) => _toggleField(p['id'], 'is_active', v),
                ),
                ToggleCell(
                  value: p['is_featured'] as bool? ?? false,
                  onToggle: (v) => _toggleField(p['id'], 'is_featured', v),
                ),
                NumberCell(
                  value: p['display_order'] as int? ?? 0,
                  onChanged: (v) => _updateOrder(p['id'], v),
                ),
                '${(p['sticker_ids'] as List?)?.length ?? 0}',
                ActionCell(
                  onEdit: () => _showAddPackDialog(context, p),
                  onDelete: () => _deletePack(p['id']),
                ),
              ]).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _PackDialog extends StatefulWidget {
  final Map<String, dynamic>? initialPack;
  final Function(Map<String, dynamic>) onSave;

  const _PackDialog({this.initialPack, required this.onSave});

  @override
  State<_PackDialog> createState() => _PackDialogState();
}

class _PackDialogState extends State<_PackDialog> {
  final _idCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _xpCostCtrl = TextEditingController(text: '0');
  final _emojiCtrl = TextEditingController();
  final _stickerIdsCtrl = TextEditingController(); // Comma separated

  @override
  void initState() {
    super.initState();
    if (widget.initialPack != null) {
      final p = widget.initialPack!;
      _idCtrl.text = p['id'] ?? '';
      _nameCtrl.text = p['name'] ?? '';
      _descCtrl.text = p['description'] ?? '';
      _xpCostCtrl.text = (p['xp_cost'] ?? 0).toString();
      _emojiCtrl.text = p['cover_emoji'] ?? '';
      _stickerIdsCtrl.text = (p['sticker_ids'] as List?)?.join(',') ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E2128),
      title: Text(widget.initialPack == null ? 'New Pack' : 'Edit Pack', style: const TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field('ID (e.g. nature_pack)', _idCtrl, enabled: widget.initialPack == null),
            _field('Name', _nameCtrl),
            _field('Description', _descCtrl),
            _field('XP Cost', _xpCostCtrl, isNumber: true),
            _field('Cover Emoji', _emojiCtrl),
            _field('Sticker IDs (comma separated)', _stickerIdsCtrl),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
        ElevatedButton(
          onPressed: () {
            final data = {
              if (widget.initialPack == null) 'id': _idCtrl.text,
              'name': _nameCtrl.text,
              'description': _descCtrl.text,
              'xp_cost': int.tryParse(_xpCostCtrl.text) ?? 0,
              'cover_emoji': _emojiCtrl.text,
              'sticker_ids': _stickerIdsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
              // default values for new
              if (widget.initialPack == null) 'is_active': true,
              if (widget.initialPack == null) 'is_featured': false,
              if (widget.initialPack == null) 'display_order': 0,
            };
            widget.onSave(data);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl, {bool isNumber = false, bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        enabled: enabled,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: const Color(0xFF111318),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
