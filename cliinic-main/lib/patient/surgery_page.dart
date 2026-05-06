import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/neon_panel.dart';
import '../widgets/neon_button.dart';

class SurgeryPage extends StatelessWidget {
  const SurgeryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppBar(context),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NeonPanel(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Oral Surgery',
                                      style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  const Text('Expert Surgical\nProcedures',
                                      style: TextStyle(
                                          color: AppColors.text,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: 160,
                                    child: NeonButton(
                                      label: 'Book Now',
                                      icon: Icons.calendar_today_rounded,
                                      onPressed: () {},
                                      height: 44,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Text('🔬', style: TextStyle(fontSize: 52)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Procedures Available',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
                      const SizedBox(height: 16),
                      ..._procedures([
                        ('Tooth Extraction', Icons.medical_services_rounded),
                        ('Wisdom Tooth Removal', Icons.healing_rounded),
                        ('Dental Implants', Icons.add_circle_outline_rounded),
                        ('Bone Grafting', Icons.biotech_rounded),
                      ]),
                      const SizedBox(height: 24),
                      const Text('What to Expect',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
                      const SizedBox(height: 16),
                      ..._steps([
                        'Pre-surgery consultation & X-rays',
                        'Local anaesthesia administered',
                        'Surgical procedure performed',
                        'Post-op care instructions given',
                      ]),
                      const SizedBox(height: 24),
                      const Text('Our Surgeon',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
                      const SizedBox(height: 16),
                      _buildDoctorCard('Dr. Karim Hadj', 'Oral Surgeon', '⭐ 4.7'),
                    ],
                  ),
                ),
              ],
            ),
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
          const Text('Surgery',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text)),
        ],
      ),
    );
  }

  List<Widget> _procedures(List<(String, IconData)> items) {
    return items.map((item) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: NeonPanel(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.neonCyan.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.$2, color: AppColors.neonCyan, size: 20),
              ),
              const SizedBox(width: 12),
              Text(item.$1,
                  style: const TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w500)),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded, color: AppColors.neonCyan, size: 20),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _steps(List<String> items) {
    return items.asMap().entries.map((e) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.neonCyan.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.neonCyan.withOpacity(0.4)),
              ),
              child: Center(
                child: Text('${e.key + 1}',
                    style: const TextStyle(
                        color: AppColors.neonCyan, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(e.value, style: const TextStyle(color: AppColors.text, fontSize: 14)),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildDoctorCard(String name, String specialty, String rating) {
    return NeonPanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.neonCyan.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: AppColors.neonCyan),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.text)),
                Text(specialty,
                    style: const TextStyle(color: AppColors.neonTeal, fontSize: 13)),
              ],
            ),
          ),
          Text(rating, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}