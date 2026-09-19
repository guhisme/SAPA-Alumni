import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/admin_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/search_field.dart';
import '../shared/whatsapp_compose_screen.dart';

/// Pilih alumni penerima lalu lanjut ke layar tulis pesan.
class AdminWhatsappScreen extends StatefulWidget {
  const AdminWhatsappScreen({super.key});

  @override
  State<AdminWhatsappScreen> createState() => _AdminWhatsappScreenState();
}

class _AdminWhatsappScreenState extends State<AdminWhatsappScreen> {
  final _searchC = TextEditingController();
  final Set<String> _selected = {};
  String _query = '';

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  void _next(List<UserModel> users) {
    final targets = users
        .where((u) => _selected.contains(u.uid))
        .map((u) => WaTarget(name: u.name, phone: u.phone))
        .toList();
    if (targets.isEmpty) {
      AppSnackbar.error(context, 'Pilih minimal satu penerima.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WhatsappComposeScreen(targets: targets),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Kirim WhatsApp')),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<UserModel>>(
          stream: AdminService.instance.watchUsers(role: Roles.alumni),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const LoadingView(message: 'Memuat daftar alumni...');
            }
            if (snap.hasError) {
              return const ErrorView(message: 'Gagal memuat daftar alumni.');
            }

            final all = snap.data ?? [];
            final q = _query.trim().toLowerCase();
            final users = q.isEmpty
                ? all
                : all
                    .where((u) => u.name.toLowerCase().contains(q))
                    .toList();
            final selectable = users
                .where((u) => Validators.phone(u.phone) == null)
                .toList();

            if (all.isEmpty) {
              return const EmptyState(
                icon: Icons.people_outline,
                title: 'Belum ada alumni terdaftar',
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: SearchField(
                    controller: _searchC,
                    hint: 'Cari nama alumni',
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => setState(() {
                          _selected.addAll(selectable.map((u) => u.uid));
                        }),
                        icon: const Icon(Icons.select_all, size: 18),
                        label: const Text('Pilih semua'),
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() => _selected.clear()),
                        icon: const Icon(Icons.clear, size: 18),
                        label: const Text('Kosongkan'),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Text(
                          '${_selected.length} dipilih',
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.textGrey),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: users.isEmpty
                      ? const EmptyState(
                          icon: Icons.search_off,
                          title: 'Alumni tidak ditemukan',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: users.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final u = users[i];
                            final valid = Validators.phone(u.phone) == null;
                            return Card(
                              child: CheckboxListTile(
                                value: _selected.contains(u.uid),
                                onChanged: valid
                                    ? (checked) => setState(() {
                                          if (checked == true) {
                                            _selected.add(u.uid);
                                          } else {
                                            _selected.remove(u.uid);
                                          }
                                        })
                                    : null,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: Text(
                                  u.name.isEmpty ? '(Tanpa nama)' : u.name,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  valid
                                      ? u.phone
                                      : 'Nomor WhatsApp belum valid',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: valid
                                        ? AppColors.textGrey
                                        : AppColors.danger,
                                  ),
                                ),
                                secondary: CircleAvatar(
                                  backgroundColor: AppColors.primarySoft,
                                  child: Text(
                                    u.name.isEmpty
                                        ? '?'
                                        : Fmt.initials(u.name),
                                    style: const TextStyle(
                                      color: AppColors.primaryDark,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: ElevatedButton.icon(
                      onPressed:
                          _selected.isEmpty ? null : () => _next(all),
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: Text('Tulis pesan (${_selected.length})'),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
