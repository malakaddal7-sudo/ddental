// lib/doctor/appointment_screen.dart
// FIXED: reads doctorId field correctly, shows accept/decline like the design mockup,
//        sends notification back to patient when doctor accepts/declines

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'doctor_colors.dart';
import 'add_appointment_screen.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});
  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  // selected appointment for detail view (pending only)
  String? _expandedId;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ─── Accept / Decline with patient notification ──────────────────────────────
  Future<void> _updateStatus(
    String appointmentId,
    String status,
    Map<String, dynamic> data,
  ) async {
    try {
      // 1. Update global appointments
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update({'status': status});

      // 2. Update patient subcollection
      final patientId = data['patientId'] as String?;
      if (patientId != null && patientId.isNotEmpty) {
        try {
          final patientRef = FirebaseFirestore.instance
              .collection('users')
              .doc(patientId)
              .collection('appointments')
              .doc(appointmentId);
          final snap = await patientRef.get();
          if (snap.exists) await patientRef.update({'status': status});
        } catch (_) {}

        // 3. ✅ Notify patient of the status change
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(patientId)
            .collection('notifications')
            .add({
              'type': 'appointment_update',
              'appointmentId': appointmentId,
              'doctorId': _uid,
              'doctorName': data['doctorName'] ?? '',
              'service': data['service'] ?? '',
              'date': data['date'],
              'time': data['time'] ?? '',
              'status': status,
              'message': status == 'confirmed'
                  ? 'Your appointment has been confirmed by the doctor.'
                  : 'Your appointment request was declined.',
              'createdAt': Timestamp.now(),
            });
      }

      if (mounted) {
        setState(() => _expandedId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'confirmed'
                  ? '✅ Appointment confirmed'
                  : '❌ Appointment declined',
              style: const TextStyle(color: DC.text),
            ),
            backgroundColor: DC.card,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: (status == 'confirmed' ? DC.green : Colors.red)
                    .withOpacity(0.5),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: DC.danger),
        );
      }
    }
  }

  // ─── Stream: all appointments for this doctor ────────────────────────────────
  Stream<QuerySnapshot> _stream() {
    return FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: _uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DC.bg,
      appBar: AppBar(
        backgroundColor: DC.surface,
        elevation: 0,
        title: const Text(
          'Appointments',
          style: TextStyle(color: DC.text, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              Container(height: 1, color: DC.border),
              TabBar(
                controller: _tabs,
                indicatorColor: DC.green,
                labelColor: DC.green,
                unselectedLabelColor: DC.textSub,
                indicatorWeight: 2,
                tabs: const [
                  Tab(text: 'Pending'),
                  Tab(text: 'Confirmed'),
                  Tab(text: 'Past'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildList('pending', showActions: true),
          _buildList('confirmed', showActions: false),
          _buildList('completed', showActions: false),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: DC.green,
        foregroundColor: Colors.black,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddAppointmentScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Appointment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ─── Stream list ─────────────────────────────────────────────────────────────
  Widget _buildList(String status, {required bool showActions}) {
    return StreamBuilder<QuerySnapshot>(
      stream: _stream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: DC.green),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: DC.textSub),
            ),
          );
        }

        var docs = (snapshot.data?.docs ?? []).where((d) {
          final data = d.data() as Map<String, dynamic>;
          final s = (data['status'] ?? 'pending') as String;
          if (status == 'completed') {
            return s == 'completed' || s == 'cancelled';
          }
          return s == status;
        }).toList();

        docs.sort((a, b) {
          final aDate = ((a.data() as Map)['date'] as Timestamp?)?.toDate();
          final bDate = ((b.data() as Map)['date'] as Timestamp?)?.toDate();
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return status == 'completed'
              ? bDate.compareTo(aDate)
              : aDate.compareTo(bDate);
        });

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: DC.textMuted,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  status == 'pending'
                      ? 'No pending requests'
                      : status == 'confirmed'
                      ? 'No confirmed appointments'
                      : 'No past appointments',
                  style: const TextStyle(color: DC.textSub),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final id = docs[i].id;
            return showActions
                ? _buildRequestCard(id, data) // pending: detailed card
                : _buildSimpleCard(id, data); // confirmed/past: simple card
          },
        );
      },
    );
  }

  // ─── Pending request card (matches the design in the screenshot) ─────────────
  Widget _buildRequestCard(String docId, Map<String, dynamic> data) {
    final patientName = data['patientName'] ?? 'Patient';
    final service = data['service'] ?? '—';
    final time = data['time'] ?? '—';
    final notes = data['notes'] ?? '';
    final phone = data['patientPhone'] ?? '';
    final expanded = _expandedId == docId;

    DateTime? date;
    if (data['date'] != null) {
      final d = data['date'];
      if (d is Timestamp) {
        date = d.toDate();
      }
    }
    final dateStr = date != null
        ? '${_weekday(date.weekday)}, ${date.day} ${_month(date.month)} ${date.year}'
        : '—';

    return GestureDetector(
      onTap: () => setState(() => _expandedId = expanded ? null : docId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: DC.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: expanded ? DC.warning.withOpacity(0.6) : DC.border,
            width: expanded ? 1.5 : 1,
          ),
          boxShadow: expanded
              ? [BoxShadow(color: DC.warning.withOpacity(0.08), blurRadius: 12)]
              : [],
        ),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Status badge: NEW
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: DC.warning.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        color: DC.warning,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Avatar
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: DC.warning.withOpacity(0.12),
                    child: Text(
                      patientName.isNotEmpty
                          ? patientName[0].toUpperCase()
                          : 'P',
                      style: const TextStyle(
                        color: DC.warning,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name + service
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patientName,
                          style: const TextStyle(
                            color: DC.text,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          service,
                          style: const TextStyle(
                            color: DC.textSub,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: DC.textMuted,
                  ),
                ],
              ),
            ),

            // ── Expanded detail ──────────────────────────────────────────
            if (expanded) ...[
              Container(height: 1, color: DC.border),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    // Detail rows
                    _detailRow(
                      Icons.medical_services_outlined,
                      'Specialty',
                      data['doctorSpecialty'] ?? service,
                    ),
                    _detailRow(Icons.calendar_today_outlined, 'Date', dateStr),
                    _detailRow(Icons.access_time_rounded, 'Time', time),
                    _detailRow(
                      Icons.location_on_outlined,
                      'Location',
                      'Clinic Visit',
                    ),
                    if (phone.isNotEmpty)
                      _detailRow(Icons.phone_outlined, 'Phone', phone),
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: DC.bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: DC.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Patient Notes',
                              style: TextStyle(color: DC.textSub, fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notes,
                              style: const TextStyle(
                                color: DC.text,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    // Accept / Decline buttons
                    Row(
                      children: [
                        Expanded(
                          child: _actionBtn(
                            label: 'Accept',
                            icon: Icons.check_circle_rounded,
                            color: DC.green,
                            onTap: () =>
                                _updateStatus(docId, 'confirmed', data),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _actionBtn(
                            label: 'Decline',
                            icon: Icons.cancel_rounded,
                            color: Colors.red,
                            onTap: () =>
                                _updateStatus(docId, 'cancelled', data),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: DC.green, size: 16),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: DC.textSub, fontSize: 12)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: DC.text,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Simple confirmed/past card ──────────────────────────────────────────────
  Widget _buildSimpleCard(String docId, Map<String, dynamic> data) {
    final status = data['status'] ?? 'confirmed';
    final col = _statusColor(status);
    final patientName = data['patientName'] ?? 'Patient';
    final service = data['service'] ?? '—';
    final time = data['time'] ?? '—';

    DateTime? date;
    if (data['date'] is Timestamp) date = (data['date'] as Timestamp).toDate();
    final dateStr = date != null
        ? '${date.day}/${date.month}/${date.year}'
        : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: DC.cardDecoration,
      child: Row(
        children: [
          // Date column
          Column(
            children: [
              Text(
                dateStr,
                style: const TextStyle(color: DC.textSub, fontSize: 10),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: const TextStyle(
                  color: DC.text,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            width: 1,
            height: 36,
            color: DC.border,
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: col.withOpacity(0.12),
            child: Text(
              patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
              style: TextStyle(color: col, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName,
                  style: const TextStyle(
                    color: DC.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  service,
                  style: const TextStyle(color: DC.textSub, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: col.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: col.withOpacity(0.3)),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: col,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'confirmed':
        return DC.green;
      case 'pending':
        return DC.warning;
      case 'completed':
        return DC.textMuted;
      case 'cancelled':
        return Colors.red;
      default:
        return DC.info;
    }
  }

  String _weekday(int w) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[(w - 1).clamp(0, 6)];
  }

  String _month(int m) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[m.clamp(1, 12)];
  }
}
