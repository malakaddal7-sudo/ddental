import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'doctor_colors.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _RequestsView(uid: uid);
  }
}

class _RequestsView extends StatefulWidget {
  final String uid;
  const _RequestsView({required this.uid});
  @override
  State<_RequestsView> createState() => _RequestsViewState();
}

class _RequestsViewState extends State<_RequestsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

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

  Stream<QuerySnapshot> _stream(String status) {
    return FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: widget.uid)
        .where('status', isEqualTo: status)
        .snapshots();
  }

  Future<void> _accept(String appointmentId) async {
    final batch = FirebaseFirestore.instance.batch();
    // Update global appointments
    batch.update(
      FirebaseFirestore.instance.collection('appointments').doc(appointmentId),
      {'status': 'confirmed'},
    );
    // Update doctor's subcollection
    batch.update(
      FirebaseFirestore.instance
          .collection('doctors')
          .doc(widget.uid)
          .collection('appointments')
          .doc(appointmentId),
      {'status': 'confirmed'},
    );
    await batch.commit();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Row(children: [
          Icon(Icons.check_circle, color: DC.green),
          SizedBox(width: 8),
          Text('Appointment confirmed!', style: TextStyle(color: DC.text)),
        ]),
        backgroundColor: DC.card,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _refuse(String appointmentId, String patientName) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DC.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: DC.border),
        ),
        title: const Text('Refuse Appointment',
            style: TextStyle(color: DC.text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Refusing $patientName's request.",
                style: const TextStyle(color: DC.textSub, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              style: const TextStyle(color: DC.text),
              decoration: InputDecoration(
                hintText: 'Reason (optional)',
                hintStyle: const TextStyle(color: DC.textMuted),
                filled: true,
                fillColor: DC.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: DC.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: DC.border),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: DC.textSub)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: DC.danger, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              final batch = FirebaseFirestore.instance.batch();
              batch.update(
                FirebaseFirestore.instance
                    .collection('appointments')
                    .doc(appointmentId),
                {'status': 'cancelled', 'refuseReason': reasonCtrl.text.trim()},
              );
              batch.update(
                FirebaseFirestore.instance
                    .collection('doctors')
                    .doc(widget.uid)
                    .collection('appointments')
                    .doc(appointmentId),
                {'status': 'cancelled', 'refuseReason': reasonCtrl.text.trim()},
              );
              await batch.commit();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Request declined",
                      style: TextStyle(color: DC.text)),
                  backgroundColor: DC.card,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            child: const Text('Refuse'),
          ),
        ],
      ),
    );
  }

  String _monthName(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m - 1];
  }

  Map<String, dynamic> _parseDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final ts = data['date'] as Timestamp?;
    String dateStr = '';
    String timeStr = data['time'] ?? '';
    if (ts != null) {
      final dt = ts.toDate();
      dateStr = '${dt.day} ${_monthName(dt.month)} ${dt.year}';
      if (timeStr.isEmpty) {
        timeStr =
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }
    final name = (data['patientName'] ?? 'Patient') as String;
    final initials = name
        .trim()
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0])
        .take(2)
        .join()
        .toUpperCase();
    return {
      'id': doc.id,
      'patient': name,
      'initials': initials.isNotEmpty ? initials : '?',
      'date': dateStr,
      'time': timeStr,
      'type': data['service'] ?? 'Appointment',
      'reason': data['reason'] ?? '',
      'status': data['status'] ?? 'pending',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DC.bg,
      appBar: AppBar(
        backgroundColor: DC.surface,
        elevation: 0,
        title: const Text('Appointment Requests',
            style: TextStyle(color: DC.text, fontWeight: FontWeight.bold)),
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
                labelStyle:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Pending'),
                  Tab(text: 'Confirmed'),
                  Tab(text: 'Refused'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildStreamList('pending', showActions: true),
          _buildStreamList('confirmed', statusColor: DC.green),
          _buildStreamList('cancelled', statusColor: DC.danger),
        ],
      ),
    );
  }

  Widget _buildStreamList(String status,
      {bool showActions = false, Color? statusColor}) {
    return StreamBuilder<QuerySnapshot>(
      stream: _stream(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: DC.green));
        }
        final docs = snapshot.data?.docs ?? [];
        final items = docs.map(_parseDoc).toList();

        if (items.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                showActions
                    ? Icons.pending_actions_outlined
                    : Icons.check_circle_outline,
                color: DC.textMuted,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                showActions ? 'No pending requests' : 'Nothing here yet',
                style: const TextStyle(color: DC.textSub),
              ),
            ]),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (_, i) =>
              _buildCard(items[i], showActions, statusColor),
        );
      },
    );
  }

  Widget _buildCard(
      Map<String, dynamic> r, bool showActions, Color? statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: DC.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: DC.warning.withOpacity(0.15),
                child: Text(r['initials'] as String,
                    style: const TextStyle(
                        color: DC.warning, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r['patient'] as String,
                        style: const TextStyle(
                            color: DC.text, fontWeight: FontWeight.bold)),
                    Text(
                      [r['date'], r['time']]
                          .where((s) => (s as String).isNotEmpty)
                          .join(' · '),
                      style:
                          const TextStyle(color: DC.textSub, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: DC.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: DC.info.withOpacity(0.3)),
                ),
                child: Text(r['type'] as String,
                    style: const TextStyle(
                        color: DC.info,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _refuse(r['id'] as String, r['patient'] as String),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Refuse'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DC.danger,
                      side: const BorderSide(color: DC.danger),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _accept(r['id'] as String),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DC.green,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (!showActions && statusColor != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  statusColor == DC.green
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: statusColor,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  statusColor == DC.green
                      ? 'Appointment Confirmed'
                      : 'Request Declined',
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
