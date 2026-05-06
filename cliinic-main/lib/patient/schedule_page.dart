import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../widgets/neon_panel.dart';
import '../widgets/neon_button.dart';
import 'book_appointment_page.dart';
import 'appointment_detail_page.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDate;

  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<Map<String, dynamic>> _getAppointmentsForDate(
      List<Map<String, dynamic>> all, DateTime date) =>
      all.where((a) => _isSameDay(a['date'] as DateTime, date)).toList();

  List<Map<String, dynamic>> _getAppointmentsForMonth(
      List<Map<String, dynamic>> all, DateTime month) =>
      all.where((a) {
        final d = a['date'] as DateTime;
        return d.year == month.year && d.month == month.month;
      }).toList();

  void _prevMonth() => setState(
      () => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1));

  void _nextMonth() => setState(
      () => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1));

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  /// Convert Firestore doc to local appointment map (including the doc id)
  Map<String, dynamic> _fromDoc(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    DateTime date = DateTime.now();
    if (d['date'] is Timestamp) {
      date = (d['date'] as Timestamp).toDate();
    }
    final status = d['status'] as String? ?? 'pending';
    return {
      'id': doc.id,          // ← critical: passes appointmentId to detail page
      'date': date,
      'doctor': d['doctorName'] ?? d['doctor'] ?? 'Doctor',
      'type': d['service'] ?? d['type'] ?? 'Appointment',
      'time': d['time'] ?? '',
      'status': status,
      'color': status == 'confirmed'
          ? const Color(0xFF00897B)
          : status == 'cancelled'
              ? Colors.red
              : const Color(0xFF00ACC1),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: _uid.isEmpty
                ? null
                : FirebaseFirestore.instance
                    .collection('appointments')
                    .where('patientId', isEqualTo: _uid)
                    .snapshots(),
            builder: (context, snapshot) {
              // Build appointment list from Firestore or fallback to empty
              final List<Map<String, dynamic>> appointments;
              if (snapshot.hasData) {
                final docs = snapshot.data!.docs;
                appointments = docs.map(_fromDoc).toList()
                  ..sort((a, b) =>
                      (a['date'] as DateTime).compareTo(b['date'] as DateTime));
              } else {
                appointments = [];
              }

              final selectedAppointments = _selectedDate != null
                  ? _getAppointmentsForDate(appointments, _selectedDate!)
                  : _getAppointmentsForMonth(appointments, _focusedMonth);

              return SingleChildScrollView(
                child: Column(
                  children: [
                    // HEADER
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Schedule',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.text)),
                              Text('Manage your appointments',
                                  style: TextStyle(
                                      color: AppColors.textMuted, fontSize: 13)),
                            ],
                          ),
                          SizedBox(
                            width: 120,
                            child: NeonButton(
                              label: 'Book',
                              icon: Icons.add_rounded,
                              height: 44,
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const BookAppointmentPage()),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // CALENDAR
                    NeonPanel(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: EdgeInsets.zero,
                      borderRadius: 20,
                      child: Column(
                        children: [
                          // MONTH NAV
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: _prevMonth,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.panel2,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.chevron_left_rounded,
                                        color: AppColors.neonCyan),
                                  ),
                                ),
                                Text(
                                  '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
                                  style: const TextStyle(
                                      color: AppColors.text,
                                      fontWeight: FontWeight.bold),
                                ),
                                GestureDetector(
                                  onTap: _nextMonth,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.panel2,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.chevron_right_rounded,
                                        color: AppColors.neonCyan),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // DAYS HEADER
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                                .map((d) => Text(d,
                                    style: const TextStyle(
                                        color: AppColors.textMuted, fontSize: 11)))
                                .toList(),
                          ),

                          const SizedBox(height: 6),

                          _buildDaysGrid(appointments),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // LOADING indicator
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                            color: AppColors.neonCyan, strokeWidth: 2),
                      ),

                    // TITLE
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _selectedDate != null
                            ? '${_selectedDate!.day} ${_monthName(_selectedDate!.month)}'
                            : '${_monthName(_focusedMonth.month)} Appointments',
                        style: const TextStyle(
                            color: AppColors.text, fontWeight: FontWeight.bold),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // EMPTY STATE
                    if (selectedAppointments.isEmpty &&
                        snapshot.connectionState != ConnectionState.waiting)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                color: AppColors.textMuted.withOpacity(0.4),
                                size: 48),
                            const SizedBox(height: 10),
                            const Text('No appointments this period',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 13)),
                          ],
                        ),
                      ),

                    // LIST
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: selectedAppointments.length,
                      itemBuilder: (context, i) =>
                          _buildAppointmentCard(context, selectedAppointments[i]),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDaysGrid(List<Map<String, dynamic>> appointments) {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7),
      itemCount: startWeekday + daysInMonth,
      itemBuilder: (context, index) {
        if (index < startWeekday) return const SizedBox();
        final day = index - startWeekday + 1;
        final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
        final hasAppt = appointments.any((a) => _isSameDay(a['date'] as DateTime, date));
        final isSelected = _selectedDate != null && _isSameDay(_selectedDate!, date);
        final isToday = _isSameDay(date, DateTime.now());

        return GestureDetector(
          onTap: () => setState(() {
            _selectedDate = isSelected ? null : date;
          }),
          child: Center(
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.neonCyan
                    : isToday
                        ? AppColors.neonCyan.withOpacity(0.2)
                        : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      color: isSelected ? Colors.black : AppColors.text,
                      fontWeight: isToday || isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                  if (hasAppt && !isSelected)
                    Positioned(
                      bottom: 3,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.neonCyan,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentCard(
      BuildContext context, Map<String, dynamic> apt) {
    final color = apt['color'] as Color;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AppointmentDetailPage(appointment: apt),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: AppColors.cardDecoration,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.medical_services_rounded, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(apt['doctor'] as String,
                      style: const TextStyle(
                          color: AppColors.text, fontWeight: FontWeight.bold)),
                  Text(apt['type'] as String,
                      style:
                          const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(apt['time'] as String,
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (apt['status'] as String).toUpperCase(),
                    style: TextStyle(
                        color: color, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
