import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../widgets/neon_panel.dart';
 
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
 
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}
 
class _DashboardPageState extends State<DashboardPage> {
  // Stats loaded from Firebase
  int _totalVisits = 0;
  int _upcoming = 0;
  int _prescriptions = 0;
  int _xrays = 0;
 
  // Medical record fields loaded from Firebase
  String _bloodType = '—';
  String _lastVisit = '—';
  String _diagnosis = '—';
  String _nextAppointment = '—';
 
  // Recent real appointments to show in Recent Activity
  List<Map<String, dynamic>> _recentActivity = [];
 
  bool _loading = true;
 
  @override
  void initState() {
    super.initState();
    _loadData();
  }
 
  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
 
    try {
      final uid = user.uid;
      final now = DateTime.now();
 
      // ── 1. Load appointments from users/{uid}/appointments ──────────────────
      final apptSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('appointments')
          .get();
 
      int totalVisits = 0;
      int upcoming = 0;
      String nextAppt = '—';
      DateTime? nextApptDate;
      List<Map<String, dynamic>> recentActivity = [];
 
      for (final doc in apptSnap.docs) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString().toLowerCase();
        final date = (data['date'] as Timestamp?)?.toDate();
 
        // Count completed visits
        if (status == 'completed') totalVisits++;
 
        // Count upcoming (confirmed + in the future)
        if (status == 'confirmed' && date != null && date.isAfter(now)) {
          upcoming++;
          // Track the nearest upcoming appointment
          if (nextApptDate == null || date.isBefore(nextApptDate)) {
            nextApptDate = date;
            nextAppt =
                '${date.day}/${date.month}/${date.year}  ${data['time'] ?? ''}';
          }
        }
 
        // Build recent activity list (last 5)
        recentActivity.add({
          'title': _activityTitle(status),
          'subtitle': _activitySubtitle(data, status),
          'date': date,
          'status': status,
        });
      }
 
      // Sort by date descending and keep last 3
      recentActivity.sort((a, b) {
        final aDate = a['date'] as DateTime?;
        final bDate = b['date'] as DateTime?;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });
      if (recentActivity.length > 3) recentActivity = recentActivity.sublist(0, 3);
 
      // ── 2. Load medical record from users/{uid}/medicalRecord ───────────────
      String bloodType = '—';
      String lastVisit = '—';
      String diagnosis = '—';
 
      final medSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('medicalRecord')
          .limit(1)
          .get();
 
      if (medSnap.docs.isNotEmpty) {
        final med = medSnap.docs.first.data();
        bloodType = med['bloodType'] ?? med['blood_type'] ?? '—';
        diagnosis = med['diagnosis'] ?? med['lastDiagnosis'] ?? '—';
        // Last visit date from medical record if stored
        final lv = med['lastVisit'];
        if (lv != null && lv is Timestamp) {
          final d = lv.toDate();
          lastVisit = '${d.day}/${d.month}/${d.year}';
        }
      }
 
      // Fallback: compute lastVisit from completed appointments
      if (lastVisit == '—') {
        DateTime? latestCompleted;
        for (final doc in apptSnap.docs) {
          final data = doc.data();
          final status = (data['status'] ?? '').toString().toLowerCase();
          final date = (data['date'] as Timestamp?)?.toDate();
          if (status == 'completed' && date != null) {
            if (latestCompleted == null || date.isAfter(latestCompleted)) {
              latestCompleted = date;
            }
          }
        }
        if (latestCompleted != null) {
          lastVisit =
              '${latestCompleted.day}/${latestCompleted.month}/${latestCompleted.year}';
        }
      }
 
      // ── 3. Count X-Rays from users/{uid}/xrays ──────────────────────────────
      int xrays = 0;
      try {
        final xraySnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('xrays')
            .get();
        xrays = xraySnap.docs.length;
      } catch (_) {}
 
      // ── 4. Count prescriptions from medical record ───────────────────────────
      int prescriptions = 0;
      try {
        final presSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('prescriptions')
            .get();
        prescriptions = presSnap.docs.length;
      } catch (_) {}
 
