import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'doctor_colors.dart';
import 'add_patient_screen.dart';
import 'patient_detail_screen.dart';
 
class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});
  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}
 
class _PatientListScreenState extends State<PatientListScreen> {
  bool _isLoading = true;
  String _search = '';
  List<Map<String, dynamic>> _patients = [];
 
  static const List<Color> _avatarColors = [
    Color(0xFF4ADE80),
    Color(0xFF60A5FA),
    Color(0xFFF472B6),
    Color(0xFFFBBF24),
    Color(0xFFA78BFA),
    Color(0xFF34D399),
    Color(0xFFFB923C),
  ];
 
  List<Map<String, dynamic>> get _filtered => _patients
      .where((p) => (p['name'] as String)
          .toLowerCase()
          .contains(_search.toLowerCase()))
      .toList();
 
  @override
  void initState() {
    super.initState();
    _loadPatients();
  }
 
  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() => _isLoading = false);
        return;
      }
 
      final Map<String, Map<String, dynamic>> seen = {};
      int colorIndex = 0;
 
      // 1. Patients registered directly by this doctor (patients collection)
      final directSnap = await FirebaseFirestore.instance
          .collection('patients')
          .where('doctorId', isEqualTo: uid)
          .get();
 
      for (final doc in directSnap.docs) {
        final data = doc.data();
        final name = (data['name'] ?? 'Patient') as String;
        final initials = _initials(name);
        seen[doc.id] = {
          'id': doc.id,
          'name': name,
          'init': initials,
          'color': _avatarColors[colorIndex % _avatarColors.length],
          'phone': data['phone'] ?? '',
          'nextVisit': '',
          'source': 'registered',
        };
        colorIndex++;
      }
 
      // 2. Self-registered users (users collection)
      // FIX: We no longer filter by doctorIds set because a user's UID being in
      // the doctors collection does NOT mean they aren't also a patient.
      // Instead, we check the user's own 'role' field (if present),
      // OR we just include everyone in 'users' who has a valid name.
      // Doctors are stored in the 'doctors' collection with their own doc,
      // but patients who registered via the patient app are in 'users'.
      // The only users we should exclude are those whose 'role' == 'doctor'.
      final usersSnap = await FirebaseFirestore.instance
          .collection('users')
          .get();
 
      for (final doc in usersSnap.docs) {
        if (seen.containsKey(doc.id)) continue;
        final data = doc.data();
 
        // Skip if user is explicitly tagged as a doctor by role field
        final role = data['role'] as String? ?? '';
        if (role == 'doctor') continue;
 
        // Skip if this UID is the currently logged-in doctor themselves
        if (doc.id == uid) continue;
 
        final firstName = data['firstName'] as String? ?? '';
        final lastName = data['lastName'] as String? ?? '';
        final name = '$firstName $lastName'.trim();
        if (name.isEmpty) continue;
 
        seen[doc.id] = {
          'id': doc.id,
          'name': name,
          'init': _initials(name),
          'color': _avatarColors[colorIndex % _avatarColors.length],
          'phone': data['phone'] ?? '',
          'nextVisit': '',
          'source': 'registered_user',
        };
        colorIndex++;
      }
 
      // 3. ALL appointments for this doctor — pick up any patient not yet seen
      final apptSnap = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: uid)
          .get();
 
      final Set<String> appointmentPatientIds = {};
      final Map<String, Map<String, dynamic>> appointmentDataByPatient = {};
 
      for (final doc in apptSnap.docs) {
        final data = doc.data();
        final patientId = data['patientId'] as String? ?? '';
        if (patientId.isEmpty) continue;
        appointmentPatientIds.add(patientId);
        if (!appointmentDataByPatient.containsKey(patientId)) {
          appointmentDataByPatient[patientId] = data;
        }
      }
 
      for (final patientId in appointmentPatientIds) {
        if (seen.containsKey(patientId)) continue;
 
        final apptData = appointmentDataByPatient[patientId]!;
        String name = (apptData['patientName'] ?? 'Patient') as String;
        String phone = '';
 
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(patientId)
              .get();
          if (userDoc.exists) {
            final ud = userDoc.data()!;
            final fullName =
                '${ud['firstName'] ?? ''} ${ud['lastName'] ?? ''}'.trim();
            if (fullName.isNotEmpty) name = fullName;
            phone = ud['phone'] ?? '';
          }
        } catch (_) {}
 
        final ts = apptData['date'] as Timestamp?;
        String nextVisit = '';
        if (ts != null) {
          final dt = ts.toDate();
          nextVisit = '${dt.day} ${_monthName(dt.month)} ${dt.year}';
        }
        seen[patientId] = {
          'id': patientId,
          'name': name,
          'init': _initials(name),
          'color': _avatarColors[colorIndex % _avatarColors.length],
          'phone': phone,
          'nextVisit': nextVisit,
          'source': 'appointment',
        };
        colorIndex++;
      }
 
      _patients = seen.values.toList();
      // Sort alphabetically
      _patients.sort((a, b) =>
          (a['name'] as String).compareTo(b['name'] as String));
    } catch (e) {
      debugPrint('Error loading patients: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }
 
  String _initials(String name) {
    final init = name
        .trim()
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0])
        .take(2)
        .join()
        .toUpperCase();
    return init.isNotEmpty ? init : '?';
  }
 
  Future<void> _deletePatient(Map<String, dynamic> p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DC.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: DC.border),
        ),
        title: const Text('Supprimer le patient',
            style: TextStyle(color: DC.text)),
        content: Text(
          'Supprimer ${p['name']} de votre liste ?',
          style: const TextStyle(color: DC.textSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler',
                style: TextStyle(color: DC.textSub)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: DC.danger, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        if (p['source'] == 'registered') {
          await FirebaseFirestore.instance
              .collection('patients')
              .doc(p['id'] as String)
              .delete();
        }
        setState(() {
          _patients.removeWhere((x) => x['id'] == p['id']);
        });
      } catch (e) {
        debugPrint('Delete error: $e');
      }
    }
  }
 
  String _monthName(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m - 1];
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DC.bg,
      appBar: AppBar(
        backgroundColor: DC.surface,
        elevation: 0,
        title: const Text('Mes Patients',
            style: TextStyle(color: DC.text, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: DC.border),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: DC.green),
            onPressed: _loadPatients,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: DC.green),
            onPressed: () async {
              final result = await Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const AddPatientScreen()));
              if (result == true) _loadPatients();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: DC.green))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style: const TextStyle(color: DC.text),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un patient...',
                      hintStyle: const TextStyle(color: DC.textMuted),
                      prefixIcon: const Icon(Icons.search,
                          color: DC.green, size: 20),
                      filled: true,
                      fillColor: DC.card,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
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
                        borderSide:
                            const BorderSide(color: DC.green, width: 1.5),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        '${_filtered.length} patient(s)',
                        style:
                            const TextStyle(color: DC.textSub, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _patients.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.people_outline_rounded,
                                  color: DC.textMuted, size: 56),
                              SizedBox(height: 12),
                              Text('Aucun patient',
                                  style: TextStyle(
                                      color: DC.text,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 6),
                              Text(
                                'Inscrivez un patient ou acceptez\nune demande de rendez-vous.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: DC.textSub, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : _filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.search_off_rounded,
                                      color: DC.textMuted, size: 48),
                                  SizedBox(height: 12),
                                  Text('Aucun patient trouvé',
                                      style:
                                          TextStyle(color: DC.textSub)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              physics: const BouncingScrollPhysics(),
                              itemCount: _filtered.length,
                              itemBuilder: (context, i) =>
                                  _buildCard(context, _filtered[i]),
                            ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: DC.green,
        foregroundColor: Colors.black,
        onPressed: () async {
          final result = await Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => const AddPatientScreen()));
          if (result == true) _loadPatients();
        },
        child: const Icon(Icons.person_add_rounded),
      ),
    );
  }
 
  Widget _buildCard(BuildContext context, Map<String, dynamic> p) {
    final color = p['color'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: DC.cardDecoration,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Hero(
          tag: 'patient_${p['id']}',
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('appointments')
                .where('patientId', isEqualTo: p['id'] as String)
                .where('doctorId',
                    isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, snapshot) {
              final pendingCount = snapshot.data?.docs.length ?? 0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: color.withOpacity(0.15),
                    child: Text(p['init'] as String,
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.bold)),
                  ),
                  if (pendingCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$pendingCount',
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        title: Text(p['name'] as String,
            style: const TextStyle(
                color: DC.text, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            if ((p['phone'] as String).isNotEmpty)
              Text(p['phone'] as String,
                  style:
                      const TextStyle(color: DC.textSub, fontSize: 11)),
            if ((p['nextVisit'] as String).isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: DC.green, size: 11),
                  const SizedBox(width: 4),
                  Text('Prochain: ${p['nextVisit']}',
                      style: const TextStyle(
                          color: DC.green, fontSize: 11)),
                ],
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: DC.danger, size: 18),
              onPressed: () => _deletePatient(p),
              tooltip: 'Supprimer',
            ),
            const Icon(Icons.chevron_right_rounded,
                color: DC.textMuted, size: 18),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PatientDetailScreen(
              patientId: p['id'] as String,
              name: p['name'] as String,
              initials: p['init'] as String,
              avatarColor: color,
            ),
          ),
        ),
      ),
    );
  }
}