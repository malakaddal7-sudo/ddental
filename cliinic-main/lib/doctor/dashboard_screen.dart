import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'doctor_colors.dart';
 
import 'add_patient_screen.dart';
import 'records_screen.dart';
import 'reports_screen.dart';
 
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}
 
class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String _doctorName = 'Doctor';
 
  // real counts from Firestore
  int _totalPatients = 0;
  int _todayVisits = 0;
  int _pendingCount = 0;
 
  // today's appointments from Firestore
  List<Map<String, dynamic>> _todayApts = [];
 
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }
 
  Future<void> _loadDashboardData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
 
      // Load doctor name
      final doctorDoc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(uid)
          .get();
      if (doctorDoc.exists) {
        final data = doctorDoc.data()!;
        final first = data['firstName'] ?? '';
        final last  = data['lastName']  ?? '';
        _doctorName = 'Dr. $first $last'.trim();
      }
 
      // Count patients assigned to this doctor
      final patientsSnap = await FirebaseFirestore.instance
          .collection('patients')
          .where('doctorId', isEqualTo: uid)
          .get();
      _totalPatients = patientsSnap.docs.length;
 
      // Today's date range
      final now   = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end   = start.add(const Duration(days: 1));
 
      // Count today's appointments
      final todaySnap = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThan: Timestamp.fromDate(end))
          .get();
      _todayVisits = todaySnap.docs.length;
 
      // Build today's schedule list
      _todayApts = todaySnap.docs.map((d) {
        final data = d.data();
        final ts = data['date'] as Timestamp?;
        final time = ts != null
            ? '${ts.toDate().hour.toString().padLeft(2, '0')}:${ts.toDate().minute.toString().padLeft(2, '0')}'
            : '--:--';
        return {
          'name': data['patientName'] ?? 'Patient',
          'time': time,
          'type': data['type'] ?? 'Appointment',
        };
      }).toList();
 
      // Count pending requests for this doctor
      final pendingSnap = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .get();
      _pendingCount = pendingSnap.docs.length;
 
    } catch (_) {}
 
    if (mounted) setState(() => _isLoading = false);
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DC.bg,
      body: Container(
        decoration: const BoxDecoration(gradient: DC.bgGrad),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: DC.green))
            : SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildStatsRow(),
                          const SizedBox(height: 20),
                          _buildQuickActions(context),
                          const SizedBox(height: 20),
                          _buildTodaySchedule(),
                          const SizedBox(height: 20),
                          _buildPendingRequests(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
 
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Good morning,', style: TextStyle(fontSize: 12, color: DC.textSub)),
              const SizedBox(height: 2),
              Text(_doctorName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: DC.text)),
            ],
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: DC.card,
              shape: BoxShape.circle,
              border: Border.all(color: DC.border),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, color: DC.green),
              onPressed: () => _showNotifications(context),
            ),
          ),
        ],
      ),
    );
  }
 
  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DC.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications',
                style: TextStyle(color: DC.text, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: const [
                  Icon(Icons.notifications_none_rounded, color: DC.textMuted, size: 40),
                  SizedBox(height: 8),
                  Text('No notifications yet', style: TextStyle(color: DC.textSub)),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
 
  Widget _buildStatsRow() {
    return Row(
      children: [
        _statCard(_totalPatients.toString(), 'Total Patients', Icons.people_outline, DC.green),
        const SizedBox(width: 12),
        _statCard(_todayVisits.toString(), 'Today Visits', Icons.calendar_today_outlined, DC.info),
        const SizedBox(width: 12),
        _statCard(_pendingCount.toString(), 'Pending', Icons.pending_actions_outlined, DC.warning),
      ],
    );
  }
 
  Widget _statCard(String val, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: DC.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(val, style: const TextStyle(color: DC.text, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: DC.textSub, fontSize: 10)),
          ],
        ),
      ),
    );
  }
 
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions',
            style: TextStyle(color: DC.text, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _actionBtn(Icons.person_add_rounded, 'Add Patient', DC.green, () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AddPatientScreen()));
            }),
            _actionBtn(Icons.assignment_rounded, 'Records', DC.info, () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RecordsScreen()));
            }),
            _actionBtn(Icons.bar_chart_rounded, 'Reports', DC.danger, () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ReportsScreen()));
            }),
          ],
        ),
      ],
    );
  }
 
  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: DC.textSub, fontSize: 10)),
        ],
      ),
    );
  }
 
  Widget _buildTodaySchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text("Today's Schedule",
                style: TextStyle(color: DC.text, fontWeight: FontWeight.bold, fontSize: 15)),
            const Spacer(),
            Text('${_todayApts.length} apts',
                style: const TextStyle(color: DC.textSub, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 12),
        if (_todayApts.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: DC.cardDecoration,
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.calendar_today_outlined, color: DC.textMuted, size: 36),
                  SizedBox(height: 8),
                  Text('No appointments today',
                      style: TextStyle(color: DC.textSub, fontSize: 13)),
                ],
              ),
            ),
          )
        else
          ..._todayApts.map((a) => _aptCard(
              a['name'] as String,
              a['time'] as String,
              a['type'] as String,
              DC.green)),
      ],
    );
  }
 
  Widget _aptCard(String name, String time, String type, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: DC.cardDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(time,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 14),
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.1),
            child: Text(name.isNotEmpty ? name[0] : '?',
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(color: DC.text, fontWeight: FontWeight.w600)),
                Text(type,
                    style: const TextStyle(color: DC.textSub, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: DC.textMuted, size: 18),
        ],
      ),
    );
  }
 
  Widget _buildPendingRequests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pending Requests',
            style: TextStyle(color: DC.text, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        if (_pendingCount == 0)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: DC.cardDecoration,
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.pending_actions_outlined, color: DC.textMuted, size: 36),
                  SizedBox(height: 8),
                  Text('No pending requests',
                      style: TextStyle(color: DC.textSub, fontSize: 13)),
                ],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DC.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DC.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.pending_actions_rounded, color: DC.warning),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$_pendingCount appointment request${_pendingCount == 1 ? '' : 's'} waiting',
                          style: const TextStyle(color: DC.text, fontWeight: FontWeight.w600)),
                      const Text('Tap Requests tab to review',
                          style: TextStyle(color: DC.textSub, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: DC.warning, size: 14),
              ],
            ),
          ),
      ],
    );
  }
}
 
 