      if (mounted) {
        setState(() {
          _totalVisits = totalVisits;
          _upcoming = upcoming;
          _prescriptions = prescriptions;
          _xrays = xrays;
          _bloodType = bloodType;
          _lastVisit = lastVisit;
          _diagnosis = diagnosis;
          _nextAppointment = nextAppt;
          _recentActivity = recentActivity;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Dashboard load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }
 
  String _activityTitle(String status) {
    switch (status) {
      case 'confirmed':
        return 'Appointment Confirmed';
      case 'pending':
        return 'Appointment Pending';
      case 'cancelled':
        return 'Appointment Cancelled';
      case 'completed':
        return 'Visit Completed';
      default:
        return 'Appointment Update';
    }
  }
 
  String _activitySubtitle(Map<String, dynamic> data, String status) {
    final doctor = data['doctorName'] ?? 'your doctor';
    final service = data['service'] ?? '';
    switch (status) {
      case 'confirmed':
        return '$doctor confirmed your appointment ($service)';
      case 'pending':
        return 'Waiting for $doctor to confirm ($service)';
      case 'cancelled':
        return '$doctor declined the appointment';
      case 'completed':
        return 'Visit with $doctor — $service';
      default:
        return 'Appointment with $doctor';
    }
  }
 
  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
 
  IconData _activityIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      case 'completed':
        return Icons.local_hospital_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }
 
  Color _activityColor(String status) {
    switch (status) {
      case 'confirmed':
        return const Color(0xFF00897B);
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return const Color(0xFF00ACC1);
      default:
        return Colors.orange;
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00897B)))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: const Color(0xFF00897B),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Dashboard',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text)),
                        const Text('Your health overview',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 13)),
 
                        const SizedBox(height: 24),
 
                        // ── Stats ────────────────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                                child: _buildStatCard(
                                    'Total Visits',
                                    '$_totalVisits',
                                    Icons.local_hospital_rounded,
                                    const Color(0xFF00897B))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _buildStatCard(
                                    'Upcoming',
                                    '$_upcoming',
                                    Icons.calendar_today_rounded,
                                    const Color(0xFF00ACC1))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                                child: _buildStatCard(
                                    'Prescriptions',
                                    '$_prescriptions',
                                    Icons.medical_services_rounded,
                                    const Color(0xFF26A69A))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _buildStatCard(
                                    'X-Rays',
                                    '$_xrays',
                                    Icons.image_rounded,
                                    const Color(0xFF00695C))),
                          ],
                        ),
 
                        const SizedBox(height: 24),
 
                        // ── Medical Record ───────────────────────────────────
                        const Text('Medical Record',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text)),
                        const SizedBox(height: 12),
 
                        NeonPanel(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildRecordRow('Blood Type', _bloodType,
                                  Icons.bloodtype_rounded, Colors.red),
                              const Divider(),
                              _buildRecordRow(
                                  'Last Visit',
                                  _lastVisit,
                                  Icons.calendar_today_rounded,
                                  const Color(0xFF00897B)),
                              const Divider(),
                              _buildRecordRow(
                                  'Diagnosis',
                                  _diagnosis,
                                  Icons.medical_information_rounded,
                                  const Color(0xFF00ACC1)),
                              const Divider(),
                              _buildRecordRow('Next Appointment',
                                  _nextAppointment, Icons.alarm_rounded,
                                  Colors.orange),
                            ],
                          ),
                        ),
 
                        const SizedBox(height: 24),
 
                        // ── Recent Activity ──────────────────────────────────
                        const Text('Recent Activity',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text)),
                        const SizedBox(height: 12),
 
                        if (_recentActivity.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'No activity yet.\nBook your first appointment!',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 13),
                              ),
                            ),
                          )
                        else
                          ..._recentActivity.map((item) {
                            final status = item['status'] as String;
                            final date = item['date'] as DateTime?;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildActivityItem(
                                item['title'] as String,
                                item['subtitle'] as String,
                                _timeAgo(date),
                                _activityIcon(status),
                                _activityColor(status),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
 
  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.stroke.withOpacity(0.9), width: 1),
        boxShadow: [
          BoxShadow(
              color: AppColors.neonCyan.withOpacity(0.16), blurRadius: 14),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(title,
              style:
                  const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
 
  Widget _buildRecordRow(
      String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(title,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 14)),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.text)),
          ),
        ],
      ),
    );
  }
 
  Widget _buildActivityItem(
      String title, String subtitle, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panel.withOpacity(0.92),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.stroke.withOpacity(0.9), width: 1),
        boxShadow: [
          BoxShadow(
              color: AppColors.neonCyan.withOpacity(0.10), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.text)),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Text(time,
              style:
                  const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}