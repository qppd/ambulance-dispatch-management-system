import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';

// =============================================================================
// USER MANAGEMENT SCREEN  (Super Admin — wired to Firebase /users)
// =============================================================================

/// Globally-scoped user management screen.
///
/// Streams all users from the Firebase RTDB `/users` node. Supports:
/// - Role-based filtering
/// - Search by name / email
/// - Approve pending accounts
/// - Deactivate / reactivate accounts
class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final _searchCtrl = TextEditingController();
  UserRole? _roleFilter;
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () => _showInviteDialog(context),
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: const Text('Invite User'),
            ),
          ),
        ],
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error loading users: $e',
              style: const TextStyle(color: AppColors.critical)),
        ),
        data: (users) => _buildContent(context, users),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<User> allUsers) {
    final filtered = allUsers.where((u) {
      final matchRole = _roleFilter == null || u.role == _roleFilter;
      final q = _search.trim().toLowerCase();
      final matchSearch = q.isEmpty ||
          u.fullName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);
      return matchRole && matchSearch;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRoleSummary(context, allUsers),
          const SizedBox(height: 28),
          _buildFiltersRow(context),
          const SizedBox(height: 20),
          Text('Users (${filtered.length})',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            _buildEmptyState(context)
          else
            ...filtered.asMap().entries.map(
                  (entry) => _UserRow(
                    user: entry.value,
                    onApprove: () => _approve(context, entry.value),
                    onDeactivate: () => _deactivate(context, entry.value),
                    onReactivate: () => _reactivate(context, entry.value),
                  )
                      .animate(
                          delay: Duration(
                              milliseconds: 40 * entry.key.clamp(0, 15)))
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.05, end: 0),
                ),
        ],
      ),
    );
  }

  Widget _buildRoleSummary(BuildContext context, List<User> users) {
    final counts = <UserRole, int>{};
    for (final u in users) {
      counts[u.role] = (counts[u.role] ?? 0) + 1;
    }
    final items = [
      _RoleStat(UserRole.municipalAdmin, AppColors.municipalAdmin,
          counts[UserRole.municipalAdmin] ?? 0),
      _RoleStat(UserRole.dispatcher, AppColors.dispatcher,
          counts[UserRole.dispatcher] ?? 0),
      _RoleStat(UserRole.driver, AppColors.driver,
          counts[UserRole.driver] ?? 0),
      _RoleStat(UserRole.hospitalStaff, AppColors.hospitalStaff,
          counts[UserRole.hospitalStaff] ?? 0),
      _RoleStat(UserRole.citizen, AppColors.primary,
          counts[UserRole.citizen] ?? 0),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: items
          .map((s) => SizedBox(
                width: 160,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: s.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(s.role.icon, color: s.color, size: 18),
                        ),
                        const SizedBox(height: 10),
                        Text('${s.count}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        Text(s.role.displayName,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ))
          .toList(),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildFiltersRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by name or email',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _search = '');
                      },
                    )
                  : null,
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<UserRole?>(
            value: _roleFilter,
            decoration: const InputDecoration(
              labelText: 'Role',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<UserRole?>(
                  value: null, child: Text('All roles')),
              ...UserRole.values
                  .where((r) => r != UserRole.superAdmin)
                  .map((r) => DropdownMenuItem(
                      value: r, child: Text(r.displayName))),
            ],
            onChanged: (v) => setState(() => _roleFilter = v),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 56, color: AppColors.textMuted),
              const SizedBox(height: 14),
              Text('No users found',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                'Try adjusting the search or role filter.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _approve(BuildContext context, User user) async {
    try {
      await ref.read(userServiceProvider).approveUser(user.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${user.fullName} approved'),
          backgroundColor: AppColors.available,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.critical,
        ));
      }
    }
  }

  Future<void> _deactivate(BuildContext context, User user) async {
    final confirmed = await _confirmDialog(
      context,
      title: 'Deactivate Account',
      message:
          'Deactivate ${user.fullName}? They will be unable to log in.',
      confirmLabel: 'Deactivate',
      isDestructive: true,
    );
    if (!confirmed) return;
    try {
      await ref.read(userServiceProvider).deactivateUser(user.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${user.fullName} deactivated'),
          backgroundColor: AppColors.urgent,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.critical,
        ));
      }
    }
  }

  Future<void> _reactivate(BuildContext context, User user) async {
    try {
      await ref.read(userServiceProvider).reactivateUser(user.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${user.fullName} reactivated'),
          backgroundColor: AppColors.available,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.critical,
        ));
      }
    }
  }

  Future<bool> _confirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    bool isDestructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              FilledButton(
                style: isDestructive
                    ? FilledButton.styleFrom(
                        backgroundColor: AppColors.critical)
                    : null,
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showInviteDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Invite User'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Users register themselves through the app. '
              'Once registered, they appear here for approval.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            SizedBox(height: 12),
            Text(
              'Roles that require approval (dispatcher, driver) '
              'will show as Pending here.',
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// USER ROW WIDGET
// =============================================================================

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.onApprove,
    required this.onDeactivate,
    required this.onReactivate,
  });

  final User user;
  final VoidCallback onApprove;
  final VoidCallback onDeactivate;
  final VoidCallback onReactivate;

  Color get _roleColor {
    switch (user.role) {
      case UserRole.superAdmin:
        return AppColors.superAdmin;
      case UserRole.municipalAdmin:
        return AppColors.municipalAdmin;
      case UserRole.dispatcher:
        return AppColors.dispatcher;
      case UserRole.driver:
        return AppColors.driver;
      case UserRole.citizen:
        return AppColors.primary;
      case UserRole.hospitalStaff:
        return AppColors.hospitalStaff;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInactive = !user.isActive;
    final isPending =
        !user.isApproved && user.role.requiresApproval && user.isActive;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _roleColor.withOpacity(0.15),
          child: Text(user.initials,
              style: TextStyle(
                  color: _roleColor, fontWeight: FontWeight.w700)),
        ),
        title: Row(
          children: [
            Text(user.fullName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: isInactive
                          ? TextDecoration.lineThrough
                          : null,
                      color: isInactive ? AppColors.textMuted : null,
                    )),
            const SizedBox(width: 8),
            _StatusBadge(
              label: isInactive
                  ? 'Inactive'
                  : isPending
                      ? 'Pending'
                      : 'Active',
              color: isInactive
                  ? AppColors.outOfService
                  : isPending
                      ? AppColors.urgent
                      : AppColors.available,
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(user.role.icon, size: 12, color: _roleColor),
                const SizedBox(width: 4),
                Text(user.role.displayName,
                    style: TextStyle(
                        fontSize: 11,
                        color: _roleColor,
                        fontWeight: FontWeight.w600)),
                if (user.municipalityName != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.location_city_outlined,
                      size: 11, color: AppColors.textMuted),
                  const SizedBox(width: 2),
                  Text(user.municipalityName!,
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ],
            ),
            Text(
              'Joined ${DateFormat.yMMMd().format(user.createdAt)}',
              style:
                  const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPending)
              Tooltip(
                message: 'Approve account',
                child: IconButton(
                  icon: const Icon(Icons.check_circle_outline,
                      color: AppColors.available),
                  onPressed: onApprove,
                ),
              ),
            if (!isInactive && !isPending)
              Tooltip(
                message: 'Deactivate account',
                child: IconButton(
                  icon: const Icon(Icons.block_outlined,
                      color: AppColors.critical),
                  onPressed: onDeactivate,
                ),
              ),
            if (isInactive)
              Tooltip(
                message: 'Reactivate account',
                child: IconButton(
                  icon: const Icon(Icons.restore_outlined,
                      color: AppColors.available),
                  onPressed: onReactivate,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// HELPERS
// =============================================================================

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

class _RoleStat {
  const _RoleStat(this.role, this.color, this.count);
  final UserRole role;
  final Color color;
  final int count;
}
