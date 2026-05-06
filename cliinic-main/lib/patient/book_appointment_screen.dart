import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/neon_button.dart';
import '../widgets/neon_panel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookAppointmentPage extends StatefulWidget {
  // FIX: added optional doctorId + doctorName so callers that pass them compile
  final String? doctorId;
  final String? doctorName;

  const BookAppointmentPage({super.key, this.doctorId, this.doctorName});

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  int _step = 0;

  String? _selectedService;
  Map<String, dynamic>? _selectedDoctorData;
  DateTime? _selectedDate;
  String? _selectedTime;

  List<Map<String, dynamic>> _doctors = [];
  bool _loadingDoctors = false;

  final List<Map<String, dynamic>> _services = [
    {
      'name': 'General Checkup',
      'icon': Icons.search_rounded,
      'color': const Color(0xFF00897B),
    },
    {
      'name': 'Teeth Cleaning',
      'icon': Icons.clean_hands_rounded,
      'color': const Color(0xFF00ACC1),
    },
    {
      'name': 'X-Ray',
      'icon': Icons.image_rounded,
      'color': const Color(0xFF26A69A),
    },
    {
      'name': 'Surgery',
      'icon': Icons.medical_services_rounded,
      'color': const Color(0xFF00695C),
    },
    {
      'name': 'Orthodontics',
      'icon': Icons.settings_rounded,
      'color': const Color(0xFF00838F),
    },
    {
      'name': 'Whitening',
      'icon': Icons.star_rounded,
      'color': const Color(0xFF4DB6AC),
    },
  ];

  final List<String> _times = [
    '9:00 AM',
    '9:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '2:00 PM',
    '2:30 PM',
    '3:00 PM',
    '3:30 PM',
    '4:00 PM',
    '4:30 PM',
  ];

  DateTime _focusedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() => _loadingDoctors = true);
    try {
      final snap = await FirebaseFirestore.instance.collection('doctors').get();
      final all = snap.docs.map((d) {
        final data = d.data();
        return {
          'id': d.id,
          'name': 'Dr. ${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'
              .trim(),
          'specialty': data['specialty'] ?? 'General Dentist',
          'city': data['city'] ?? '',
          'clinicName': data['clinicName'] ?? '',
          'available': true,
        };
      }).toList();

      // FIX: if a doctorId was pre-selected, jump straight to step 1 and
      // pre-select that doctor so the user skips the doctor-selection step.
      if (widget.doctorId != null && widget.doctorId!.isNotEmpty) {
        final preSelected = all.firstWhere(
          (d) => d['id'] == widget.doctorId,
          orElse: () => <String, dynamic>{
            'id': widget.doctorId!,
            'name': widget.doctorName ?? 'Doctor',
            'specialty': 'Dentist',
            'city': '',
            'clinicName': '',
            'available': true,
          },
        );
        _selectedDoctorData = preSelected;
      }

      if (mounted) setState(() => _doctors = all);
    } catch (e) {
      debugPrint('Error loading doctors: $e');
    }
    if (mounted) setState(() => _loadingDoctors = false);
  }

  Future<void> _saveAppointment() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || _selectedDoctorData == null) return;

      String patientName = 'Patient';
      String patientPhone = '';
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          final ud = userDoc.data()!;
          patientName = '${ud['firstName'] ?? ''} ${ud['lastName'] ?? ''}'
              .trim();
          if (patientName.isEmpty) patientName = 'Patient';
          patientPhone = (ud['phone'] ?? ud['phoneNumber'] ?? '').toString();
        }
      } catch (_) {}

      final dateTime = _buildDateTime();
      final doctorId = _selectedDoctorData!['id'] as String;

      final appointmentData = {
        'patientId': user.uid,
        'patientName': patientName,
        'patientPhone': patientPhone,
        'doctorId': doctorId,
        'doctorName': _selectedDoctorData!['name'],
        'service': _selectedService,
        'date': dateTime != null ? Timestamp.fromDate(dateTime) : null,
        'time': _selectedTime,
        'status': 'pending',
        'reason': '',
        'createdAt': Timestamp.now(),
      };

      final batch = FirebaseFirestore.instance.batch();

      // 1. Global appointments collection
      final ref = FirebaseFirestore.instance.collection('appointments').doc();
      batch.set(ref, appointmentData);

      // 2. users/{uid}/appointments/
      batch.set(
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('appointments')
            .doc(ref.id),
        appointmentData,
      );

      // 3. patients/{uid}/appointments/  ← patient app reads from here
      batch.set(
        FirebaseFirestore.instance
            .collection('patients')
            .doc(user.uid)
            .collection('appointments')
            .doc(ref.id),
        appointmentData,
      );

      // 4. doctors/{id}/appointments/  ← doctor sees from here
      batch.set(
        FirebaseFirestore.instance
            .collection('doctors')
            .doc(doctorId)
            .collection('appointments')
            .doc(ref.id),
        appointmentData,
      );

      // 5. Notify the doctor
      batch.set(
        FirebaseFirestore.instance
            .collection('doctors')
            .doc(doctorId)
            .collection('notifications')
            .doc(ref.id),
        {
          'appointmentId': ref.id,
          'patientId': user.uid,
          'patientName': patientName,
          'patientPhone': patientPhone,
          'service': _selectedService,
          'date': dateTime != null ? Timestamp.fromDate(dateTime) : null,
          'time': _selectedTime,
          'status': 'unread',
          'createdAt': Timestamp.now(),
        },
      );

      await batch.commit();
    } catch (e) {
      debugPrint('Firestore error: $e');
    }
  }

  DateTime? _buildDateTime() {
    if (_selectedDate == null || _selectedTime == null) return null;
    try {
      final t = _selectedTime!;
      final parts = t.replaceAll(' AM', '').replaceAll(' PM', '').split(':');
      int hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      if (t.contains('PM') && hour != 12) hour += 12;
      if (t.contains('AM') && hour == 12) hour = 0;
      return DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        hour,
        minute,
      );
    } catch (_) {
      return _selectedDate;
    }
  }

  bool get _canProceed {
    switch (_step) {
      case 0:
        return _selectedService != null;
      case 1:
        return _selectedDoctorData != null;
      case 2:
        return _selectedDate != null && _selectedTime != null;
      default:
        return true;
    }
  }

  void _nextStep() {
    if (_step < 3) setState(() => _step++);
  }

  void _prevStep() {
    if (_step > 0) setState(() => _step--);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFF0FAF7),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFD4EDEA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF00897B),
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Request Sent!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF004D40),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your appointment request has been sent to the doctor. '
              "You'll be notified once it's accepted.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF00695C), fontSize: 13),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00897B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          _step == 0 ? Navigator.pop(context) : _prevStep(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4EDEA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFF00897B),
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Book Appointment',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        Text(
                          _stepLabel(),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: List.generate(4, (i) {
                    final active = i == _step;
                    final done = i < _step;
                    return Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 4,
                              decoration: BoxDecoration(
                                color: done || active
                                    ? const Color(0xFF00897B)
                                    : const Color(0xFFB2DFDB),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          if (i < 3) const SizedBox(width: 6),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildStepContent(),
                ),
              ),
              if (_step < 3)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: NeonButton(
                    label: _step == 2 ? 'Review Booking' : 'Continue',
                    icon: Icons.arrow_forward_rounded,
                    height: 52,
                    onPressed: _canProceed ? _nextStep : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _stepLabel() {
    switch (_step) {
      case 0:
        return 'Step 1 of 4 — Choose a service';
      case 1:
        return 'Step 2 of 4 — Choose a doctor';
      case 2:
        return 'Step 3 of 4 — Pick a date & time';
      case 3:
        return 'Step 4 of 4 — Confirm booking';
      default:
        return '';
    }
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildServiceStep();
      case 1:
        return _buildDoctorStep();
      case 2:
        return _buildDateTimeStep();
      case 3:
        return _buildConfirmStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildServiceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What service do you need?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Select one service to continue',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.25,
          children: _services.map((s) {
            final selected = _selectedService == s['name'];
            return GestureDetector(
              onTap: () =>
                  setState(() => _selectedService = s['name'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selected
                      ? (s['color'] as Color).withOpacity(0.15)
                      : const Color(0xFFF0FAF7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? s['color'] as Color
                        : const Color(0xFFB2DFDB),
                    width: selected ? 2 : 0.8,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (s['color'] as Color).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        s['icon'] as IconData,
                        color: s['color'] as Color,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s['name'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: selected
                            ? s['color'] as Color
                            : const Color(0xFF004D40),
                      ),
                    ),
                    if (selected)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: s['color'] as Color,
                          size: 16,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDoctorStep() {
    if (_loadingDoctors) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: Color(0xFF00897B)),
        ),
      );
    }

    if (_doctors.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              const Icon(
                Icons.person_off_rounded,
                color: AppColors.textMuted,
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'No doctors available yet',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Please check back later.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadDoctors,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00897B),
                  side: const BorderSide(color: Color(0xFF00897B)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose your doctor',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'For $_selectedService',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        ..._doctors.map((d) {
          final selected = _selectedDoctorData?['id'] == d['id'];
          return GestureDetector(
            onTap: () => setState(() => _selectedDoctorData = d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF00897B).withOpacity(0.10)
                    : const Color(0xFFF0FAF7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF00897B)
                      : const Color(0xFFB2DFDB),
                  width: selected ? 2 : 0.8,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD4EDEA),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF00897B),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d['name'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF004D40),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          d['specialty'] as String,
                          style: const TextStyle(
                            color: Color(0xFF00695C),
                            fontSize: 12,
                          ),
                        ),
                        if ((d['city'] as String).isNotEmpty)
                          Text(
                            d['city'] as String,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF00897B),
                      size: 22,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDateTimeStep() {
    final daysInMonth = DateUtils.getDaysInMonth(
      _focusedMonth.year,
      _focusedMonth.month,
    );
    final firstWeekday =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday % 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Date & Time',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 16),
        NeonPanel(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() {
                      _focusedMonth = DateTime(
                        _focusedMonth.year,
                        _focusedMonth.month - 1,
                      );
                    }),
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: AppColors.text,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      _focusedMonth = DateTime(
                        _focusedMonth.year,
                        _focusedMonth.month + 1,
                      );
                    }),
                    icon: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 4),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: firstWeekday + daysInMonth,
                itemBuilder: (_, i) {
                  if (i < firstWeekday) return const SizedBox();
                  final day = i - firstWeekday + 1;
                  final date = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month,
                    day,
                  );
                  final isSelected =
                      _selectedDate != null && _isSameDay(date, _selectedDate!);
                  final isPast = date.isBefore(
                    DateTime.now().subtract(const Duration(days: 1)),
                  );
                  return GestureDetector(
                    onTap: isPast
                        ? null
                        : () => setState(() => _selectedDate = date),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF00897B)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : isPast
                                ? AppColors.textMuted.withOpacity(0.4)
                                : AppColors.text,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Available Times',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _times.map((t) {
            final selected = _selectedTime == t;
            return GestureDetector(
              onTap: () => setState(() => _selectedTime = t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF00897B)
                      : const Color(0xFFF0FAF7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF00897B)
                        : const Color(0xFFB2DFDB),
                  ),
                ),
                child: Text(
                  t,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF004D40),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildConfirmStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirm Appointment',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Please review your booking details',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 20),
        NeonPanel(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _confirmRow(
                Icons.medical_services_rounded,
                'Service',
                _selectedService ?? '—',
                const Color(0xFF00897B),
              ),
              const Divider(color: Color(0xFFB2DFDB), height: 24),
              _confirmRow(
                Icons.person_rounded,
                'Doctor',
                _selectedDoctorData?['name'] ?? '—',
                const Color(0xFF00ACC1),
              ),
              const Divider(color: Color(0xFFB2DFDB), height: 24),
              _confirmRow(
                Icons.calendar_today_rounded,
                'Date',
                _selectedDate != null
                    ? '${_selectedDate!.day} ${_monthName(_selectedDate!.month)} ${_selectedDate!.year}'
                    : '—',
                const Color(0xFF26A69A),
              ),
              const Divider(color: Color(0xFFB2DFDB), height: 24),
              _confirmRow(
                Icons.access_time_rounded,
                'Time',
                _selectedTime ?? '—',
                const Color(0xFF00695C),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFCC02), width: 0.8),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Color(0xFFF9A825),
                size: 18,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Your request will be sent to the doctor. You'll be notified once it's accepted or refused.",
                  style: TextStyle(fontSize: 12, color: Color(0xFF795548)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: NeonButton(
            label: 'Confirm Appointment',
            icon: Icons.check_rounded,
            height: 52,
            onPressed: () async {
              await _saveAppointment();
              if (mounted) {
                Navigator.pop(context);
                _showSuccessDialog();
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFB2DFDB)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF00897B), fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _confirmRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
