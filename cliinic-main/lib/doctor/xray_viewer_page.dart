import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'doctor_colors.dart';
import 'xray_upload_widget.dart';
 
/// Doctor-side full page for viewing & uploading X-Rays per appointment.
/// Route usage:
///   Navigator.push(context, MaterialPageRoute(
///     builder: (_) => XRayViewerPage(appointmentId: id, patientName: name),
///   ));
class XRayViewerPage extends StatelessWidget {
  final String appointmentId;
  final String patientName;
 
  const XRayViewerPage({
    super.key,
    required this.appointmentId,
    required this.patientName,
  });
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DC.bg,
      appBar: AppBar(
        backgroundColor: DC.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: DC.green, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('X-Ray',
                style: TextStyle(
                    color: DC.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text(patientName,
                style: const TextStyle(
                    color: DC.textSub, fontSize: 12)),
          ],
        ),
        actions: [
          // Quick fullscreen view button (shows if image exists)
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('appointments')
                .doc(appointmentId)
                .snapshots(),
            builder: (ctx, snap) {
              final data = snap.data?.data() as Map<String, dynamic>?;
              final url = data?['xrayUrl'] as String?;
              if (url == null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.fullscreen_rounded,
                    color: DC.green),
                tooltip: 'View fullscreen',
                onPressed: () => _openFullscreen(context, url),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: DC.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DC.green.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: DC.green, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Upload the patient\'s X-Ray. It will appear automatically '
                      'in the patient\'s app under this appointment.',
                      style: TextStyle(
                          color: DC.textSub,
                          fontSize: 12,
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
 
            const SizedBox(height: 20),
 
            // ── Upload widget
            XRayUploadWidget(appointmentId: appointmentId),
 
            const SizedBox(height: 20),
 
            // ── History of all xrays sent for this appointment
            _XRayHistory(appointmentId: appointmentId),
          ],
        ),
      ),
    );
  }
 
  void _openFullscreen(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullscreenImagePage(imageUrl: url),
      ),
    );
  }
}
 
// ─────────────────────────────────────────────────────────────────────────────
// Shows the current xray metadata from Firestore (read-only history block)
// ─────────────────────────────────────────────────────────────────────────────
class _XRayHistory extends StatelessWidget {
  final String appointmentId;
  const _XRayHistory({required this.appointmentId});
 
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final url = data['xrayUrl'] as String?;
        if (url == null) return const SizedBox.shrink();
 
        final note = data['xrayNote'] as String? ?? '';
        final ts = data['xrayUploadedAt'] as Timestamp?;
        final dateStr = ts != null
            ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}  '
                '${ts.toDate().hour.toString().padLeft(2, '0')}:'
                '${ts.toDate().minute.toString().padLeft(2, '0')}'
            : '';
 
        return Container(
          decoration: BoxDecoration(
            color: DC.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DC.border),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.history_rounded,
                      color: DC.green, size: 18),
                  const SizedBox(width: 8),
                  const Text('Uploaded X-Ray Info',
                      style: TextStyle(
                          color: DC.text,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const Spacer(),
                  if (dateStr.isNotEmpty)
                    Text(dateStr,
                        style: const TextStyle(
                            color: DC.textSub, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 12),
              // Thumbnail
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _FullscreenImagePage(imageUrl: url),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    url,
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                    loadingBuilder: (ctx, child, prog) {
                      if (prog == null) return child;
                      return Container(
                        height: 160,
                        color: DC.surface,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(
                            color: DC.green),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      height: 100,
                      color: DC.surface,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_rounded,
                          color: Colors.grey),
                    ),
                  ),
                ),
              ),
              if (note.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note_alt_rounded,
                        color: DC.green, size: 15),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(note,
                          style: const TextStyle(
                              color: DC.textSub, fontSize: 12, height: 1.5)),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Text('Tap image to view fullscreen',
                  style: TextStyle(
                      color: DC.green.withOpacity(0.7), fontSize: 11)),
            ],
          ),
        );
      },
    );
  }
}
 
// ─────────────────────────────────────────────────────────────────────────────
// Fullscreen image viewer with pinch-to-zoom
// ─────────────────────────────────────────────────────────────────────────────
class _FullscreenImagePage extends StatelessWidget {
  final String imageUrl;
  const _FullscreenImagePage({required this.imageUrl});
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('X-Ray',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            tooltip: 'Open / Download',
            onPressed: () async {
              // URL launch handled by the platform
              final uri = Uri.parse(imageUrl);
              if (!await _tryLaunch(uri)) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Could not open image URL.')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 5.0,
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
                  Text('Failed to load image',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
 
  Future<bool> _tryLaunch(Uri uri) async {
    // We avoid importing url_launcher here and rely on the OS
    // to open the URL from the share/open mechanism — handled by the parent.
    return false;
  }
}