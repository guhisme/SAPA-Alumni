import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/admin_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/search_field.dart';
import '../shared/alumni_detail_screen.dart';
import 'admin_user_detail_screen.dart';

/// Daftar pengguna: semua, alumni saja, BKK saja.
class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Pengguna'),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textGrey,
            indicatorColor: AppColors.primary,
            labelStyle: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: 'Semua'),
              Tab(text: 'Alumni'),
              Tab(text: 'BKK'),
            ],
          ),
        ),
        body: const SafeArea(
          top: false,
          child: TabBarView(
            children: [
              _UserList(role: null),
              _UserList(role: Roles.alumni),
              _UserList(role: Roles.bkk),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserList extends StatefulWidget {
  final String? role;
  const _UserList({this.role});

  @override
  State<_UserList> createState() => _UserListState();
}

class _UserListState extends State<_UserList> {
  final _searchC = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  Color _roleColor(String role) {
    switch (role) {
      case Roles.admin:
        return AppColors.danger;
      case Roles.bkk:
        return AppColors.info;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: AdminService.instance.watchUsers(role: widget.role),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingView(message: 'Memuat pengguna...');
        }
        if (snap.hasError) {
          return const ErrorView(message: 'Gagal memuat data pengguna.');
        }
        final all = snap.data ?? [];
        final q = _query.trim().toLowerCase();
        final users = q.isEmpty
            ? all
            : all
                .where((u) =>
                    u.name.toLowerCase().contains(q) ||
                    u.email.toLowerCase().contains(q))
                .toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SearchField(
                controller: _searchC,
                hint: 'Cari nama atau email',
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: users.isEmpty
                  ? EmptyState(
                      icon: Icons.people_outline,
                      title: all.isEmpty
                          ? 'Belum ada pengguna'
                          : 'Pengguna tidak ditemukan',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final u = users[i];
                        return Card(
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            leading: CircleAvatar(
                              backgroundColor:
                                  _roleColor(u.role).withValues(alpha: 0.12),
                              child: Text(
                                u.name.isEmpty ? '?' : Fmt.initials(u.name),
                                style: TextStyle(
                                  color: _roleColor(u.role),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            title: Text(
                              u.name.isEmpty ? '(Tanpa nama)' : u.name,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              u.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    _roleColor(u.role).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                u.role,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _roleColor(u.role),
                                ),
                              ),
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => u.role == Roles.alumni
                                    ? AlumniDetailScreen(uid: u.uid)
                                    : AdminUserDetailScreen(user: u),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
