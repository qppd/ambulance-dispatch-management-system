import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';

/// Staff management screen — Drivers management.
class StaffScreen extends ConsumerStatefulWidget {
  final String municipalityId;

  const StaffScreen({required this.municipalityId, super.key});

  @override
  ConsumerState<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends ConsumerState<StaffScreen> {
  String _search = '';
  final _searchCtrl = TextEditingController();
  User? _selectedUser;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(municipalityUsersProvider(widget.municipalityId));
    final isWide = MediaQuery.of(context).size.width > 1100;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Staff', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    Text('Manage ambulance crew for your municipality', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Invite Crew'),
                onPressed: () => _showInviteDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Search
          SizedBox(
            width: 360,
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name or email…',
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                suffixIcon: _search.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); })
                    : null,
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),
          const SizedBox(height: 16),

          // ─── Content
          Expanded(
            child: usersAsync.when(
              data: (all) {
                final crew = _filterUsers(all.where((u) => u.role == UserRole.driver).toList());

                return _StaffList(
                  users: crew,
                  roleColor: AppColors.driver,
                  onSelect: (u) => setState(() => _selectedUser = u == _selectedUser ? null : u),
                  selectedUser: _selectedUser,
                  isWide: isWide,
                  onApprove: (u) => _approve(u),
                  onToggleActive: (u) => _toggleActive(u),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: AppColors.critical))),
            ),
          ),
        ],
      ),
    );
  }

  List<User> _filterUsers(List<User> users) {
    if (_search.isEmpty) return users;
    return users.where((u) =>
      u.fullName.toLowerCase().contains(_search) ||
      u.email.toLowerCase().contains(_search)
    ).toList();
  }

  Future<void> _approve(User user) async {
    final svc = ref.read(userServiceProvider);
    try {
      await svc.approveUser(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${user.fullName} approved'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _toggleActive(User user) async {
    final svc = ref.read(userServiceProvider);
    try {
      if (user.isActive) {
        await svc.deactivateUser(user.id);
      } else {
        await svc.reactivateUser(user.id);
      }
      setState(() => _selectedUser = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${user.fullName} ${user.isActive ? "deactivated" : "reactivated"}'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
    }
  }

  void _showInviteDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite Crew Member'),
        content: SizedBox(
          width: 380,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'An invite record will be created. Share the municipality ID with the crew member so they can register.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'crew@example.com',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final dbRef = ref.read(databaseRefProvider);
                final token = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
                await dbRef.child('invites').child(token).set({
                  'email': emailCtrl.text.trim(),
                  'role': UserRole.driver.name,
                  'municipalityId': widget.municipalityId,
                  'createdAt': DateTime.now().toIso8601String(),
                  'used': false,
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Invite created for ${emailCtrl.text.trim()} (token: $token)'),
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Create Invite'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Staff List
// =============================================================================

class _StaffList extends StatelessWidget {
  final List<User> users;
  final Color roleColor;
  final User? selectedUser;
  final bool isWide;
  final void Function(User) onSelect, onApprove, onToggleActive;

  const _StaffList({
    required this.users,
    required this.roleColor,
    required this.selectedUser,
    required this.isWide,
    required this.onSelect,
    required this.onApprove,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('No crew registered', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    final listWidget = ListView.separated(
      itemCount: users.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final u = users[i];
        final isSelected = selectedUser?.id == u.id;
        return _UserTile(
          user: u,
          roleColor: roleColor,
          isSelected: isSelected,
          onTap: () => onSelect(u),
          onApprove: () => onApprove(u),
          onToggleActive: () => onToggleActive(u),
        ).animate(delay: Duration(milliseconds: 30 * i)).fadeIn();
      },
    );

    if (!isWide || selectedUser == null) return listWidget;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: listWidget),
        const VerticalDivider(width: 1),
        Expanded(child: _UserDetailPanel(user: selectedUser!, roleColor: roleColor, onApprove: () => onApprove(selectedUser!), onToggleActive: () => onToggleActive(selectedUser!))),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// User Tile
// -----------------------------------------------------------------------------

class _UserTile extends StatelessWidget {
  final User user;
  final Color roleColor;
  final bool isSelected;
  final VoidCallback onTap, onApprove, onToggleActive;

  const _UserTile({
    required this.user,
    required this.roleColor,
    required this.isSelected,
    required this.onTap,
    required this.onApprove,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: isSelected,
      selectedTileColor: roleColor.withOpacity(0.06),
      leading: CircleAvatar(
        backgroundColor: roleColor.withOpacity(0.15),
        child: Text(user.initials, style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
      title: Row(
        children: [
          Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          if (!user.isApproved)
            _badge('Pending', AppColors.urgent),
          if (!user.isActive)
            _badge('Inactive', AppColors.outOfService),
        ],
      ),
      subtitle: Text(user.email, style: const TextStyle(fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!user.isApproved)
            TextButton(onPressed: onApprove, child: const Text('Approve')),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'toggle') onToggleActive();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'toggle',
                child: Row(children: [
                  Icon(user.isActive ? Icons.block : Icons.check_circle, size: 16),
                  const SizedBox(width: 8),
                  Text(user.isActive ? 'Deactivate' : 'Reactivate'),
                ]),
              ),
            ],
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(5)),
      child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }
}

// -----------------------------------------------------------------------------
// User Detail Panel
// -----------------------------------------------------------------------------

class _UserDetailPanel extends StatelessWidget {
  final User user;
  final Color roleColor;
  final VoidCallback onApprove, onToggleActive;

  const _UserDetailPanel({
    required this.user,
    required this.roleColor,
    required this.onApprove,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: roleColor.withOpacity(0.15),
                  child: Text(user.initials, style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 22)),
                ),
                const SizedBox(height: 12),
                Text(user.fullName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(user.role.name, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          _detailRow(context, Icons.email_outlined, 'Email', user.email),
          if (user.phoneNumber != null) _detailRow(context, Icons.phone_outlined, 'Phone', user.phoneNumber!),
          _detailRow(context, Icons.calendar_today_outlined, 'Joined', DateFormat('MMM d, yyyy').format(user.createdAt)),
          if (user.lastLoginAt != null) _detailRow(context, Icons.access_time, 'Last Login', DateFormat('MMM d, yyyy HH:mm').format(user.lastLoginAt!)),
          const SizedBox(height: 8),
          _statusChip('Verified', user.isVerified, AppColors.available, context),
          const SizedBox(height: 4),
          _statusChip('Approved', user.isApproved, AppColors.available, context),
          const SizedBox(height: 4),
          _statusChip('Active', user.isActive, AppColors.available, context),
          const SizedBox(height: 20),
          if (!user.isApproved)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Approve Account'),
                onPressed: onApprove,
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: Icon(user.isActive ? Icons.block : Icons.check_circle, size: 16),
              label: Text(user.isActive ? 'Deactivate Account' : 'Reactivate Account'),
              style: OutlinedButton.styleFrom(foregroundColor: user.isActive ? AppColors.critical : AppColors.available),
              onPressed: onToggleActive,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                Text(value, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, bool active, Color color, BuildContext context) {
    return Row(
      children: [
        Icon(active ? Icons.radio_button_checked : Icons.radio_button_off, size: 14, color: active ? color : AppColors.textMuted),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: active ? color : AppColors.textMuted)),
      ],
    );
  }
}