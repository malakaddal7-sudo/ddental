// lib/patient/notifications_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
        actions: [
          TextButton(
            onPressed: () => _markAllRead(uid),
            child: const Text(
              'Mark all read',
              style: TextStyle(color: AppColors.neonCyan, fontSize: 12),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('patients')
            .doc(uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.neonCyan),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // FIX: removed const — withOpacity() is not a const expression
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 60,
                    color: AppColors.textMuted.withOpacity(0.4),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No notifications yet',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final isUnread = data['status'] == 'unread';
              final type = data['type'] as String? ?? '';
              final label = data['label'] as String? ?? '';
              // imageUrl kept for potential future use; prefixed to silence
              // unused-variable warning without removing the field read.
              // ignore: unused_local_variable
              final imageUrl = data['imageUrl'] as String? ?? '';
              final ts = data['createdAt'] as Timestamp?;
              final dateStr = ts != null
                  ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
                  : '';

              // appointment-type fields
              final service = data['service'] as String? ?? '';
              final time = data['time'] as String? ?? '';
              final status = data['status'] as String? ?? '';
              final doctorName = data['doctorName'] as String? ?? '';

              final isXray = type == 'xray_uploaded';
              final isAppointment =
                  type == 'appointment_update' || data.containsKey('service');

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    // FIX: removed const — withOpacity() is not const
                    color: AppColors.danger.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.danger,
                  ),
                ),
                onDismissed: (_) {
                  FirebaseFirestore.instance
                      .collection('patients')
                      .doc(uid)
                      .collection('notifications')
                      .doc(doc.id)
                      .delete();
                },
                child: GestureDetector(
                  onTap: () {
                    if (isUnread) {
                      FirebaseFirestore.instance
                          .collection('patients')
                          .doc(uid)
                          .collection('notifications')
                          .doc(doc.id)
                          .update({'status': 'read'});
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      // FIX: removed const — withOpacity() is not const
                      color: isUnread
                          ? AppColors.neonCyan.withOpacity(0.08)
                          : AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isUnread
                            ? AppColors.neonCyan.withOpacity(0.3)
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon bubble
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            // FIX: removed const — withOpacity() is not const
                            color: AppColors.neonCyan.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isXray
                                ? Icons.image_rounded
                                : Icons.calendar_today_rounded,
                            color: AppColors.neonCyan,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      isXray
                                          ? 'New X-Ray Uploaded'
                                          : 'Appointment Update',
                                      style: TextStyle(
                                        color: AppColors.text,
                                        fontWeight: isUnread
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (isUnread)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.neonCyan,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (isXray && label.isNotEmpty)
                                Text(
                                  'Label: $label',
                                  style: const TextStyle(
                                    color: AppColors.textSub,
                                    fontSize: 13,
                                  ),
                                ),
                              if (isAppointment) ...[
                                if (doctorName.isNotEmpty)
                                  Text(
                                    'Doctor: $doctorName',
                                    style: const TextStyle(
                                      color: AppColors.textSub,
                                      fontSize: 13,
                                    ),
                                  ),
                                if (service.isNotEmpty)
                                  Text(
                                    'Service: $service',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                if (time.isNotEmpty)
                                  Text(
                                    'Time: $time',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                // FIX: guard against 'unread'/'read' leaking
                                // into the status badge — also avoids showing
                                // the read-state as an appointment status.
                                if (status.isNotEmpty &&
                                    status != 'unread' &&
                                    status != 'read')
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      // FIX: removed const — withOpacity()
                                      color: _statusColor(
                                        status,
                                      ).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        color: _statusColor(status),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return AppColors.neonCyan;
    }
  }

  Future<void> _markAllRead(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('patients')
        .doc(uid)
        .collection('notifications')
        .where('status', isEqualTo: 'unread')
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'status': 'read'});
    }
    await batch.commit();
  }
}
