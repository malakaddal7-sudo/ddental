import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'doctor_colors.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});
  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  String _search = '';
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  Stream<QuerySnapshot> get _stream => FirebaseFirestore.instance
      .collection('medical_records')
      .where('doctorId', isEqualTo: _uid)
      .orderBy('createdAt', descending: true)
      .snapshots();

  String _monthName(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }

  void _createRecord() {
    final diagnosisCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final treatmentCtrl = TextEditingController();
    String? selectedPatientId;
    String? selectedPatientName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DC.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Créer Dossier Médical',
                    style: TextStyle(
                        color: DC.text, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance.collection('users').get(),
                  builder: (_, snap) {
                    final patients = snap.data?.docs ?? [];
                    return DropdownButtonFormField<String>(
                      value: selectedPatientId,
                      dropdownColor: DC.surface,
                      style: const TextStyle(color: DC.text),
                      decoration: InputDecoration(
                        labelText: 'Sélectionner un patient',
                        labelStyle: const TextStyle(color: DC.textMuted),
                        prefixIcon: const Icon(Icons.person_outline, color: DC.green),
                        filled: true,
                        fillColor: DC.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: DC.border),
                        ),
                      ),
                      items: patients.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        final name = '${d['firstName'] ?? ''} ${d['lastName'] ?? ''}'.trim();
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(name.isNotEmpty ? name : doc.id,
                              style: const TextStyle(color: DC.text)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setSheetState(() {
                          selectedPatientId = val;
                          final doc = patients.firstWhere((d) => d.id == val);
                          final d = doc.data() as Map<String, dynamic>;
                          selectedPatientName = '${d['firstName'] ?? ''} ${d['lastName'] ?? ''}'.trim();
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                _sheetField(diagnosisCtrl, 'Diagnostic', Icons.medical_services_outlined),
                const SizedBox(height: 12),
                _sheetField(treatmentCtrl, 'Traitement', Icons.medication_outlined),
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
                      if (selectedPatientId == null ||
                          diagnosisCtrl.text.trim().isEmpty) return;
                      await FirebaseFirestore.instance
                          .collection('medical_records')
                          .add({
                        'doctorId': _uid,
                        'patientId': selectedPatientId,
                        'patientName': selectedPatientName ?? '',
                        'title': diagnosisCtrl.text.trim(),
                        'diagnosis': diagnosisCtrl.text.trim(),
                        'treatment': treatmentCtrl.text.trim(),
                        'notes': notesCtrl.text.trim(),
                        'createdAt': Timestamp.now(),
                      });
                      if (mounted) Navigator.pop(context);
                    },
                    child: const Text('Enregistrer',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editRecord(String docId, Map<String, dynamic> data) {
    final diagnosisCtrl =
        TextEditingController(text: data['diagnosis'] ?? '');
    final notesCtrl = TextEditingController(text: data['notes'] ?? '');
    final treatmentCtrl =
        TextEditingController(text: data['treatment'] ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DC.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Modifier — ${data['patientName'] ?? ''}',
                    style: const TextStyle(
                        color: DC.text,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _sheetField(diagnosisCtrl, 'Diagnostic', Icons.medical_services_outlined),
            const SizedBox(height: 12),
            _sheetField(treatmentCtrl, 'Traitement', Icons.medication_outlined),
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
                  await FirebaseFirestore.instance
                      .collection('medical_records')
                      .doc(docId)
                      .update({
                    'diagnosis': diagnosisCtrl.text.trim(),
                    'treatment': treatmentCtrl.text.trim(),
                    'notes': notesCtrl.text.trim(),
                    'updatedAt': Timestamp.now(),
                  });
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Sauvegarder',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRecord(String docId, String patientName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DC.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: DC.border),
        ),
        title: const Text('Supprimer le dossier',
            style: TextStyle(color: DC.text)),
        content: Text('Supprimer le dossier de $patientName ?',
            style: const TextStyle(color: DC.textSub)),
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
      await FirebaseFirestore.instance
          .collection('medical_records')
          .doc(docId)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DC.bg,
      appBar: AppBar(
        backgroundColor: DC.surface,
        elevation: 0,
        title: const Text('Dossiers Médicaux',
            style: TextStyle(color: DC.text, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: DC.border),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: DC.green,
        foregroundColor: Colors.black,
        onPressed: _createRecord,
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: const TextStyle(color: DC.text),
              decoration: InputDecoration(
                hintText: 'Rechercher un patient...',
                hintStyle: const TextStyle(color: DC.textMuted),
                prefixIcon:
                    const Icon(Icons.search, color: DC.green, size: 20),
                filled: true,
                fillColor: DC.card,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: DC.green));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erreur: ${snapshot.error}',
                        style: const TextStyle(color: DC.textSub)),
                  );
                }
                var docs = snapshot.data?.docs ?? [];
                if (_search.isNotEmpty) {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final name = (data['patientName'] ?? '').toString().toLowerCase();
                    return name.contains(_search.toLowerCase());
                  }).toList();
                }
                if (docs.isEmpty) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.folder_open_outlined,
                          color: DC.textMuted, size: 56),
                      const SizedBox(height: 12),
                      const Text('Aucun dossier médical',
                          style: TextStyle(
                              color: DC.text,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      const Text('Appuyez sur + pour créer un dossier.',
                          style:
                              TextStyle(color: DC.textSub, fontSize: 13)),
                    ]),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final ts = data['createdAt'] as Timestamp?;
                    String dateStr = '';
                    if (ts != null) {
                      final dt = ts.toDate();
                      dateStr =
                          '${dt.day} ${_monthName(dt.month)} ${dt.year}';
                    }
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: DC.cardDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: DC.info.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.folder_rounded,
                                    color: DC.info, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(data['patientName'] ?? '—',
                                        style: const TextStyle(
                                            color: DC.text,
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                      data['diagnosis'] ?? '—',
                                      style: const TextStyle(
                                          color: DC.textSub, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Text(dateStr,
                                  style: const TextStyle(
                                      color: DC.textMuted, fontSize: 10)),
                            ],
                          ),
                          if ((data['notes'] ?? '').toString().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: DC.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(data['notes'] as String,
                                  style: const TextStyle(
                                      color: DC.textSub, fontSize: 12)),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _editRecord(doc.id, data),
                                icon: const Icon(Icons.edit_outlined, size: 14),
                                label: const Text('Modifier'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: DC.green,
                                  side: const BorderSide(color: DC.green),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  textStyle: const TextStyle(fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () => _deleteRecord(
                                    doc.id, data['patientName'] ?? ''),
                                icon: const Icon(Icons.delete_outline, size: 14),
                                label: const Text('Supprimer'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: DC.danger,
                                  side: const BorderSide(color: DC.danger),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  textStyle: const TextStyle(fontSize: 12),
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
            ),
          ),
        ],
      ),
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
