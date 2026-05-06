// lib/doctor/xray_upload_widget.dart

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'doctor_colors.dart';

const _cloudName = 'YOUR_CLOUD_NAME';
const _uploadPreset = 'YOUR_UNSIGNED_PRESET';

class XRayUploadWidget extends StatefulWidget {
  final String? patientId;
  final String? patientName;
  final String? appointmentId;

  const XRayUploadWidget({
    super.key,
    this.patientId,
    this.patientName,
    this.appointmentId,
  }) : assert(
         patientId != null || appointmentId != null,
         'Provide either patientId or appointmentId.',
       );

  @override
  State<XRayUploadWidget> createState() => _XRayUploadWidgetState();
}

class _XRayUploadWidgetState extends State<XRayUploadWidget> {
  final _labelCtrl = TextEditingController();
  final _picker = ImagePicker();
  bool _uploading = false;
  double _progress = 0;

  String? _resolvedPatientId;
  String _resolvedPatientName = 'Patient';

  @override
  void initState() {
    super.initState();
    if (widget.patientId != null && widget.patientId!.isNotEmpty) {
      _resolvedPatientId = widget.patientId;
      _resolvedPatientName = widget.patientName ?? 'Patient';
    } else {
      _resolveFromAppointment();
    }
  }

  Future<void> _resolveFromAppointment() async {
    if (widget.appointmentId == null || widget.appointmentId!.isEmpty) return;
    final snap = await FirebaseFirestore.instance
        .collection('appointments')
        .doc(widget.appointmentId)
        .get();
    if (!mounted) return;
    final data = snap.data();
    if (data == null) return;
    setState(() {
      _resolvedPatientId = (data['patientId'] as String?) ?? '';
      _resolvedPatientName = (data['patientName'] as String?) ?? 'Patient';
    });
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<String?> _uploadToCloudinary(File file) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = 'xrays'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();

    int received = 0;
    final total = streamed.contentLength ?? 0;
    final chunks = <int>[];

    await for (final chunk in streamed.stream) {
      chunks.addAll(chunk);
      received += chunk.length;
      if (total > 0 && mounted) {
        setState(() => _progress = received / total);
      }
    }

    if (streamed.statusCode != 200) return null;

    final body = jsonDecode(utf8.decode(chunks)) as Map<String, dynamic>;
    return body['secure_url'] as String?;
  }

