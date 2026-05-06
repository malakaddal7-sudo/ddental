import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_colors.dart';
 
class MedicalRecordsPage extends StatefulWidget {
  const MedicalRecordsPage({super.key});
 
  @override
  State<MedicalRecordsPage> createState() => _MedicalRecordsPageState();
}
 
class _MedicalRecordsPageState extends State<MedicalRecordsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  bool _loading = true;
 
  List<Map<String, dynamic>> _records = [];
 
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRecords();
  }
 
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
 
  Future<void> _loadRecords() async {
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
 
    final uid = user.uid;
    final List<Map<String, dynamic>> records = [];
 
    try {
      // ── 1. Appointments as records ──────────────────────────────────────────
      final apptSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('appointments')
          .get();
 
      for (final doc in apptSnap.docs) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString().toLowerCase();
        final date = (data['date'] as Timestamp?)?.toDate();
        String dateStr = '—';
        if (date != null) {
          dateStr =
              '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year}';
        }
        final service = (data['service'] ?? 'General').toString();
        final recStatus = status == 'completed'
            ? 'Normal'
            : status == 'confirmed'
                ? 'Upcoming'
                : status == 'cancelled'
                    ? 'Cancelled'
                    : 'Pending';
 
        records.add({
          'title': _serviceTitle(service),
          'doctor': data['doctorName'] ?? 'Doctor',
          'date': dateStr,
          'type': _serviceType(service),
          'icon': _serviceIcon(service),
          'color': _serviceColor(service),
          'size': '—',
          'status': recStatus,
          'statusColor': _statusColor(recStatus),
        });
      }
 
      // ── 2. Medical records added by doctor (global collection, by patientId) ──
      try {
        final medSnap = await FirebaseFirestore.instance
            .collection('medical_records')
            .where('patientId', isEqualTo: uid)
            .get();

        for (final doc in medSnap.docs) {
          final data = doc.data();
          final date = (data['createdAt'] as Timestamp?)?.toDate();
          String dateStr = '—';
          if (date != null) {
            dateStr =
                '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year}';
          }
          records.add({
            'title': data['title'] ?? data['diagnosis'] ?? 'Diagnosis',
            'doctor': data['doctorName'] ?? 'Your Doctor',
            'date': dateStr,
            'type': 'Reports',
            'icon': Icons.medical_information_rounded,
            'color': AppColors.neonTeal,
            'size': '—',
            'status': 'Normal',
            'statusColor': AppColors.neonTeal,
            'notes': data['notes'] ?? '',
            'treatment': data['treatment'] ?? '',
          });
        }
      } catch (_) {}

      // ── 2b. Diagnoses sub-collection (legacy fallback) ──────────────────────
      try {
        final diagSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('diagnoses')
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
            'title': data['diagnosis'] ?? 'Diagnosis',
            'doctor': data['doctorName'] ?? 'Doctor',
            'date': dateStr,
            'type': 'Reports',
            'icon': Icons.medical_information_rounded,
            'color': AppColors.neonTeal,
            'size': '—',
            'status': 'Normal',
            'statusColor': AppColors.neonTeal,
          });
        }
      } catch (_) {}
 
      // ── 3. X-Ray sub-collection ─────────────────────────────────────────────
      try {
        final xraySnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('xrays')
            .get();
 
        for (final doc in xraySnap.docs) {
          final data = doc.data();
          final date = (data['uploadedAt'] as Timestamp?)?.toDate();
          String dateStr = '—';
          if (date != null) {
            dateStr =
                '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year}';
          }
          records.add({
            'title': data['label'] ?? 'X-Ray Image',
            'doctor': data['doctorName'] ?? 'Doctor',
            'date': dateStr,
            'type': 'Lab',
            'icon': Icons.image_rounded,
            'color': const Color(0xFF2EF3FF),
            'size': '—',
            'status': 'Normal',
            'statusColor': AppColors.neonCyan,
            'imageUrl': data['imageUrl'],
          });
        }
      } catch (_) {}
 
      setState(() {
        _records = records;
        _loading = false;
      });
    } catch (e) {
      debugPrint('MedicalRecords load error: $e');
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
 
  String _serviceTitle(String service) {
    switch (service.toLowerCase()) {
      case 'cleaning':
        return 'Dental Cleaning';
      case 'checkup':
        return 'General Checkup';
      case 'x-ray':
      case 'xray':
        return 'Dental X-Ray';
      case 'filling':
        return 'Dental Filling';
      case 'extraction':
        return 'Tooth Extraction';
      case 'whitening':
        return 'Teeth Whitening';
      default:
        return service.isNotEmpty ? service : 'Appointment';
    }
  }
 
  String _serviceType(String service) {
    switch (service.toLowerCase()) {
      case 'x-ray':
      case 'xray':
        return 'Lab';
      default:
        return 'Reports';
    }
  }
 
  IconData _serviceIcon(String service) {
    switch (service.toLowerCase()) {
      case 'cleaning':
        return Icons.clean_hands_rounded;
      case 'x-ray':
      case 'xray':
        return Icons.image_rounded;
      case 'checkup':
        return Icons.medical_services_rounded;
      case 'filling':
        return Icons.construction_rounded;
      default:
        return Icons.local_hospital_rounded;
    }
  }
 
  Color _serviceColor(String service) {
    switch (service.toLowerCase()) {
      case 'x-ray':
      case 'xray':
        return const Color(0xFF2EF3FF);
      case 'cleaning':
        return const Color(0xFF10D7C8);
      case 'filling':
        return Colors.purple;
      case 'extraction':
        return Colors.redAccent;
      default:
        return AppColors.neonTeal;
    }
  }
 
  Color _statusColor(String status) {
    switch (status) {
      case 'Normal':
        return AppColors.neonTeal;
      case 'Upcoming':
        return Colors.orange;
      case 'Cancelled':
        return Colors.red;
      default:
        return AppColors.textMuted;
    }
  }
 
  List<Map<String, dynamic>> get _filtered {
    final q = _searchQuery.toLowerCase();
    final tabType = _tabController.index == 1
        ? 'Lab'
        : _tabController.index == 2
            ? 'Reports'
            : null;
 
    return _records.where((r) {
      final matchesSearch = q.isEmpty ||
          (r['title'] as String).toLowerCase().contains(q) ||
          (r['doctor'] as String).toLowerCase().contains(q);
      final matchesTab =
          tabType == null || (r['type'] as String) == tabType;
      return matchesSearch && matchesTab;
    }).toList();
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _statCard('Total', '${_records.length}',
                        Icons.folder_rounded, AppColors.neonCyan),
                    const SizedBox(width: 12),
                    _statCard(
                        'Normal',
                        '${_records.where((r) => r['status'] == 'Normal').length}',
                        Icons.check_circle_rounded,
                        AppColors.neonTeal),
                    const SizedBox(width: 12),
                    _statCard(
                        'Review',
                        '${_records.where((r) => r['status'] != 'Normal').length}',
                        Icons.warning_rounded,
                        Colors.orange),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: AppColors.text),
                  decoration: InputDecoration(
                    hintText: 'Search records...',
                    hintStyle:
                        const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.neonCyan),
                    filled: true,
                    fillColor: AppColors.panel,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.stroke)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.stroke)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.neonCyan, width: 1.5)),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.panel,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.stroke),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    onTap: (_) => setState(() {}),
                    indicator: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textMuted,
                    labelStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(text: 'All'),
                      Tab(text: 'Lab'),
                      Tab(text: 'Reports')
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.neonCyan))
                    : _filtered.isEmpty
                        ? _emptyState()
                        : RefreshIndicator(
                            onRefresh: _loadRecords,
                            color: AppColors.neonCyan,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20),
                              itemCount: _filtered.length,
                              itemBuilder: (ctx, i) =>
                                  _recordCard(_filtered[i]),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
 
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.neonCyan),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          const Text('Medical Records',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.neonCyan),
            onPressed: _loadRecords,
          ),
        ],
      ),
    );
  }
 
  Widget _statCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 10)),
          ],
        ),
      ),
    );
  }
 
  Widget _recordCard(Map<String, dynamic> record) {
    final color = record['color'] as Color;
    final statusColor = record['statusColor'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.neonCyan.withOpacity(0.12)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(record['icon'] as IconData,
              color: color, size: 24),
        ),
        title: Text(record['title'] as String,
            style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(record['doctor'] as String,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 10, color: AppColors.textMuted),
                const SizedBox(width: 3),
                Text(record['date'] as String,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(record['status'] as String,
              style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ),
        onTap: () {},
      ),
    );
  }
 
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded,
              size: 60,
              color: AppColors.textMuted.withOpacity(0.4)),
          const SizedBox(height: 12),
          const Text('No records found',
              style: TextStyle(color: AppColors.textMuted)),
          if (_records.isEmpty) ...[
            const SizedBox(height: 6),
            const Text(
              'Your medical records will appear here\nonce you start booking appointments.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 12),
            ),
          ]
        ],
      ),
    );
  }
}