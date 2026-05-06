import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import '../theme/app_colors.dart';
import '../widgets/neon_panel.dart';
 
/// Widget shown in the patient's appointment detail page.
/// It reads the x-ray image URL stored by the doctor in Firestore
/// under: appointments/{appointmentId}  →  field: xrayUrl
/// and lets the patient view & download it.
class XRayViewWidget extends StatelessWidget {
  final String appointmentId;
 
  const XRayViewWidget({super.key, required this.appointmentId});
 
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .snapshots(),
      builder: (context, snapshot) {
        // ── Loading ──────────────────────────────────────────────────────────
        if (snapshot.connectionState == ConnectionState.waiting) {
          return NeonPanel(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: const [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF00897B),
                  ),
                ),
                SizedBox(width: 12),
                Text('Checking for X-Ray...',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ],
            ),
          );
        }
 
        // ── No data or no xrayUrl ────────────────────────────────────────────
        if (!snapshot.hasData ||
            !snapshot.data!.exists ||
            (snapshot.data!.data() as Map<String, dynamic>?)?['xrayUrl'] ==
                null) {
          return NeonPanel(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.image_not_supported_rounded,
                      color: Colors.grey, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('X-Ray Images',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF004D40))),
                      SizedBox(height: 3),
                      Text('No X-Ray uploaded yet for this appointment.',
                          style:
                              TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
 
        // ── X-Ray available ──────────────────────────────────────────────────
        final data =
            snapshot.data!.data() as Map<String, dynamic>;
        final String xrayUrl = data['xrayUrl'] as String;
        final String? xrayNote = data['xrayNote'] as String?;
        final Timestamp? uploadedAt = data['xrayUploadedAt'] as Timestamp?;
 
        String dateStr = '';
        if (uploadedAt != null) {
          final d = uploadedAt.toDate();
          dateStr = '${d.day}/${d.month}/${d.year}';
        }
 
        return NeonPanel(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Section title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00897B).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.image_rounded,
                        color: Color(0xFF00897B), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('X-Ray Image',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF004D40))),
                        if (dateStr.isNotEmpty)
                          Text('Uploaded on $dateStr',
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
 
              const SizedBox(height: 14),
 
              // ── X-Ray preview image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  xrayUrl,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 180,
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: const Color(0xFF00897B),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 120,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image_rounded,
                            color: Colors.grey, size: 32),
                        SizedBox(height: 6),
                        Text('Could not load image',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
 
              // ── Doctor note
              if (xrayNote != null && xrayNote.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FAF9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFB2DFDB), width: 0.8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.note_alt_rounded,
                          color: Color(0xFF00897B), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          xrayNote,
                          style: const TextStyle(
                              color: Color(0xFF004D40), fontSize: 12, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
 
              const SizedBox(height: 14),
 
              // ── Download / Save button
              SizedBox(
                width: double.infinity,
                child: _XRayDownloadButton(xrayUrl: xrayUrl),
              ),
            ],
          ),
        );
      },
    );
  }
}
 
// ─────────────────────────────────────────────────────────────────────────────
// Stateful download button — shows loading, uses http + Printing.sharePdf
// ─────────────────────────────────────────────────────────────────────────────
class _XRayDownloadButton extends StatefulWidget {
  final String xrayUrl;
  const _XRayDownloadButton({required this.xrayUrl});

  @override
  State<_XRayDownloadButton> createState() => _XRayDownloadButtonState();
}

class _XRayDownloadButtonState extends State<_XRayDownloadButton> {
  bool _loading = false;

  Future<void> _download() async {
    setState(() => _loading = true);
    try {
      final response = await http.get(Uri.parse(widget.xrayUrl));
      if (response.statusCode != 200) {
        throw Exception('Could not download (HTTP ${response.statusCode})');
      }
      final fileName =
          'XRay_${DateTime.now().millisecondsSinceEpoch}.jpg';
      // Opens native share/save sheet
      // Android → "Save to Downloads"  |  iOS → "Save to Files"
      await Printing.sharePdf(bytes: response.bodyBytes, filename: fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Share sheet opened!\n• Android: tap "Save to Downloads"\n• iOS: tap "Save to Files"',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ]),
            backgroundColor: const Color(0xFF00897B),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        elevation: 0,
      ),
      icon: _loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.download_rounded, size: 18),
      label: Text(
        _loading ? 'Downloading...' : 'Download X-Ray',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      onPressed: _loading ? null : _download,
    );
  }
}