  Future<void> _pickAndUpload() async {
    final pid = _resolvedPatientId;
    if (pid == null || pid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient not found. Cannot upload.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    if (!mounted) return;

    final label = _labelCtrl.text.trim().isEmpty
        ? 'X-Ray ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'
        : _labelCtrl.text.trim();

    setState(() {
      _uploading = true;
      _progress = 0;
    });

    try {
      final doctorUid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      final url = await _uploadToCloudinary(File(picked.path));

      if (url == null) throw Exception('Cloudinary returned no URL');

      await FirebaseFirestore.instance
          .collection('patients')
          .doc(pid)
          .collection('xrays')
          .add({
            'imageUrl': url,
            'label': label,
            'uploadedBy': doctorUid,
            'patientId': pid,
            if (widget.appointmentId != null)
              'appointmentId': widget.appointmentId,
            'uploadedAt': FieldValue.serverTimestamp(),
          });

      await FirebaseFirestore.instance
          .collection('patients')
          .doc(pid)
          .collection('notifications')
          .add({
            'type': 'xray_uploaded',
            'label': label,
            'imageUrl': url,
            'doctorId': doctorUid,
            'status': 'unread',
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        _labelCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          // FIX: SnackBar backgroundColor uses DC.green correctly (non-const)
          SnackBar(
            content: const Text('X-Ray uploaded successfully ✓'),
            backgroundColor: DC.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // FIX: moved reset into finally block with proper braces so it always
      // runs whether upload succeeded or threw, and braces prevent the
      // dangling-statement lint warning that the original bare `if` caused.
      if (mounted) {
        setState(() {
          _uploading = false;
          _progress = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Upload card ───────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DC.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DC.green.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              TextField(
                controller: _labelCtrl,
                style: const TextStyle(color: DC.text),
                decoration: InputDecoration(
                  labelText: 'Label (e.g. "Full Panoramic")',
                  labelStyle: const TextStyle(color: DC.textSub, fontSize: 13),
                  prefixIcon: const Icon(
                    Icons.label_outline,
                    color: DC.green,
                    size: 18,
                  ),
                  filled: true,
                  fillColor: DC.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: DC.green.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: DC.green.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: DC.green, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (_uploading) ...[
                LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  backgroundColor: DC.border,
                  // DC.green is not a compile-time constant so no const here
                  valueColor: AlwaysStoppedAnimation<Color>(DC.green),
                ),
                const SizedBox(height: 8),
                Text(
                  'Uploading... ${(_progress * 100).toInt()}%',
                  style: const TextStyle(color: DC.textSub, fontSize: 12),
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _pickAndUpload,
                    icon: const Icon(Icons.upload_rounded),
                    label: const Text(
                      'Select & Upload X-Ray',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DC.green,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Section label ─────────────────────────────────────────────────
        Row(
          children: [
            Container(
              width: 3,
              height: 13,
              decoration: BoxDecoration(
                color: DC.green,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(color: DC.green.withOpacity(0.6), blurRadius: 6),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'UPLOADED X-RAYS',
              style: TextStyle(
                color: DC.green,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Grid ──────────────────────────────────────────────────────────
        if (_resolvedPatientId == null)
          // FIX: removed const — CircularProgressIndicator with a non-const
          // color argument cannot be const
          Center(
            child: CircularProgressIndicator(color: DC.green, strokeWidth: 2),
          )
        else
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('patients')
                .doc(_resolvedPatientId)
                .collection('xrays')
                .orderBy('uploadedAt', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: DC.green,
                    strokeWidth: 2,
                  ),
                );
              }
              final docs = snap.data?.docs ?? [];

              if (docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: DC.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DC.border),
                  ),
                  child: const Center(
                    child: Text(
                      'No X-Rays uploaded yet',
                      style: TextStyle(color: DC.textMuted, fontSize: 13),
                    ),
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.9,
                ),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  final url = d['imageUrl'] as String? ?? '';
                  final lbl = d['label'] as String? ?? 'X-Ray';
                  final ts = d['uploadedAt'] as Timestamp?;
                  final date = ts != null
                      ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
                      : '';
                  return _xrayCard(context, docs[i].id, url, lbl, date);
                },
              );
            },
          ),
      ],
    );
  }

  Widget _xrayCard(
    BuildContext ctx,
    String docId,
    String url,
    String label,
    String date,
  ) {
    final pid = _resolvedPatientId ?? '';

    return Container(
      decoration: BoxDecoration(
        color: DC.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DC.green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: url.isNotEmpty
                  ? Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        // FIX: removed const — Icon with non-const color
                        child: Icon(
                          Icons.broken_image_rounded,
                          color: DC.textMuted,
                          size: 36,
                        ),
                      ),
                    )
                  : Center(
                      // FIX: removed const — Icon with non-const color
                      child: Icon(
                        Icons.image_rounded,
                        color: DC.textMuted,
                        size: 36,
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: DC.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                if (date.isNotEmpty)
                  Text(
                    date,
                    style: const TextStyle(color: DC.textMuted, fontSize: 10),
                  ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () async {
                    if (pid.isNotEmpty) {
                      await FirebaseFirestore.instance
                          .collection('patients')
                          .doc(pid)
                          .collection('xrays')
                          .doc(docId)
                          .delete();
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // FIX: removed const — Icon with non-const color expression
                      Icon(
                        Icons.delete_outline_rounded,
                        color: DC.danger.withOpacity(0.7),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
