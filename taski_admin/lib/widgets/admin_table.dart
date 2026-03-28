import 'package:flutter/material.dart';

class AdminTable extends StatelessWidget {
  final List<String> columns;
  final List<List<dynamic>> rows;

  const AdminTable({super.key, required this.columns, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2128),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            dataTextStyle: const TextStyle(color: Colors.white70),
            columns: columns.map((c) => DataColumn(label: Text(c))).toList(),
            rows: rows.map((row) {
              return DataRow(
                cells: row.map((cell) {
                  if (cell is Widget) return DataCell(cell);
                  return DataCell(Text(cell.toString()));
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class ToggleCell extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onToggle;

  const ToggleCell({super.key, required this.value, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onToggle,
      activeColor: const Color(0xFF27389A),
    );
  }
}

class NumberCell extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const NumberCell({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove, size: 16, color: Colors.white54),
          onPressed: () => onChanged(value - 1),
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(width: 8),
        Text('$value'),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.add, size: 16, color: Colors.white54),
          onPressed: () => onChanged(value + 1),
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

class ActionCell extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ActionCell({super.key, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onEdit != null)
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.white70),
            onPressed: onEdit,
          ),
        if (onDelete != null)
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
            onPressed: onDelete,
          ),
      ],
    );
  }
}

class RewardsChip extends StatelessWidget {
  final dynamic rewards;

  const RewardsChip({super.key, required this.rewards});

  @override
  Widget build(BuildContext context) {
    if (rewards == null || rewards is! Map) {
      return const Text('-');
    }

    final List<Widget> chips = [];
    final map = rewards as Map;
    if (map['xp'] != null) {
      chips.add(_chip('${map['xp']} XP', const Color(0xFF6366F1)));
    }
    if (map['pack_ids'] != null && (map['pack_ids'] as List).isNotEmpty) {
      chips.add(_chip('${(map['pack_ids'] as List).length} Packs', const Color(0xFF10B981)));
    }
    if (map['sticker_ids'] != null && (map['sticker_ids'] as List).isNotEmpty) {
      chips.add(_chip('${(map['sticker_ids'] as List).length} Stickers', const Color(0xFFF59E0B)));
    }
    
    if (chips.isEmpty) return const Text('-');

    return Wrap(spacing: 8, runSpacing: 4, children: chips);
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
