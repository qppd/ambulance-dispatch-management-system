import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';

/// Full electronic Patient Care Report form.
/// Captures patient demographics, vitals, interventions, and handover info.
class EpcrFormScreen extends ConsumerStatefulWidget {
  final String municipalityId;
  final String incidentId;
  final String unitId;

  const EpcrFormScreen({
    super.key,
    required this.municipalityId,
    required this.incidentId,
    required this.unitId,
  });

  @override
  ConsumerState<EpcrFormScreen> createState() => _EpcrFormScreenState();
}

class _EpcrFormScreenState extends ConsumerState<EpcrFormScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Patient demographics
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  String _gender = 'male';
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // Clinical
  final _chiefComplaintCtrl = TextEditingController();
  final _hpiCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _medicationsCtrl = TextEditingController();
  final _pmhCtrl = TextEditingController();

  // Vitals
  final _systolicCtrl = TextEditingController();
  final _diastolicCtrl = TextEditingController();
  final _heartRateCtrl = TextEditingController();
  final _respRateCtrl = TextEditingController();
  final _spo2Ctrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  String _loc = 'Alert';

  // Treatments
  final _treatmentsCtrl = TextEditingController();
  final _medsGivenCtrl = TextEditingController();
  final _procedureNotesCtrl = TextEditingController();

  // Handover
  final _hospitalNameCtrl = TextEditingController();
  final _receivingStaffCtrl = TextEditingController();
  final _handoverNotesCtrl = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _firstNameCtrl, _lastNameCtrl, _ageCtrl, _addressCtrl, _phoneCtrl,
      _chiefComplaintCtrl, _hpiCtrl, _allergiesCtrl, _medicationsCtrl, _pmhCtrl,
      _systolicCtrl, _diastolicCtrl, _heartRateCtrl, _respRateCtrl, _spo2Ctrl, _tempCtrl,
      _treatmentsCtrl, _medsGivenCtrl, _procedureNotesCtrl,
      _hospitalNameCtrl, _receivingStaffCtrl, _handoverNotesCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Care Report'),
        backgroundColor: AppColors.driver,
        foregroundColor: Colors.white,
        actions: [
          if (_currentStep == 4)
            TextButton.icon(
              onPressed: _isSubmitting ? null : _submitReport,
              icon: const Icon(Icons.send, color: Colors.white, size: 18),
              label: const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 4) {
              setState(() => _currentStep++);
            } else {
              _submitReport();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) setState(() => _currentStep--);
          },
          onStepTapped: (step) => setState(() => _currentStep = step),
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  if (_currentStep < 4)
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.driver),
                      child: const Text('Next'),
                    )
                  else
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReport,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.available),
                      child: _isSubmitting
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Submit Report'),
                    ),
                  const SizedBox(width: 12),
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Patient Info'),
              subtitle: const Text('Demographics & contact'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: _buildPatientInfoStep(),
            ),
            Step(
              title: const Text('Clinical'),
              subtitle: const Text('Complaint & history'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: _buildClinicalStep(),
            ),
            Step(
              title: const Text('Vitals'),
              subtitle: const Text('Vital signs assessment'),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
              content: _buildVitalsStep(),
            ),
            Step(
              title: const Text('Interventions'),
              subtitle: const Text('Treatments administered'),
              isActive: _currentStep >= 3,
              state: _currentStep > 3 ? StepState.complete : StepState.indexed,
              content: _buildInterventionsStep(),
            ),
            Step(
              title: const Text('Handover'),
              subtitle: const Text('Hospital & receiving staff'),
              isActive: _currentStep >= 4,
              state: _currentStep > 4 ? StepState.complete : StepState.indexed,
              content: _buildHandoverStep(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientInfoStep() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _firstNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _lastNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _ageCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _gender = v ?? 'male'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressCtrl,
          decoration: const InputDecoration(
            labelText: 'Address',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on_outlined, size: 20),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Contact Number',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone_outlined, size: 20),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildClinicalStep() {
    return Column(
      children: [
        TextFormField(
          controller: _chiefComplaintCtrl,
          decoration: const InputDecoration(
            labelText: 'Chief Complaint *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.medical_services_outlined, size: 20),
          ),
          maxLines: 2,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Chief complaint is required';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _hpiCtrl,
          decoration: const InputDecoration(
            labelText: 'History of Present Illness',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _allergiesCtrl,
          decoration: const InputDecoration(
            labelText: 'Allergies (comma-separated)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.warning_amber, size: 20),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _medicationsCtrl,
          decoration: const InputDecoration(
            labelText: 'Current Medications (comma-separated)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.medication_outlined, size: 20),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _pmhCtrl,
          decoration: const InputDecoration(
            labelText: 'Past Medical History (comma-separated)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.history, size: 20),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildVitalsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Blood Pressure',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _systolicCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Systolic (mmHg)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('/', style: TextStyle(fontSize: 20)),
            ),
            Expanded(
              child: TextFormField(
                controller: _diastolicCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Diastolic (mmHg)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _heartRateCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Heart Rate (bpm)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.favorite_outline, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _respRateCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Resp. Rate',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.air, size: 20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _spo2Ctrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'SpO2 (%)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _tempCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Temp (°C)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.thermostat_outlined, size: 20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _loc,
          decoration: const InputDecoration(
            labelText: 'Level of Consciousness (AVPU)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.psychology_outlined, size: 20),
          ),
          items: const [
            DropdownMenuItem(value: 'Alert', child: Text('Alert')),
            DropdownMenuItem(value: 'Verbal', child: Text('Verbal')),
            DropdownMenuItem(value: 'Pain', child: Text('Pain')),
            DropdownMenuItem(value: 'Unresponsive', child: Text('Unresponsive')),
          ],
          onChanged: (v) => setState(() => _loc = v ?? 'Alert'),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildInterventionsStep() {
    return Column(
      children: [
        TextFormField(
          controller: _treatmentsCtrl,
          decoration: const InputDecoration(
            labelText: 'Treatments Administered (comma-separated)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.healing, size: 20),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _medsGivenCtrl,
          decoration: const InputDecoration(
            labelText: 'Medications Given (comma-separated)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.medication, size: 20),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _procedureNotesCtrl,
          decoration: const InputDecoration(
            labelText: 'Procedure Notes',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildHandoverStep() {
    return Column(
      children: [
        TextFormField(
          controller: _hospitalNameCtrl,
          decoration: const InputDecoration(
            labelText: 'Destination Hospital',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.local_hospital_outlined, size: 20),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _receivingStaffCtrl,
          decoration: const InputDecoration(
            labelText: 'Receiving Staff Name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person_outline, size: 20),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _handoverNotesCtrl,
          decoration: const InputDecoration(
            labelText: 'Handover Notes',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.available.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.available.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.access_time, color: AppColors.available),
              const SizedBox(width: 12),
              Text(
                'Handover Time: ${_formatNow()}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  String _formatNow() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} — '
        '${now.day}/${now.month}/${now.year}';
  }

  List<String> _splitCsv(String text) {
    return text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  Future<void> _submitReport() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      final pcrService = ref.read(patientCareReportServiceProvider);

      final report = await pcrService.createReport(
        municipalityId: widget.municipalityId,
        incidentId: widget.incidentId,
        unitId: widget.unitId,
        createdByUid: user.id,
        createdByName: user.fullName,
        chiefComplaint: _chiefComplaintCtrl.text.trim(),
        patientFirstName: _firstNameCtrl.text.trim().isEmpty ? null : _firstNameCtrl.text.trim(),
        patientLastName: _lastNameCtrl.text.trim().isEmpty ? null : _lastNameCtrl.text.trim(),
        patientAge: int.tryParse(_ageCtrl.text.trim()),
        patientGender: _gender,
      );

      // Update vitals
      await pcrService.updateVitals(
        municipalityId: widget.municipalityId,
        reportId: report.id,
        systolicBP: int.tryParse(_systolicCtrl.text.trim()),
        diastolicBP: int.tryParse(_diastolicCtrl.text.trim()),
        heartRate: int.tryParse(_heartRateCtrl.text.trim()),
        respiratoryRate: int.tryParse(_respRateCtrl.text.trim()),
        oxygenSaturation: double.tryParse(_spo2Ctrl.text.trim()),
        temperature: double.tryParse(_tempCtrl.text.trim()),
        levelOfConsciousness: _loc,
      );

      // Update treatments
      final treatments = _splitCsv(_treatmentsCtrl.text);
      final medsGiven = _splitCsv(_medsGivenCtrl.text);
      if (treatments.isNotEmpty || medsGiven.isNotEmpty || _procedureNotesCtrl.text.trim().isNotEmpty) {
        await pcrService.updateTreatments(
          municipalityId: widget.municipalityId,
          reportId: report.id,
          treatmentsAdministered: treatments,
          medicationsGiven: medsGiven,
          procedureNotes: _procedureNotesCtrl.text.trim().isEmpty ? null : _procedureNotesCtrl.text.trim(),
        );
      }

      // Record handover
      if (_hospitalNameCtrl.text.trim().isNotEmpty && _receivingStaffCtrl.text.trim().isNotEmpty) {
        await pcrService.recordHandover(
          municipalityId: widget.municipalityId,
          reportId: report.id,
          hospitalId: '',
          hospitalName: _hospitalNameCtrl.text.trim(),
          receivingStaffName: _receivingStaffCtrl.text.trim(),
          handoverNotes: _handoverNotesCtrl.text.trim().isEmpty ? null : _handoverNotesCtrl.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient Care Report submitted successfully.'),
            backgroundColor: AppColors.available,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting report: $e'), backgroundColor: AppColors.critical),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
