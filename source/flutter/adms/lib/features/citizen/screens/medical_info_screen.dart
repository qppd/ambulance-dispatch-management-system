import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/user_error_message.dart';

/// Screen for managing citizen medical information.
/// Accessible from: Profile > Medical Information.
class MedicalInfoScreen extends ConsumerStatefulWidget {
  const MedicalInfoScreen({super.key});

  @override
  ConsumerState<MedicalInfoScreen> createState() => _MedicalInfoScreenState();
}

class _MedicalInfoScreenState extends ConsumerState<MedicalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bloodTypeCtrl;
  late TextEditingController _allergiesCtrl;
  late TextEditingController _conditionsCtrl;
  late TextEditingController _medicationsCtrl;
  late TextEditingController _physicianNameCtrl;
  late TextEditingController _physicianPhoneCtrl;
  bool _isSaving = false;

  static const _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    _bloodTypeCtrl = TextEditingController();
    _allergiesCtrl = TextEditingController();
    _conditionsCtrl = TextEditingController();
    _medicationsCtrl = TextEditingController();
    _physicianNameCtrl = TextEditingController();
    _physicianPhoneCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _bloodTypeCtrl.dispose();
    _allergiesCtrl.dispose();
    _conditionsCtrl.dispose();
    _medicationsCtrl.dispose();
    _physicianNameCtrl.dispose();
    _physicianPhoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final medInfoAsync = ref.watch(citizenMedicalInfoProvider);

    medInfoAsync.whenData((data) {
      if (data == null) return;
      _bloodTypeCtrl.text = data['bloodType'] ?? '';
      _allergiesCtrl.text = data['allergies'] ?? '';
      _conditionsCtrl.text = data['conditions'] ?? '';
      _medicationsCtrl.text = data['medications'] ?? '';
      _physicianNameCtrl.text = data['physicianName'] ?? '';
      _physicianPhoneCtrl.text = data['physicianPhone'] ?? '';
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Medical Information')),
      body: medInfoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(userErrorMessage(e))),
        data: (_) => _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Blood Type',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _bloodTypes.map((bt) {
                final selected = _bloodTypeCtrl.text == bt;
                return ChoiceChip(
                  label: Text(bt),
                  selected: selected,
                  onSelected: (v) => setState(() => _bloodTypeCtrl.text = bt),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(color: selected ? Colors.white : null),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Allergies (medications, food, environmental)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _allergiesCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g., Penicillin, peanuts, bee stings',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            const Text(
              'Medical Conditions',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _conditionsCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g., Diabetes, hypertension, asthma',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            const Text(
              'Current Medications',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _medicationsCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g., Metformin 500mg twice daily',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            const Text(
              'Primary Physician',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _physicianNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Physician Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _physicianPhoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Physician Phone',
                border: OutlineInputBorder(),
                hintText: '+639****',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _saveMedicalInfo,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Medical Information'),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.urgent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.urgent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This information will be shared with emergency responders when you request an ambulance.',
                      style: const TextStyle(fontSize: 12, color: AppColors.urgent),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveMedicalInfo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(citizenServiceProvider).saveMedicalInfo(
            bloodType: _bloodTypeCtrl.text.trim(),
            allergies: _allergiesCtrl.text.trim(),
            conditions: _conditionsCtrl.text.trim(),
            medications: _medicationsCtrl.text.trim(),
            physicianName: _physicianNameCtrl.text.trim(),
            physicianPhone: _physicianPhoneCtrl.text.trim(),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medical information saved.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userErrorMessage(e)), backgroundColor: AppColors.critical),
        );
      }
    } finally {
      if (context.mounted) setState(() => _isSaving = false);
    }
  }
}
