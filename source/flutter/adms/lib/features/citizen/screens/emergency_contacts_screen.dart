import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/user_error_message.dart';

/// Screen for managing citizen emergency contacts.
/// Accessible from: home Quick Services > Emergency Contacts
///                  AND Profile > Emergency Contacts.
class EmergencyContactsScreen extends ConsumerStatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  ConsumerState<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState
    extends ConsumerState<EmergencyContactsScreen> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(citizenEmergencyContactsProvider);
    final hasContacts = contactsAsync.value?.isNotEmpty ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (hasContacts)
            IconButton(
              icon: Icon(_editing ? Icons.check : Icons.edit_outlined),
              onPressed: () => setState(() => _editing = !_editing),
            ),
        ],
      ),
      body: contactsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(userErrorMessage(e))),
        data: (contacts) {
          if (contacts.isEmpty && !_editing) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.contact_phone_outlined,
                    size: 64,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No emergency contacts yet',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add contacts who can be reached in an emergency',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => setState(() => _editing = true),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Contact'),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              final key = contact['key'] as String? ?? '';
              return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.critical.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: AppColors.critical,
                        ),
                      ),
                      title: Text(contact['name'] as String? ?? 'Unknown'),
                      subtitle: Text(
                        '${contact['relation'] ?? 'Contact'} • ${contact['phone'] ?? ''}',
                      ),
                      trailing: _editing
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: AppColors.primary,
                                  ),
                                  onPressed: () => _showAddEditDialog(contact),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.critical,
                                  ),
                                  onPressed: () => _confirmDelete(key, contact['name'] as String?),
                                ),
                              ],
                            )
                          : null,
                      onTap: _editing
                          ? () => _showAddEditDialog(contact)
                          : null,
                    ),
                  )
                  .animate(delay: Duration(milliseconds: 50 * index))
                  .fadeIn();
            },
          );
        },
      ),
      floatingActionButton: _editing
          ? FloatingActionButton.extended(
              onPressed: () => _showAddEditDialog(null),
              icon: const Icon(Icons.add),
              label: const Text('Add Contact'),
              backgroundColor: AppColors.critical,
            )
          : null,
    );
  }

  void _showAddEditDialog(Map<String, dynamic>? existing) {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final phoneCtrl = TextEditingController(text: existing?['phone'] ?? '');
    final relationCtrl = TextEditingController(text: existing?['relation'] ?? '');
    final formKey = GlobalKey<FormState>();
    final isNew = existing == null;
    final contactKey = existing?['key'] as String?;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isNew ? 'Add Contact' : 'Edit Contact'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue:
                    relationCtrl.text.isNotEmpty ? relationCtrl.text : null,
                decoration: const InputDecoration(
                  labelText: 'Relationship',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Parent', child: Text('Parent')),
                  DropdownMenuItem(value: 'Sibling', child: Text('Sibling')),
                  DropdownMenuItem(value: 'Spouse', child: Text('Spouse')),
                  DropdownMenuItem(value: 'Friend', child: Text('Friend')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (v) => relationCtrl.text = v ?? '',
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Select a relationship' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                if (isNew) {
                  await ref.read(citizenServiceProvider).addEmergencyContact(
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        relation: relationCtrl.text.trim(),
                      );
                } else if (contactKey != null) {
                  await ref.read(citizenServiceProvider).updateEmergencyContact(
                        contactKey: contactKey,
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        relation: relationCtrl.text.trim(),
                      );
                }
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contact saved.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(userErrorMessage(e))));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String key, String? name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Remove "$name" from your emergency contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(citizenServiceProvider)
                    .deleteEmergencyContact(key);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contact deleted.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(userErrorMessage(e))),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.critical),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
