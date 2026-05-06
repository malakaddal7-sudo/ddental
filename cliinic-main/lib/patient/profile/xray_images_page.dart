import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import '../../theme/app_colors.dart';

class XRayImagesPage extends StatelessWidget {
  const XRayImagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.neonCyan),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    const Text('My X-Ray Images',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text)),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Info banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.neonCyan.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.neonCyan.withOpacity(0.25)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: AppColors.neonCyan, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'X-Rays shared by your doctor appear here automatically.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('appointments')
                      .where('patientId', isEqualTo: uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.neonCyan, strokeWidth: 2));
                    }

                    // Only show appointments that have an xrayUrl
                    final docs = (snapshot.data?.docs ?? []).where((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final url = d['xrayUrl'];
                      return url != null && (url as String).isNotEmpty;
                    }).toList();

                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported_rounded,
                                size: 60,
                                color: AppColors.textMuted.withOpacity(0.35)),
                            const SizedBox(height: 14),
                            const Text('No X-Ray images yet',
                                style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                            const SizedBox(height: 6),
                            const Text(
                              'When your doctor shares an X-Ray\nit will appear here automatically.',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: docs.length,
                      itemBuilder: (context, i) =>
                          _XRayCard(doc: docs[i]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual X-Ray card widget
// ─────────────────────────────────────────────────────────────────────────────
class _XRayCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  const _XRayCard({required this.doc});

  @override
  State<_XRayCard> createState() => _XRayCardState();
}

class _XRayCardState extends State<_XRayCard> {
  bool _downloading = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.doc.data() as Map<String, dynamic>;
    final xrayUrl = d['xrayUrl'] as String;
    final xrayNote = d['xrayNote'] as String? ?? '';
    final ts = d['xrayUploadedAt'] as Timestamp?;
    final doctorName = d['doctorName'] ?? d['doctor'] ?? 'Doctor';
    final service = d['service'] ?? d['type'] ?? 'Appointment';

    String dateStr = '';
    if (ts != null) {
      final dt = ts.toDate();
      dateStr = '${dt.day}/${dt.month}/${dt.year}';
    }

    final isNew = ts != null &&
        DateTime.now().difference(ts.toDate()).inHours < 24;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neonCyan.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.neonCyan.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.image_rounded,
                      color: AppColors.neonCyan, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(service,
                          style: const TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      Text('$doctorName  ·  $dateStr',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
                if (isNew)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.4)),
                    ),
                    child: const Text('NEW',
                        style: TextStyle(
                            color: Colors.green,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),

          // Image (tappable)
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => _FullscreenXRay(imageUrl: xrayUrl)),
            ),
            child: Image.network(
              xrayUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              loadingBuilder: (ctx, child, prog) {
                if (prog == null) return child;
                return Container(
                  height: 200,
                  color: AppColors.panel2,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(
                      color: AppColors.neonCyan, strokeWidth: 2),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                height: 120,
                color: AppColors.panel2,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_rounded,
                    color: Colors.grey, size: 36),
              ),
            ),
          ),

          // Doctor note
          if (xrayNote.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.neonCyan.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: AppColors.neonCyan.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note_alt_rounded,
                        color: AppColors.neonCyan, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(xrayNote,
                          style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              height: 1.5)),
                    ),
                  ],
                ),
              ),
            ),

          // Buttons
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: AppColors.neonCyan.withOpacity(0.5)),
                      foregroundColor: AppColors.neonCyan,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.fullscreen_rounded, size: 16),
                    label: const Text('View', style: TextStyle(fontSize: 13)),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => _FullscreenXRay(imageUrl: xrayUrl)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonCyan,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: _downloading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black))
                        : const Icon(Icons.download_rounded, size: 16),
                    label: Text(_downloading ? 'Saving...' : 'Download',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                    onPressed: _downloading
                        ? null
                        : () => _download(context, xrayUrl, service),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _download(
      BuildContext context, String url, String label) async {
    setState(() => _downloading = true);
    try {
      // Download bytes using the http package
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');

      final bytes = response.bodyBytes;
      final fileName = 'XRay_${label.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // sharePdf works for any bytes — opens native share/save sheet
      // Android → "Save to Downloads"; iOS → "Save to Files"
      await Printing.sharePdf(bytes: bytes, filename: fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Share sheet opened!\nAndroid: tap "Save to Downloads"\niOS: tap "Save to Files"',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ]),
            backgroundColor: const Color(0xFF00897B),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fullscreen viewer with pinch-to-zoom
// ─────────────────────────────────────────────────────────────────────────────
class _FullscreenXRay extends StatelessWidget {
  final String imageUrl;
  const _FullscreenXRay({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('X-Ray', style: TextStyle(color: Colors.white)),
      ),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 6.0,
        child: Center(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (ctx, child, prog) {
              if (prog == null) return child;
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            },
            errorBuilder: (_, __, ___) => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image_rounded,
                      color: Colors.grey, size: 48),
                  SizedBox(height: 8),
                  Text('Could not load image',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
