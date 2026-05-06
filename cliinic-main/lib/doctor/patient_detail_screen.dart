import 'package:flutter/material.dart';
import 'doctor_colors.dart';
import 'add_appointment_screen.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<String?> uploadToCloudinaryWeb(
  Uint8List fileBytes,
  String fileName,
) async {
  final url = Uri.parse(
    "https://api.cloudinary.com/v1_1/dsd8zea8q/auto/upload",
  );
  final request = http.MultipartRequest('POST', url)
    ..fields['upload_preset'] = 'doctor_license'
    ..files.add(
      http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
    );
  final response = await request.send();
  final resBody = await response.stream.bytesToString();
  if (response.statusCode == 200) {
    final match = RegExp(r'"secure_url":"(.*?)"').firstMatch(resBody);
    return match?.group(1);
  }
  return null;
}

class PatientDetailScreen extends StatefulWidget {
  final String patientId; // Firestore document ID in patients/
  final String name;
  final String initials;
  final Color avatarColor;

  const PatientDetailScreen({
    super.key,
    required this.patientId,
    required this.name,
    required this.initials,
    required this.avatarColor,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  Map<String, dynamic> _patientInfo = {};
  bool _loadingInfo = true;
  bool _uploadingXray = false;

  String get _doctorId => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _loadPatientInfo();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadPatientInfo() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _patientInfo = doc.data()!;
          _loadingInfo = false;
        });
      } else {
        if (mounted) setState(() => _loadingInfo = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingInfo = false);
    }
  }

  // ── MEDICAL RECORDS (Firestore) ───────────────────────────────
  Stream<QuerySnapshot> get _diagnosisStream => FirebaseFirestore.instance
      .collection('medical_records')
      .where('patientId', isEqualTo: widget.patientId)
      .orderBy('createdAt', descending: true)
      .snapshots();

  // ── APPOINTMENTS (Firestore) ───────────────────────────────────
  Stream<QuerySnapshot> get _appointmentsStream => FirebaseFirestore.instance
      .collection('appointments')
      .where('patientId', isEqualTo: widget.patientId)
      .where('doctorId', isEqualTo: _doctorId)
      .snapshots();

  // ── REQUESTS (pending appointments from this patient) ─────────
  Stream<QuerySnapshot> get _requestsStream => FirebaseFirestore.instance
      .collection('appointments')
      .where('patientId', isEqualTo: widget.patientId)
      .where('doctorId', isEqualTo: _doctorId)
      .where('status', isEqualTo: 'pending')
      .snapshots();

  // ── X-RAY (Firestore) ─────────────────────────────────────────
  Stream<QuerySnapshot> get _xrayStream => FirebaseFirestore.instance
      .collection('xray')
      .where('patientId', isEqualTo: widget.patientId)
      .orderBy('createdAt', descending: true)
      .snapshots();

  void _addDiagnosis() {
    final titleCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final treatmentCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DC.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Diagnosis',
                style: TextStyle(
                    color: DC.text,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _sheetField(titleCtrl, 'Diagnosis Title', Icons.title),
            const SizedBox(height: 12),
            _sheetField(treatmentCtrl, 'Treatment', Icons.medication_outlined),
            const SizedBox(height: 12),
            _sheetField(notesCtrl, 'Notes', Icons.note_outlined, maxLines: 3),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DC.green,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty) return;
                  await FirebaseFirestore.instance
                      .collection('medical_records')
                      .add({
                    'patientId': widget.patientId,
                    'patientName': widget.name,
                    'doctorId': _doctorId,
                    'title': titleCtrl.text.trim(),
                    'diagnosis': titleCtrl.text.trim(),
                    'treatment': treatmentCtrl.text.trim(),
                    'notes': notesCtrl.text.trim().isEmpty
                        ? 'No notes provided.'
                        : notesCtrl.text.trim(),
                    'createdAt': Timestamp.now(),
                  });
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Save Diagnosis',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addXray() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf'],
      withData: true,
    );
    if (result == null) return;

    final fileBytes = result.files.single.bytes!;
    final fileName = result.files.single.name;

    setState(() => _uploadingXray = true);

    try {
      String? url = await uploadToCloudinaryWeb(fileBytes, fileName);
      if (url != null) {
        await FirebaseFirestore.instance.collection('xray').add({
          'patientId': widget.patientId,
          'patientName': widget.name,
          'doctorId': _doctorId,
          'fileUrl': url,
          'fileName': fileName,
          'createdAt': Timestamp.now(),
        });
      }
    } catch (e) {
      debugPrint('X-Ray upload error: $e');
    }
    if (mounted) setState(() => _uploadingXray = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DC.bg,
      appBar: AppBar(
        backgroundColor: DC.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: DC.text, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Patient Record',
            style: TextStyle(color: DC.text, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: DC.border),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: DC.green),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AddAppointmentScreen(patientName: widget.name),
              ),
            ),
            tooltip: 'Add Appointment',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          TabBar(
            controller: _tabs,
            indicatorColor: DC.green,
            labelColor: DC.green,
            unselectedLabelColor: DC.textSub,
            indicatorWeight: 2,
            labelStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Info'),
              Tab(text: 'Requests'),
              Tab(text: 'Diagnostic'),
              Tab(text: 'X-Ray'),
              Tab(text: 'RDV'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _buildInfoTab(),
                _buildRequestsTab(),
                _buildDiagnosisTab(),
                _buildXRayTab(),
                _buildAppointmentsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Hero(
            tag: 'patient_${widget.name}',
            child: CircleAvatar(
              radius: 35,
              backgroundColor: widget.avatarColor.withOpacity(0.15),
              child: Text(widget.initials,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: widget.avatarColor)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.name,
                    style: const TextStyle(
                        color: DC.text,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text(
                  _patientInfo['phone'] ?? '',
                  style: const TextStyle(color: DC.textSub, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: DC.greenGlow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: DC.border),
                  ),
                  child: const Text('Active Patient',
                      style: TextStyle(
                          color: DC.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── INFO TAB ─────────────────────────────────────────────────
  Widget _buildInfoTab() {
    if (_loadingInfo) {
      return const Center(child: CircularProgressIndicator(color: DC.green));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoCard('Informations Personnelles', [
          _infoRow(Icons.cake_outlined, 'Date de naissance',
              _patientInfo['dob'] ?? '—'),
          _infoRow(Icons.wc_outlined, 'Genre',
              _patientInfo['gender'] ?? '—'),
          _infoRow(Icons.phone_outlined, 'Téléphone',
              _patientInfo['phone'] ?? '—'),
          _infoRow(Icons.email_outlined, 'Email',
              _patientInfo['email'] ?? '—'),
          _infoRow(Icons.location_on_outlined, 'Adresse',
              _patientInfo['address'] ?? '—'),
        ]),
        const SizedBox(height: 14),
        _infoCard('Antécédents Médicaux', [
          _infoRow(Icons.bloodtype_outlined, 'Groupe sanguin',
              _patientInfo['bloodType'] ?? '—'),
          _infoRow(Icons.warning_amber_outlined, 'Allergies',
              _patientInfo['allergies'] ?? '—'),
        ]),
      ],
    );
  }

  Widget _infoCard(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: DC.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: DC.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: DC.green, size: 16),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(color: DC.textSub, fontSize: 13)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: DC.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // ── ACCEPT / REFUSE HELPERS ──────────────────────────────────
  Future<void> _acceptRequest(String appointmentId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.update(
        FirebaseFirestore.instance.collection('appointments').doc(appointmentId),
        {'status': 'confirmed'},
      );
      batch.update(
        FirebaseFirestore.instance
            .collection('doctors')
            .doc(_doctorId)
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
    } catch (e) {
      debugPrint('Accept error: $e');
    }
  }

  void _refuseRequest(String appointmentId) {
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
            Text("Refusing ${widget.name}'s request.",
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
              try {
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
                      .doc(_doctorId)
                      .collection('appointments')
                      .doc(appointmentId),
                  {'status': 'cancelled', 'refuseReason': reasonCtrl.text.trim()},
                );
                await batch.commit();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Request declined',
                        style: TextStyle(color: DC.text)),
                    backgroundColor: DC.card,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              } catch (e) {
                debugPrint('Refuse error: $e');
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

  // ── REQUESTS TAB ─────────────────────────────────────────────
  Widget _buildRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _requestsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: DC.green));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _emptyState(Icons.pending_actions_outlined, 'No pending requests');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final ts = data['date'] as Timestamp?;
            String dateStr = '—';
            String timeStr = data['time'] ?? '';
            if (ts != null) {
              final dt = ts.toDate();
              dateStr = '${dt.day} ${_monthName(dt.month)} ${dt.year}';
              if (timeStr.isEmpty) {
                timeStr =
                    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
              }
            }
            final service = data['service'] ?? 'Appointment';
            final reason = data['reason'] ?? '';
            final xrayUrl = data['xrayUrl'] as String? ?? '';
            final appointmentId = docs[i].id;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: DC.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row ────────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: DC.warning.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.pending_actions_outlined,
                            color: DC.warning, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(service,
                                style: const TextStyle(
                                    color: DC.text,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            const SizedBox(height: 2),
                            Row(children: [
                              const Icon(Icons.calendar_today_outlined,
                                  color: DC.green, size: 12),
                              const SizedBox(width: 4),
                              Text('$dateStr${timeStr.isNotEmpty ? ' · $timeStr' : ''}',
                                  style: const TextStyle(
                                      color: DC.textSub, fontSize: 11)),
                            ]),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: DC.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: DC.warning.withOpacity(0.4)),
                        ),
                        child: const Text('PENDING',
                            style: TextStyle(
                                color: DC.warning,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),

                  // ── Reason ───────────────────────────────────
                  if (reason.toString().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: DC.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: DC.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.notes_rounded,
                              color: DC.textSub, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(reason.toString(),
                                style: const TextStyle(
                                    color: DC.textSub, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── X-Ray preview (if attached) ───────────────
                  if (xrayUrl.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Row(children: [
                      Icon(Icons.image_outlined, color: DC.info, size: 14),
                      SizedBox(width: 6),
                      Text('Attached X-Ray',
                          style: TextStyle(
                              color: DC.info,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _viewXRay(xrayUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            Image.network(
                              xrayUrl,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 80,
                                decoration: BoxDecoration(
                                  color: DC.card,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Icon(Icons.broken_image_outlined,
                                      color: DC.textMuted),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.zoom_in_rounded,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // ── Action buttons ────────────────────────────
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _refuseRequest(appointmentId),
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
                          onPressed: () => _acceptRequest(appointmentId),
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
              ),
            );
          },
        );
      },
    );
  }

  // ── DIAGNOSIS TAB ─────────────────────────────────────────────
  Widget _buildDiagnosisTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _diagnosisStream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('${docs.length} diagnostic(s)',
                      style: const TextStyle(
                          color: DC.textSub, fontSize: 12)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _addDiagnosis,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: DC.greenGlow,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: DC.border),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add_rounded, color: DC.green, size: 14),
                          SizedBox(width: 4),
                          Text('Ajouter Diagnostic',
                              style:
                                  TextStyle(color: DC.green, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const Center(
                      child: CircularProgressIndicator(color: DC.green))
                  : docs.isEmpty
                      ? _emptyState(Icons.assignment_outlined,
                          'Aucun diagnostic enregistré')
                      : ListView.builder(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: docs.length,
                          itemBuilder: (_, i) {
                            final data =
                                docs[i].data() as Map<String, dynamic>;
                            final ts = data['createdAt'] as Timestamp?;
                            String dateStr = '';
                            if (ts != null) {
                              final dt = ts.toDate();
                              dateStr =
                                  '${dt.day}/${dt.month}/${dt.year}';
                            }
                            return Container(
                              margin:
                                  const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: DC.cardDecoration,
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                          Icons.medical_services_outlined,
                                          color: DC.green,
                                          size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          data['title'] ??
                                              data['diagnosis'] ??
                                              '—',
                                          style: const TextStyle(
                                              color: DC.text,
                                              fontWeight:
                                                  FontWeight.bold),
                                        ),
                                      ),
                                      Text(dateStr,
                                          style: const TextStyle(
                                              color: DC.textSub,
                                              fontSize: 11)),
                                    ],
                                  ),
                                  if ((data['treatment'] ?? '')
                                      .toString()
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(children: [
                                      const Icon(Icons.medication_outlined,
                                          color: DC.info, size: 14),
                                      const SizedBox(width: 6),
                                      Text(data['treatment'] as String,
                                          style: const TextStyle(
                                              color: DC.info,
                                              fontSize: 12)),
                                    ]),
                                  ],
                                  if ((data['notes'] ?? '')
                                      .toString()
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(data['notes'] as String,
                                        style: const TextStyle(
                                            color: DC.textSub,
                                            fontSize: 13)),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }

  // ── X-RAY TAB ─────────────────────────────────────────────────
  Widget _buildXRayTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _xrayStream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('${docs.length} X-Ray(s)',
                      style: const TextStyle(
                          color: DC.textSub, fontSize: 12)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _uploadingXray ? null : _addXray,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: DC.greenGlow,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: DC.border),
                      ),
                      child: _uploadingXray
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: DC.green, strokeWidth: 2))
                          : const Row(
                              children: [
                                Icon(Icons.add_photo_alternate_outlined,
                                    color: DC.green, size: 14),
                                SizedBox(width: 4),
                                Text('Ajouter X-Ray',
                                    style: TextStyle(
                                        color: DC.green, fontSize: 12)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const Center(
                      child: CircularProgressIndicator(color: DC.green))
                  : docs.isEmpty
                      ? _emptyState(Icons.image_search_outlined,
                          'Aucune image X-Ray')
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: docs.length,
                          itemBuilder: (_, i) {
                            final data =
                                docs[i].data() as Map<String, dynamic>;
                            final url =
                                data['fileUrl'] as String? ?? '';
                            final ts =
                                data['createdAt'] as Timestamp?;
                            String dateStr = '';
                            if (ts != null) {
                              final dt = ts.toDate();
                              dateStr = '${dt.day}/${dt.month}/${dt.year}';
                            }
                            return GestureDetector(
                              onTap: () => _viewXRay(url),
                              child: Container(
                                decoration: DC.cardDecoration,
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(15),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        url,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Center(
                                          child: Icon(
                                              Icons.broken_image_outlined,
                                              color: DC.textMuted),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          padding:
                                              const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin:
                                                  Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [
                                                Colors.black87,
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                          child: Text(dateStr,
                                              style: const TextStyle(
                                                  color: DC.text,
                                                  fontSize: 10)),
                                        ),
                                      ),
                                      const Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Icon(Icons.zoom_in_rounded,
                                            color: DC.green, size: 18),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }

  void _viewXRay(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('X-Ray Viewer',
                style: TextStyle(color: Colors.white)),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: Image.network(
                url,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image, color: DC.textMuted),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── APPOINTMENTS TAB ─────────────────────────────────────────
  Widget _buildAppointmentsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _appointmentsStream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('${docs.length} rendez-vous',
                      style: const TextStyle(
                          color: DC.textSub, fontSize: 12)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddAppointmentScreen(
                            patientName: widget.name),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: DC.greenGlow,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: DC.border),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add_rounded, color: DC.green, size: 14),
                          SizedBox(width: 4),
                          Text('Ajouter RDV',
                              style:
                                  TextStyle(color: DC.green, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const Center(
                      child: CircularProgressIndicator(color: DC.green))
                  : docs.isEmpty
                      ? _emptyState(Icons.calendar_today_outlined,
                          'Aucun rendez-vous')
                      : ListView.builder(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: docs.length,
                          itemBuilder: (_, i) {
                            final data =
                                docs[i].data() as Map<String, dynamic>;
                            final ts = data['date'] as Timestamp?;
                            String dateStr = '—';
                            if (ts != null) {
                              final dt = ts.toDate();
                              dateStr =
                                  '${dt.day}/${dt.month}/${dt.year}';
                            }
                            final status =
                                data['status'] as String? ?? 'pending';
                            final color = status == 'confirmed'
                                ? DC.green
                                : status == 'cancelled'
                                    ? DC.danger
                                    : DC.warning;
                            return Container(
                              margin:
                                  const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: DC.cardDecoration,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                        Icons.calendar_today_outlined,
                                        color: color,
                                        size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['service'] ??
                                              'Appointment',
                                          style: const TextStyle(
                                              color: DC.text,
                                              fontWeight:
                                                  FontWeight.bold),
                                        ),
                                        Text(
                                          '$dateStr · ${data['time'] ?? ''}',
                                          style: const TextStyle(
                                              color: DC.textSub,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      border: Border.all(
                                          color:
                                              color.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                          color: color,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _emptyState(IconData icon, String msg) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: DC.textMuted, size: 48),
        const SizedBox(height: 12),
        Text(msg, style: const TextStyle(color: DC.textSub)),
      ]),
    );
  }

  Widget _sheetField(TextEditingController c, String label, IconData icon,
      {int maxLines = 1}) {
    return TextField(
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
    );
  }
}
