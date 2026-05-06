// lib/patient/account_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import '../theme/app_colors.dart';
import '../widgets/neon_panel.dart';
import '../nav/app_routes.dart';
import 'profile/notifications_settings_page.dart';
import 'profile/medical_history_page.dart';
import 'profile/language_page.dart';
import 'profile/personal_info_page.dart';
import 'profile/credentials_page.dart';
import 'profile/medical_records_page.dart';
import 'profile/xray_images_page.dart';
import 'profile/export_pdf_page.dart';
import 'profile/privacy_policy_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String _displayName = '';
  String _email = '';
  StreamSubscription<DocumentSnapshot>? _sub;

  @override
  void initState() {
    super.initState();
    _listenToUserData();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _listenToUserData() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _sub = FirebaseFirestore.instance
        .collection('patients') // reads from patients collection
        .doc(uid)
        .snapshots()
        .listen((doc) {
          if (doc.exists && mounted) {
            final data = doc.data()!;
            final first = data['firstName'] ?? '';
            final last = data['lastName'] ?? '';
            setState(() {
              _displayName = '$first $last'.trim().toUpperCase();
              _email = data['email'] ?? '';
            });
          }
        });
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This will permanently delete your account and all your data. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final uid = user.uid;
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      // Delete patients document
      batch.delete(db.collection('patients').doc(uid));

      // Delete users document
      batch.delete(db.collection('users').doc(uid));

      // Delete global appointments
      final appts = await db
          .collection('appointments')
          .where('patientId', isEqualTo: uid)
          .get();
      for (final d in appts.docs) {
        batch.delete(d.reference);
      }

      // Delete patient sub-collections
      final patientAppts = await db
          .collection('patients')
          .doc(uid)
          .collection('appointments')
          .get();
      for (final d in patientAppts.docs) {
        batch.delete(d.reference);
      }

      final notifs = await db
          .collection('patients')
          .doc(uid)
          .collection('notifications')
          .get();
      for (final d in notifs.docs) {
        batch.delete(d.reference);
      }

      final xrays = await db
          .collection('patients')
          .doc(uid)
          .collection('xrays')
          .get();
      for (final d in xrays.docs) {
        batch.delete(d.reference);
      }

      await batch.commit();
      await user.delete();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          AppRoutes.fadeSlide(LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ── Profile Card ──────────────────────────────────────────
                NeonPanel(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: AppColors.panel2,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.neonCyan.withOpacity(0.65),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 50,
                              color: AppColors.neonCyan,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.neonTeal,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 14,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _displayName.isNotEmpty ? _displayName : 'PATIENT',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        _email,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.panel2,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.neonCyan.withOpacity(0.35),
                          ),
                        ),
                        child: const Text(
                          'Patient',
                          style: TextStyle(
                            color: AppColors.neonCyan,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Profile Section ───────────────────────────────────────
                _buildSection('Profile', [
                  _buildMenuItem(
                    context,
                    Icons.person_rounded,
                    'Personal Info',
                    () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PersonalInfoPage(),
                        ),
                      );
                      // Stream handles refresh automatically
                    },
                  ),
                  _buildMenuItem(
                    context,
                    Icons.lock_rounded,
                    'Credentials',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CredentialsPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    Icons.school_rounded,
                    'Medical History',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MedicalHistoryPage()),
                      );
                    },
                  ),
                ]),

                const SizedBox(height: 16),

                // ── Health Section ────────────────────────────────────────
                _buildSection('Health', [
                  _buildMenuItem(
                    context,
                    Icons.folder_rounded,
                    'Medical Records',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MedicalRecordsPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    Icons.image_rounded,
                    'X-Ray Images',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const XRayImagesPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    Icons.download_rounded,
                    'Export PDF',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ExportPdfPage(),
                        ),
                      );
                    },
                  ),
                ]),

                const SizedBox(height: 16),

                // ── Settings Section ──────────────────────────────────────
                _buildSection('Settings', [
                  _buildMenuItem(
                    context,
                    Icons.notifications_rounded,
                    'Notification Settings',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NotificationSettingsPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    Icons.language_rounded,
                    'Language',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => LanguagePage()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    Icons.privacy_tip_rounded,
                    'Privacy Policy',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyPage(),
                        ),
                      );
                    },
                  ),
                ]),

                const SizedBox(height: 16),

                // ── Logout / Delete ───────────────────────────────────────
                Container(
                  decoration: AppColors.cardDecoration,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            color: Colors.red,
                          ),
                        ),
                        title: const Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Colors.red,
                        ),
                        onTap: () async {
                          await FirebaseAuth.instance.signOut();
                          if (mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              AppRoutes.fadeSlide(LoginPage()),
                              (route) => false,
                            );
                          }
                        },
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person_remove_rounded,
                            color: Colors.red,
                          ),
                        ),
                        title: const Text(
                          'Delete Account',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: const Text(
                          'Permanently delete your account',
                          style: TextStyle(color: Colors.red, fontSize: 11),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Colors.red,
                        ),
                        onTap: () => _confirmDeleteAccount(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const Text(
                  'DocLine v1.0.0',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
        ),
        Container(
          decoration: AppColors.cardDecoration,
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.neonCyan.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.neonCyan, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.text,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: AppColors.neonCyan,
      ),
      onTap: onTap,
    );
  }
}
