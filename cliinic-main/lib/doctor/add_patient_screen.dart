// lib/doctor/add_patient_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'doctor_colors.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});
  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _dob = TextEditingController();
  final _address = TextEditingController();
  final _bloodType = TextEditingController();
  final _allergies = TextEditingController();
  String _gender = 'Male';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _dob.dispose();
    _address.dispose();
    _bloodType.dispose();
    _allergies.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    try {
      // FIX: Check authentication first and show clear error if not logged in
      final doctorUid = FirebaseAuth.instance.currentUser?.uid;
      if (doctorUid == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Error: Not authenticated. Please log in again.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: DC.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() => _saving = false);
        return;
      }

      // FIX: Use a batch write so both the global patients collection
      // and the doctor's subcollection are written atomically.
      final db = FirebaseFirestore.instance;
      final patientRef = db.collection('patients').doc(); // auto-ID

      final patientData = {
        'patientId': patientRef.id,
        'name': _name.text.trim(),
        'firstName': _name.text.trim().split(' ').first,
        'lastName': _name.text.trim().contains(' ')
            ? _name.text.trim().split(' ').sublist(1).join(' ')
            : '',
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'dob': _dob.text.trim(),
        'address': _address.text.trim(),
        'gender': _gender,
        'bloodType': _bloodType.text.trim(),
        'allergies': _allergies.text.trim(),
        'doctorId': doctorUid,
        'createdAt': Timestamp.now(),
        'source': 'doctor_registered',
        'role': 'patient',
      };

      final batch = db.batch();

      // 1. Global patients collection
      batch.set(patientRef, patientData);

      // 2. Doctor's patients subcollection (for quick lookup)
      batch.set(
        db
            .collection('doctors')
            .doc(doctorUid)
            .collection('patients')
            .doc(patientRef.id),
        patientData,
      );

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: DC.green),
              SizedBox(width: 10),
              Text(
                'Patient registered successfully!',
                style: TextStyle(color: DC.text),
              ),
            ],
          ),
          backgroundColor: DC.card,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: DC.border),
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error saving patient: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to register patient: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: DC.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DC.bg,
      appBar: AppBar(
        backgroundColor: DC.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: DC.text,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Register New Patient',
          style: TextStyle(color: DC.text, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: DC.border),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: DC.greenGlow,
                  shape: BoxShape.circle,
                  border: Border.all(color: DC.border, width: 2),
                ),
                child: const Icon(
                  Icons.person_add_rounded,
                  color: DC.green,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _section('Personal Information'),
            const SizedBox(height: 12),
            _field(_name, 'Full Name', Icons.person_outline, required: true),
            const SizedBox(height: 14),
            _field(
              _email,
              'Email Address',
              Icons.email_outlined,
              type: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            _field(
              _phone,
              'Phone Number',
              Icons.phone_outlined,
              type: TextInputType.phone,
              required: true,
            ),
            const SizedBox(height: 14),
            _field(
              _dob,
              'Date of Birth',
              Icons.cake_outlined,
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime(1990),
                  firstDate: DateTime(1930),
                  lastDate: DateTime.now(),
                  builder: (ctx, child) => Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(primary: DC.green),
                    ),
                    child: child!,
                  ),
                );
                if (d != null) {
                  _dob.text = '${d.day}/${d.month}/${d.year}';
                }
              },
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: DC.cardDecoration,
              child: Row(
                children: [
                  const Icon(Icons.wc_outlined, color: DC.green, size: 18),
                  const SizedBox(width: 10),
                  const Text(
                    'Gender',
                    style: TextStyle(color: DC.textSub, fontSize: 12),
                  ),
                  const Spacer(),
                  DropdownButton<String>(
                    value: _gender,
                    dropdownColor: DC.card,
                    underline: const SizedBox(),
                    style: const TextStyle(color: DC.text),
                    items: ['Male', 'Female']
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) => setState(() => _gender = v!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _field(_address, 'Address', Icons.location_on_outlined),
            const SizedBox(height: 24),
            _section('Medical Information'),
            const SizedBox(height: 12),
            _field(
              _bloodType,
              'Blood Type (e.g. A+)',
              Icons.bloodtype_outlined,
            ),
            const SizedBox(height: 14),
            _field(_allergies, 'Known Allergies', Icons.warning_amber_outlined),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DC.green,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Register Patient',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Text(
    title,
    style: const TextStyle(
      color: DC.green,
      fontWeight: FontWeight.bold,
      fontSize: 13,
      letterSpacing: 0.5,
    ),
  );

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType? type,
    bool required = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: type,
      readOnly: onTap != null,
      onTap: onTap,
      style: const TextStyle(color: DC.text),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: DC.textSub),
        prefixIcon: Icon(icon, color: DC.green, size: 18),
        filled: true,
        fillColor: DC.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DC.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DC.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DC.green, width: 1.5),
        ),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
          : null,
    );
  }
}
