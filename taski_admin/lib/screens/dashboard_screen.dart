import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/admin_table.dart';
import 'packs_tab.dart';
import 'codes_tab.dart';
import 'users_tab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tab = 0;
  // 0=Overview 1=Packs 2=Stickers 3=Codes 4=Users

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111318),
      body: Row(
        children: [
          // Sidebar
          _AdminSidebar(
            currentTab: _tab,
            onTabChange: (t) => setState(() => _tab = t),
          ),
          // Content
          Expanded(
            child: switch (_tab) {
              0 => const _OverviewTab(),
              1 => const PacksTab(),
              2 => const Center(child: Text('Stickers Tab (Coming Soon)', style: TextStyle(color: Colors.white))),
              3 => const CodesTab(),
              4 => const UsersTab(),
              _ => const _OverviewTab(),
            },
          ),
        ],
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  final int currentTab;
  final ValueChanged<int> onTabChange;

  const _AdminSidebar({
    required this.currentTab,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: const Color(0xFF191C23),
      child: Column(
        children: [
          // Logo
          const Padding(
            padding: EdgeInsets.all(24),
            child: Row(
              children: [
                Text('⚡', style: TextStyle(fontSize: 24)),
                SizedBox(width: 10),
                Text(
                  'Taski Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),

          // Nav items
          ...[
            (0, Icons.dashboard_outlined, 'Overview'),
            (1, Icons.auto_awesome_outlined, 'Sticker Packs'),
            (2, Icons.emoji_emotions_outlined, 'Stickers'),
            (3, Icons.redeem_outlined, 'Redeem Codes'),
            (4, Icons.people_outlined, 'Users'),
          ].map((item) => _NavItem(
                index: item.$1,
                icon: item.$2,
                label: item.$3,
                isActive: currentTab == item.$1,
                onTap: () => onTabChange(item.$1),
              )),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.white : Colors.white54;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        color: isActive ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PART 3 - OVERVIEW TAB
// ============================================================================

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _fetchStats(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF27389A)),
          );
        }
        final stats = snap.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Overview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Last updated: ${DateTime.now().toString().substring(0, 16)}',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 32),

              // Stats grid
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _StatCard(
                    label: 'Total Users',
                    value: '${stats['users']}',
                    icon: Icons.people,
                    color: const Color(0xFF27389A),
                  ),
                  _StatCard(
                    label: 'Active Today',
                    value: '${stats["today"]}',
                    icon: Icons.today,
                    color: const Color(0xFF006846),
                  ),
                  _StatCard(
                    label: 'Total Claims',
                    value: '${stats["claims"]}',
                    icon: Icons.redeem,
                    color: const Color(0xFFFF6B35),
                  ),
                  _StatCard(
                    label: 'Packs Sold',
                    value: '${stats["packs"]}',
                    icon: Icons.auto_awesome,
                    color: const Color(0xFF9C27B0),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Recent users table
              const _SectionHeader('Recent Users'),
              const SizedBox(height: 16),
              const _RecentUsersTable(),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, int>> _fetchStats() async {
    final db = Supabase.instance.client;
    final users = await db.from('user_stats').select('id').count(CountOption.exact);
    final today = await db
        .from('user_stats')
        .select('id')
        .gte(
          'last_seen',
          DateTime.now().subtract(const Duration(hours: 24)).toIso8601String(),
        )
        .count(CountOption.exact);
    final claims = await db.from('code_redemptions').select('id').count(CountOption.exact);

    return {
      'users': users.count,
      'today': today.count,
      'claims': claims.count,
      'packs': 0, // Calculate from user_stats if needed
    };
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2128),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _RecentUsersTable extends StatelessWidget {
  const _RecentUsersTable();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Supabase.instance.client
          .from('user_stats')
          .select()
          .order('last_seen', ascending: false)
          .limit(10),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snap.data as List;
        return _AdminTable(
          columns: const ['User ID', 'Last Seen', 'XP', 'Tasks Done'],
          rows: users.map((u) {
            return [
              '${(u['user_id'] as String).substring(0, 8)}...',
              DateTime.parse(u['last_seen']).toString().substring(0, 16),
              '${u['total_xp_earned'] ?? 0}',
              '${u['tasks_completed'] ?? 0}',
            ];
          }).toList(),
        );
      },
    );
  }
}

// ============================================================================
// SHARED WIDGETS
// ============================================================================

class _AdminTable extends StatelessWidget {
  final List<String> columns;
  final List<List<dynamic>> rows;

  const _AdminTable({required this.columns, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2128),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
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
    );
  }
}

