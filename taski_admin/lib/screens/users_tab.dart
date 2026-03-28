import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/admin_table.dart';

class UsersTab extends StatelessWidget {
  const UsersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Users',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FutureBuilder(
              future: Supabase.instance.client
                  .from('user_stats')
                  .select()
                  .order('last_seen', ascending: false)
                  .limit(100),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF27389A)));
                }
                final users = snap.data as List;
                return AdminTable(
                  columns: const ['User ID', 'Last Seen', 'XP', 'Tasks Done', 'Packs Owned', 'Version'],
                  rows: users.map((u) {
                    final packsOwned = (u['packs_owned'] as List?)?.length ?? 0;
                    return [
                      '${(u['user_id'] as String).substring(0, 12)}...',
                      DateTime.parse(u['last_seen']).toString().substring(0, 16),
                      '${u['total_xp_earned'] ?? 0}',
                      '${u['tasks_completed'] ?? 0}',
                      '$packsOwned',
                      u['app_version'] ?? '-',
                    ];
                  }).toList(),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
