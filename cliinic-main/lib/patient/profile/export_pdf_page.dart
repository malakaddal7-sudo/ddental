import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/neon_panel.dart';

class ExportPdfPage extends StatefulWidget {
  const ExportPdfPage({super.key});

  @override
  State<ExportPdfPage> createState() => _ExportPdfPageState();
}

class _ExportPdfPageState extends State<ExportPdfPage> {
  bool _includePersonalInfo = true;
  bool _includeMedicalHistory = true;
  bool _includeMedicalRecords = true;
  bool _includeXRayImages = false;
  bool _includePrescriptions = true;
  bool _includeLabResults = true;

  int _selectedFormat = 0;
  int _selectedLanguage = 0;
  bool _isExporting = false;
  double _exportProgress = 0;

  final List<String> _formats = ['PDF', 'Word (.docx)', 'HTML'];
  final List<String> _languages = ['French', 'Arabic', 'English'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPreviewCard(),
                      const SizedBox(height: 24),
                      _sectionLabel('Select Content to Include'),
                      const SizedBox(height: 10),
                      NeonPanel(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Column(
                          children: [
                            _toggleItem(Icons.person_rounded, 'Personal Information',
                                'Name, DOB, contact details', AppColors.neonCyan,
                                _includePersonalInfo, (v) => setState(() => _includePersonalInfo = v)),
                            _divider(),
                            _toggleItem(Icons.history_rounded, 'Medical History',
                                'Past conditions, surgeries, allergies', Colors.purple,
                                _includeMedicalHistory, (v) => setState(() => _includeMedicalHistory = v)),
                            _divider(),
                            _toggleItem(Icons.folder_rounded, 'Medical Records',
                                'Reports and consultation notes', AppColors.neonTeal,
                                _includeMedicalRecords, (v) => setState(() => _includeMedicalRecords = v)),
                            _divider(),
                            _toggleItem(Icons.image_rounded, 'X-Ray Images',
                                'Radiographic images (increases size)', Colors.orange,
                                _includeXRayImages, (v) => setState(() => _includeXRayImages = v)),
                            _divider(),
                            _toggleItem(Icons.medication_rounded, 'Prescriptions',
                                'Current and past medications', Colors.pinkAccent,
                                _includePrescriptions, (v) => setState(() => _includePrescriptions = v)),
                            _divider(),
                            _toggleItem(Icons.science_rounded, 'Lab Results',
                                'Blood tests, analyses', Colors.amber,
                                _includeLabResults, (v) => setState(() => _includeLabResults = v)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _sectionLabel('Export Format'),
                      const SizedBox(height: 10),
                      NeonPanel(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: List.generate(_formats.length, (i) => Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedFormat = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: EdgeInsets.only(right: i < _formats.length - 1 ? 8 : 0),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: _selectedFormat == i ? AppColors.accentGradient : null,
                                  color: _selectedFormat == i ? null : AppColors.panel2,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _selectedFormat == i ? Colors.transparent : AppColors.stroke,
                                  ),
                                ),
                                child: Text(_formats[i],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _selectedFormat == i ? Colors.white : AppColors.textMuted,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    )),
                              ),
                            ),
                          )),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _sectionLabel('Document Language'),
                      const SizedBox(height: 10),
                      NeonPanel(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: List.generate(_languages.length, (i) => Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedLanguage = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: EdgeInsets.only(right: i < _languages.length - 1 ? 8 : 0),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: _selectedLanguage == i ? AppColors.accentGradient : null,
                                  color: _selectedLanguage == i ? null : AppColors.panel2,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _selectedLanguage == i ? Colors.transparent : AppColors.stroke,
                                  ),
                                ),
                                child: Text(_languages[i],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _selectedLanguage == i ? Colors.white : AppColors.textMuted,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    )),
                              ),
                            ),
                          )),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildEstimatedSize(),
                      const SizedBox(height: 24),
                      if (_isExporting)
                        NeonPanel(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Text('Generating your document...',
                                  style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 14),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: _exportProgress,
                                  backgroundColor: AppColors.panel2,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neonTeal),
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('${(_exportProgress * 100).toInt()}%',
                                  style: const TextStyle(
                                      color: AppColors.neonCyan, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AppColors.accentGradient,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                    color: AppColors.neonTeal.withOpacity(0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4)),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: const Icon(Icons.download_rounded, color: Colors.white),
                              label: const Text('Export Document',
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              onPressed: _startExport,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.neonCyan),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          const Text('Export Document',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text)),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.neonCyan.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.panel2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.neonCyan.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 28),
                const SizedBox(height: 4),
                Text(_formats[_selectedFormat].split(' ').first,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Medical Report — ADDAL MERIEM',
                    style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text('DocLine · ${now.day}/${now.month}/${now.year}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (_includePersonalInfo) _miniChip('Personal'),
                    if (_includeMedicalHistory) _miniChip('History'),
                    if (_includeMedicalRecords) _miniChip('Records'),
                    if (_includeXRayImages) _miniChip('X-Ray'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.neonCyan.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.neonCyan.withOpacity(0.3)),
      ),
      child: Text(label,
          style: const TextStyle(color: AppColors.neonCyan, fontSize: 9, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildEstimatedSize() {
    final bools = [_includePersonalInfo, _includeMedicalHistory, _includeMedicalRecords, _includePrescriptions, _includeLabResults];
    final sections = bools.where((v) => v).length;
    final size = sections * 0.4 + (_includeXRayImages ? 4.5 : 0);
    return NeonPanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.storage_rounded, color: AppColors.neonCyan, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Estimated File Size',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              Text('~ ${size.toStringAsFixed(1)} MB',
                  style: const TextStyle(
                      color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Sections', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              Text('$sections selected',
                  style: const TextStyle(
                      color: AppColors.neonTeal, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(label,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.neonTeal, letterSpacing: 1.1));

  Widget _divider() => Divider(color: AppColors.stroke, height: 1, thickness: 1);

  Widget _toggleItem(IconData icon, String title, String subtitle, Color color,
      bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      activeColor: AppColors.neonCyan,
      onChanged: onChanged,
      title: Text(title,
          style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 13)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Future<void> _startExport() async {
    setState(() {
      _isExporting = true;
      _exportProgress = 0;
    });
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) setState(() => _exportProgress = i / 10);
    }
    if (mounted) {
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.neonTeal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Document exported successfully!', style: TextStyle(color: Colors.white)),
          ]),
        ),
      );
    }
  }
}
