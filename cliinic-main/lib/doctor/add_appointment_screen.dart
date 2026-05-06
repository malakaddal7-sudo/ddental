// lib/doctor/add_appointment_screen.dart
// FIX: المشكل 2 - يحفظ الموعد فعليًا في Firestore
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'doctor_colors.dart';

class AddAppointmentScreen extends StatefulWidget {
  final String? patientName;
  final String? patientId;
  const AddAppointmentScreen({super.key, this.patientName, this.patientId});
  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patient = TextEditingController();
  final _notes = TextEditingController();
  String _type = 'Cleaning';
  DateTime? _date;
  TimeOfDay? _time;
  bool _saving = false;

  final List<String> _types = [
    'Cleaning',
    'Checkup',
    'Root Canal',
    'Extraction',
    'Filling',
    'X-Ray',
    'Surgery',
    'Consultation',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.patientName != null) _patient.text = widget.patientName!;
  }

  @override
  void dispose() {
    _patient.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_date == null) {
      _showSnack('Please select a date', DC.warning);
      return;
    }
    if (_time == null) {
      _showSnack('Please select a time', DC.warning);
      return;
    }
    setState(() => _saving = true);

    try {
      final doctorUid = FirebaseAuth.instance.currentUser?.uid;
      if (doctorUid == null) {
        _showSnack('Not authenticated', DC.danger);
        setState(() => _saving = false);
        return;
      }

      // Get doctor name
      String doctorName = 'Doctor';
      try {
        final dDoc = await FirebaseFirestore.instance
            .collection('doctors')
            .doc(doctorUid)
            .get();
        if (dDoc.exists) {
          final dd = dDoc.data()!;
          doctorName = 'Dr. ${dd['firstName'] ?? ''} ${dd['lastName'] ?? ''}'
              .trim();
        }
      } catch (_) {}

      final dateTime = DateTime(
        _date!.year,
        _date!.month,
        _date!.day,
        _time!.hour,
        _time!.minute,
      );

      final timeStr = _time!.format(context);

      final appointmentData = {
        'patientId': widget.patientId ?? '',
        'patientName': _patient.text.trim(),
        'doctorId': doctorUid,
        'doctorName': doctorName,
        'service': _type,
        'date': Timestamp.fromDate(dateTime),
        'time': timeStr,
        'notes': _notes.text.trim(),
        'status': 'confirmed', // Doctor-added appointments are auto-confirmed
        'createdBy': 'doctor',
        'createdAt': Timestamp.now(),
      };

      final batch = FirebaseFirestore.instance.batch();

      // 1. Global appointments collection
      final ref = FirebaseFirestore.instance.collection('appointments').doc();
      batch.set(ref, appointmentData);

      // 2. Doctor subcollection
      batch.set(
        FirebaseFirestore.instance
            .collection('doctors')
            .doc(doctorUid)
            .collection('appointments')
            .doc(ref.id),
        appointmentData,
      );

      // 3. Patient subcollection (if patientId provided)
      if (widget.patientId != null && widget.patientId!.isNotEmpty) {
        batch.set(
          FirebaseFirestore.instance
              .collection('users')
              .doc(widget.patientId)
              .collection('appointments')
              .doc(ref.id),
          appointmentData,
        );
      }

      await batch.commit();

      if (!mounted) return;
      _showSnack('Appointment added successfully!', DC.green);
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error saving appointment: $e');
      if (mounted) _showSnack('Error saving appointment: $e', DC.danger);
    }

    if (mounted) setState(() => _saving = false);
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: DC.text)),
        backgroundColor: DC.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.5)),
        ),
      ),
    );
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
          'Add Appointment',
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
            _field(
              _patient,
              'Patient Name',
              Icons.person_outline,
              required: true,
            ),
            const SizedBox(height: 14),
            // Type dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: DC.cardDecoration,
              child: Row(
                children: [
                  const Icon(
                    Icons.medical_services_outlined,
                    color: DC.green,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Type',
                    style: TextStyle(color: DC.textSub, fontSize: 12),
                  ),
                  const Spacer(),
                  DropdownButton<String>(
                    value: _type,
                    dropdownColor: DC.card,
                    underline: const SizedBox(),
                    style: const TextStyle(color: DC.text),
                    items: _types
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Date picker
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (ctx, child) => Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(primary: DC.green),
                    ),
                    child: child!,
                  ),
                );
                if (d != null) setState(() => _date = d);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: DC.cardDecoration,
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: DC.green,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _date == null
                          ? 'Select Date'
                          : '${_date!.day}/${_date!.month}/${_date!.year}',
                      style: TextStyle(
                        color: _date == null ? DC.textMuted : DC.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Time picker
            GestureDetector(
              onTap: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 9, minute: 0),
                  builder: (ctx, child) => Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(primary: DC.green),
                    ),
                    child: child!,
                  ),
                );
                if (t != null) setState(() => _time = t);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: DC.cardDecoration,
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: DC.green,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _time == null ? 'Select Time' : _time!.format(context),
                      style: TextStyle(
                        color: _time == null ? DC.textMuted : DC.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _field(
              _notes,
              'Notes (optional)',
              Icons.note_outlined,
              maxLines: 3,
            ),
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
                        'Confirm Appointment',
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

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    bool required = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: c,
      maxLines: maxLines,
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
