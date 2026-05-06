import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/neon_panel.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  int _expandedIndex = -1;

  final List<Map<String, dynamic>> _sections = [
    {
      'icon': Icons.info_rounded,
      'color': AppColors.neonCyan,
      'title': '1. Information We Collect',
      'content':
          'We collect information you provide directly, including your name, date of birth, contact details, and medical data. We also collect usage data such as app activity and device information to improve our services.',
    },
    {
      'icon': Icons.medical_services_rounded,
      'color': Colors.pinkAccent,
      'title': '2. Medical Data',
      'content':
          'Your medical records, X-ray images, prescriptions, and health history are stored securely and encrypted. This data is only accessible by you and authorized healthcare providers you explicitly choose to share it with.',
    },
    {
      'icon': Icons.share_rounded,
      'color': Colors.orange,
      'title': '3. How We Use Your Data',
      'content':
          'Your data is used to provide personalized healthcare services, facilitate appointments, generate medical reports, and improve the DocLine platform. We do not sell your data to third parties.',
    },
    {
      'icon': Icons.shield_rounded,
      'color': AppColors.neonTeal,
      'title': '4. Data Security',
      'content':
          'We use industry-standard encryption (AES-256) to protect your data at rest and in transit. Our servers are hosted in secure, ISO-certified data centers with 24/7 monitoring and regular security audits.',
    },
    {
      'icon': Icons.people_rounded,
      'color': Colors.purple,
      'title': '5. Sharing with Third Parties',
      'content':
          'We only share your information with healthcare providers you authorize, and with service partners necessary to operate DocLine. All partners are bound by strict confidentiality agreements.',
    },
    {
      'icon': Icons.manage_accounts_rounded,
      'color': Colors.amber,
      'title': '6. Your Rights',
      'content':
          'You have the right to access, correct, or delete your personal data at any time. You may also request a copy of your data in portable format or withdraw consent for specific processing activities.',
    },
    {
      'icon': Icons.cookie_rounded,
      'color': Colors.teal,
      'title': '7. Cookies & Tracking',
      'content':
          'DocLine uses cookies and similar technologies to enhance your experience, remember preferences, and analyze usage patterns. You can manage cookie preferences through your device settings.',
    },
    {
      'icon': Icons.child_care_rounded,
      'color': Colors.lightBlue,
      'title': '8. Minors',
      'content':
          'DocLine is not intended for users under the age of 16. If you are a minor, a parent or legal guardian must create and manage your account.',
    },
    {
      'icon': Icons.update_rounded,
      'color': AppColors.neonCyan,
      'title': '9. Policy Updates',
      'content':
          'We may update this Privacy Policy from time to time. We will notify you of significant changes via email or in-app notification.',
    },
    {
      'icon': Icons.contact_mail_rounded,
      'color': AppColors.neonTeal,
      'title': '10. Contact Us',
      'content':
          'If you have questions about this Privacy Policy, please contact our Data Protection Officer at privacy@docline.dz or write to us at DocLine, Sétif, Algeria.',
    },
  ];

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
                      _buildBanner(),
                      const SizedBox(height: 20),
                      Row(
                        children: const [
                          Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.textMuted),
                          SizedBox(width: 6),
                          Text('Last updated: March 15, 2025',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          Spacer(),
                          Text('Version 1.2', style: TextStyle(color: AppColors.neonCyan, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildQuickSummary(),
                      const SizedBox(height: 24),
                      const Text('Full Policy',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.neonTeal,
                              letterSpacing: 1.1)),
                      const SizedBox(height: 10),
                      ...List.generate(_sections.length, (i) => _buildSection(i)),
                      const SizedBox(height: 24),
                      NeonPanel(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: const [
                            Icon(Icons.verified_rounded, color: AppColors.neonTeal, size: 24),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'By using DocLine, you agree to this Privacy Policy and our Terms of Service.',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.neonCyan),
                                foregroundColor: AppColors.neonCyan,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.download_rounded, size: 16),
                              label: const Text('Download'),
                              onPressed: () {},
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: AppColors.accentGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.share_rounded, size: 16, color: Colors.white),
                                label: const Text('Share', style: TextStyle(color: Colors.white)),
                                onPressed: () {},
                              ),
                            ),
                          ),
                        ],
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
          const Text('Privacy Policy',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.neonCyan.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.privacy_tip_rounded, color: AppColors.neonCyan, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColors.panel,
        border: Border.all(color: AppColors.neonCyan.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.neonCyan.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.shield_rounded, color: AppColors.neonCyan, size: 32),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Privacy Matters',
                    style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 4),
                Text(
                    'DocLine is committed to protecting your personal and medical data with the highest standards of security.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Summary',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.neonTeal, letterSpacing: 1.1)),
        const SizedBox(height: 10),
        NeonPanel(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _summaryRow(Icons.lock_rounded, AppColors.neonCyan, 'Data is encrypted end-to-end'),
              _summaryRow(Icons.block_rounded, Colors.red, 'We never sell your data'),
              _summaryRow(Icons.manage_accounts_rounded, AppColors.neonTeal, 'You control your data'),
              _summaryRow(Icons.notifications_rounded, Colors.orange, 'You are notified of any changes'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: AppColors.text, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSection(int index) {
    final section = _sections[index];
    final isExpanded = _expandedIndex == index;
    final color = section['color'] as Color;

    return GestureDetector(
      onTap: () => setState(() => _expandedIndex = isExpanded ? -1 : index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isExpanded ? color.withOpacity(0.4) : AppColors.stroke,
            width: isExpanded ? 1.2 : 1,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(section['icon'] as IconData, color: color, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(section['title'] as String,
                        style: const TextStyle(
                            color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  children: [
                    Divider(color: AppColors.stroke, height: 1),
                    const SizedBox(height: 12),
                    Text(section['content'] as String,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 13, height: 1.6)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
