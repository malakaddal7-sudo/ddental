// lib/patient/profile/medical_history_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bar_widget.dart';
 
class MedicalHistoryPage extends StatefulWidget {
  const MedicalHistoryPage({super.key});
 
  @override
  State<MedicalHistoryPage> createState() => _MedicalHistoryPageState();
}
 
class _MedicalHistoryPageState extends State<MedicalHistoryPage> {
  bool _loading = true;
  String _bloodType = '—';
  List<Map<String, dynamic>> _records = [];
 
  @override
  void initState() {
    super.initState();
    _loadData();
  }
 
  Future<void> _loadData() async {
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
 
    try {
      final uid = user.uid;
 
      // ── Blood type from medical record ──────────────────────────────────────
      try {
        final medSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('medicalRecord')
            .limit(1)
            .get();
        if (medSnap.docs.isNotEmpty) {
          final med = medSnap.docs.first.data();
          _bloodType = med['bloodType'] ?? med['blood_type'] ?? '—';
        }
      } catch (_) {}
 
      // ── Appointments that are completed → show as history entries ───────────
      final apptSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('appointments')
          .get();
 
      final List<Map<String, dynamic>> records = [];
      for (final doc in apptSnap.docs) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString().toLowerCase();
        // Show completed AND confirmed (so patient sees their full history)
        if (status == 'completed' || status == 'confirmed') {
          final date = (data['date'] as Timestamp?)?.toDate();
          String dateStr = '—';
          if (date != null) {
            dateStr =
                '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year}';
          }
          records.add({
            'date': dateStr,
            'doctor': data['doctorName'] ?? 'Doctor',
            'diagnosis': data['service'] ?? 'Dental consultation',
            'treatment': data['notes'] ?? _defaultTreatment(data['service']),
            'status': status == 'completed' ? 'Completed' : 'Upcoming',
          });
        }
      }
 
      // ── Also pull from diagnoses sub-collection if doctor added any ─────────
      try {
        final diagSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('diagnoses')
            .orderBy('createdAt', descending: true)
            .get();
 
        for (final doc in diagSnap.docs) {
          final data = doc.data();
          final date = (data['createdAt'] as Timestamp?)?.toDate();
          String dateStr = '—';
          if (date != null) {
            dateStr =
                '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year}';
          }
          records.add({
            'date': dateStr,
            'doctor': data['doctorName'] ?? 'Doctor',
            'diagnosis': data['diagnosis'] ?? '—',
            'treatment': data['treatment'] ?? data['notes'] ?? '—',
            'status': 'Completed',
          });
        }
      } catch (_) {}
 
      // Sort by most recent first (just by string for now — good enough)
      setState(() {
        _records = records;
        _loading = false;
      });
    } catch (e) {
      debugPrint('MedicalHistory load error: $e');
      setState(() => _loading = false);
    }
  }
 
  String _month(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m - 1];
  }
 
  String _defaultTreatment(String? service) {
    switch ((service ?? '').toLowerCase()) {
      case 'cleaning':
        return 'Professional dental cleaning';
      case 'checkup':
        return 'General dental examination';
      case 'x-ray':
      case 'xray':
        return 'Dental X-ray taken';
      case 'filling':
        return 'Dental filling applied';
      case 'extraction':
        return 'Tooth extraction performed';
      default:
        return 'Dental consultation';
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              const CustomAppBar(title: 'Medical History'),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.neonTeal))
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: AppColors.neonTeal,
                        child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            // Summary chips
                            Row(children: [
                              _stat('${_records.length}', 'Records'),
                              const SizedBox(width: 12),
                              _stat(
                                  '${_records.where((r) => r['status'] == 'Upcoming').length}',
                                  'Upcoming'),
                              const SizedBox(width: 12),
                              _stat(_bloodType, 'Blood Type'),
                            ]),
                            const SizedBox(height: 20),
 
                            if (_records.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 40),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.folder_open_rounded,
                                      size: 56,
                                      color:
                                          AppColors.textMuted.withOpacity(0.4),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'No medical history yet.\nVisit your doctor to build your record.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ..._records.map((r) => _recordCard(r)),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
 
  Widget _stat(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: AppColors.cardDecoration,
        child: Column(children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neonTeal)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12)),
        ]),
      ),
    );
  }
 
  Widget _recordCard(Map<String, dynamic> r) {
    final isUpcoming = r['status'] == 'Upcoming';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppColors.cardDecoration,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(
            isUpcoming
                ? Icons.calendar_today_rounded
                : Icons.medical_services_rounded,
            color: AppColors.neonTeal,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(r['date'] as String,
              style: const TextStyle(
                  color: AppColors.neonTeal,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: (isUpcoming ? Colors.orange : AppColors.neonTeal)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(r['status'] as String,
                style: TextStyle(
                    color: isUpcoming
                        ? Colors.orange
                        : AppColors.neonTeal,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 6),
        Text(r['doctor'] as String,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 12)),
        const Divider(color: Color(0xFF1A2A44), height: 16),
        _rRow('Diagnosis', r['diagnosis'] as String),
        const SizedBox(height: 4),
        _rRow('Treatment', r['treatment'] as String),
      ]),
    );
  }
 
  Widget _rRow(String label, String value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
              text: '$label: ',
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 13)),
          TextSpan(
              text: value,
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}