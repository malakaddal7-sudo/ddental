// lib/doctor/profile_screen.dart
// FIXES:
//   1 → _saveChanges: shows SnackBar THEN pops (was popping before snackbar)
//   2 → Password dialog: uses dialogContext for Navigator.pop, outer context for SnackBar
//   3 → Delete account properly awaits all sub-collections
//   4 → Language page wired to app-level locale via ValueNotifier

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'doctor_colors.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Stream<DocumentSnapshot<Map<String, dynamic>>> get _doctorStream {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('doctors')
        .doc(uid)
        .snapshots();
  }

  Stream<int> get _totalPatientsStream {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(0);
    return FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: uid)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => d.data()['patientId'] as String? ?? '')
              .where((id) => id.isNotEmpty)
              .toSet()
              .length,
        );
  }

  void _push(BuildContext ctx, Widget page) =>
      Navigator.push(ctx, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DC.bg,
      appBar: AppBar(
        backgroundColor: DC.surface,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(color: DC.text, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, DC.green, Colors.transparent],
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _doctorStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: DC.green),
            );
          }
          final d = snap.data?.data() ?? {};
          final first = d['firstName'] as String? ?? '';
          final last = d['lastName'] as String? ?? '';
          final doctorName = 'Dr. $first $last'.trim().replaceAll(
            RegExp(r'\s+'),
            ' ',
          );
          final specialty = d['specialty'] as String? ?? '';
          final city = d['clinicName'] as String? ?? d['city'] as String? ?? '';
          final yoe =
              int.tryParse(
                (d['yearsOfExperience'] ?? d['yearsExp'] ?? '0').toString(),
              ) ??
              0;
          final rating = double.tryParse((d['rating'] ?? 0).toString()) ?? 0.0;
          final ratingStr = rating > 0 ? rating.toStringAsFixed(1) : '—';
          final experience = '${yoe}yr';

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildAvatar(doctorName, specialty, city),
                const SizedBox(height: 24),
                _buildStatsRow(ratingStr, experience),
                const SizedBox(height: 24),
                _buildSection('Account', [
                  _tile(
                    context,
                    Icons.person_outline_rounded,
                    'Personal Information',
                    DC.green,
                    () {
                      _push(
                        context,
                        _PersonalInfoPage(
                          doctorName: doctorName,
                          specialty: specialty,
                          city: city,
                        ),
                      );
                    },
                  ),
                  _tile(
                    context,
                    Icons.lock_outline_rounded,
                    'Change Password',
                    DC.info,
                    () => _showChangePasswordDialog(context),
                  ),
                  _tile(
                    context,
                    Icons.cases_outlined,
                    'My Cases',
                    DC.warning,
                    () => _push(context, const _CasesPage()),
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSection('Preferences', [
                  _tile(
                    context,
                    Icons.notifications_outlined,
                    'Notifications',
                    DC.green,
                    () => _push(context, const _NotifSettingsPage()),
                  ),
                  _tile(
                    context,
                    Icons.language_outlined,
                    'Language',
                    DC.info,
                    () => _push(context, const _LanguagePage()),
                  ),
                  _tile(
                    context,
                    Icons.schedule_outlined,
                    'Schedule & Hours',
                    DC.textSub,
                    () => _push(context, const _SchedulePage()),
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSection('Support', [
                  _tile(
                    context,
                    Icons.help_outline_rounded,
                    'Help & Support',
                    DC.green,
                    () => _push(context, const _HelpPage()),
                  ),
                  _tile(
                    context,
                    Icons.privacy_tip_outlined,
                    'Privacy Policy',
                    DC.info,
                    () => _push(context, const _PrivacyPage()),
                  ),
                  _tile(
                    context,
                    Icons.star_outline_rounded,
                    'Rate the App',
                    DC.warning,
                    () => _push(context, const _RateAppPage()),
                  ),
                ]),
                const SizedBox(height: 24),
                _buildLogout(context),
                const SizedBox(height: 12),
                _buildDeleteAccount(context),
                const SizedBox(height: 12),
                const Text(
                  'DocLine v2.0.0 · Dental Care Made Easy',
                  style: TextStyle(color: DC.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── FIX 2: Change Password — dialogContext vs outer context separated ──────
  void _showChangePasswordDialog(BuildContext outerContext) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: outerContext,
      builder: (dialogContext) {
        bool saving = false;
        return StatefulBuilder(
          builder: (dialogContext, setS) => AlertDialog(
            backgroundColor: DC.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: DC.green.withOpacity(0.4)),
            ),
            title: const Text(
              'Change Password',
              style: TextStyle(color: DC.text, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(
                  currentCtrl,
                  'Current Password',
                  Icons.lock_outline,
                  true,
                ),
                const SizedBox(height: 12),
                _dialogField(
                  newCtrl,
                  'New Password',
                  Icons.lock_reset_outlined,
                  true,
                ),
                const SizedBox(height: 12),
                _dialogField(
                  confirmCtrl,
                  'Confirm New Password',
                  Icons.lock_reset_outlined,
                  true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: DC.textSub),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DC.green,
                  foregroundColor: Colors.black,
                ),
                onPressed: saving
                    ? null
                    : () async {
                        // Validate inputs
                        if (currentCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(outerContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please enter your current password',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        if (newCtrl.text != confirmCtrl.text) {
                          ScaffoldMessenger.of(outerContext).showSnackBar(
                            const SnackBar(
                              content: Text('Passwords do not match'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        if (newCtrl.text.length < 6) {
                          ScaffoldMessenger.of(outerContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Password must be at least 6 characters',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        setS(() => saving = true);

                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null || user.email == null) {
                            throw FirebaseAuthException(
                              code: 'no-user',
                              message: 'No authenticated user found',
                            );
                          }

                          // Step 1: Re-authenticate
                          final cred = EmailAuthProvider.credential(
                            email: user.email!,
                            password: currentCtrl.text,
                          );
                          await user.reauthenticateWithCredential(cred);

                          // Step 2: Update password
                          await user.updatePassword(newCtrl.text);

                          // Step 3: Close dialog THEN show success
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                          if (outerContext.mounted) {
                            ScaffoldMessenger.of(outerContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Password updated successfully ✓',
                                ),
                                backgroundColor: DC.green,
                              ),
                            );
                          }
                        } on FirebaseAuthException catch (e) {
                          setS(() => saving = false);
                          String msg;
                          switch (e.code) {
                            case 'wrong-password':
                            case 'invalid-credential':
                              msg = 'Current password is incorrect';
                              break;
                            case 'weak-password':
                              msg = 'New password is too weak';
                              break;
                            case 'requires-recent-login':
                              msg =
                                  'Please log out and log in again before changing password';
                              break;
                            default:
                              msg = e.message ?? 'Authentication error';
                          }
                          if (outerContext.mounted) {
                            ScaffoldMessenger.of(outerContext).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } catch (e) {
                          setS(() => saving = false);
                          if (outerContext.mounted) {
                            ScaffoldMessenger.of(outerContext).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Update'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _dialogField(
    TextEditingController c,
    String label,
    IconData icon,
    bool obscure,
  ) {
    return TextField(
      controller: c,
      obscureText: obscure,
      style: const TextStyle(color: DC.text),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: DC.textSub),
        prefixIcon: Icon(icon, color: DC.green, size: 18),
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
    );
  }

  // ── FIX 3: Delete account ─────────────────────────────────────────────────
  Widget _buildDeleteAccount(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: DC.danger.withOpacity(0.12), blurRadius: 12),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          onPressed: () => _confirmDeleteAccount(context),
          icon: const Icon(Icons.delete_forever_rounded, color: DC.danger),
          label: const Text(
            'Delete Account',
            style: TextStyle(color: DC.danger, fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: DC.danger.withOpacity(0.7)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DC.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: DC.danger.withOpacity(0.5)),
        ),
        title: const Text(
          'Delete Account',
          style: TextStyle(color: DC.text, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This is permanent. All your data will be deleted and cannot be recovered.',
          style: TextStyle(color: DC.textSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: DC.textSub)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DC.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    String? pwd;
    if (context.mounted) {
      pwd = await showDialog<String>(
        context: context,
        builder: (_) {
          final c = TextEditingController();
          return AlertDialog(
            backgroundColor: DC.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Confirm Password',
              style: TextStyle(color: DC.text),
            ),
            content: TextField(
              controller: c,
              obscureText: true,
              style: const TextStyle(color: DC.text),
              decoration: InputDecoration(
                hintText: 'Enter your password',
                hintStyle: const TextStyle(color: DC.textMuted),
                filled: true,
                fillColor: DC.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: DC.green.withOpacity(0.2)),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: DC.textSub),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DC.danger,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, c.text),
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );
    }

    if (pwd == null || pwd.isEmpty) return;

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            const Center(child: CircularProgressIndicator(color: DC.green)),
      );
    }

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: pwd,
      );
      await user.reauthenticateWithCredential(cred);

      final uid = user.uid;
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      batch.delete(db.collection('doctors').doc(uid));

      final appts = await db
          .collection('appointments')
          .where('doctorId', isEqualTo: uid)
          .get();
      for (final d in appts.docs) batch.delete(d.reference);

      final doctorAppts = await db
          .collection('doctors')
          .doc(uid)
          .collection('appointments')
          .get();
      for (final d in doctorAppts.docs) batch.delete(d.reference);

      final doctorNotifs = await db
          .collection('doctors')
          .doc(uid)
          .collection('notifications')
          .get();
      for (final d in doctorNotifs.docs) batch.delete(d.reference);

      await batch.commit();
      await user.delete();

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Auth error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildAvatar(String doctorName, String specialty, String city) {
    final subtitle = [specialty, city].where((s) => s.isNotEmpty).join(' · ');
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(
                  colors: [DC.green, Color(0xFF003D3A), DC.green],
                ),
                boxShadow: [
                  BoxShadow(
                    color: DC.green.withOpacity(0.45),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: DC.greenGlow,
                  ),
                  child: const CircleAvatar(
                    backgroundColor: Colors.transparent,
                    child: Icon(
                      Icons.person_rounded,
                      size: 55,
                      color: DC.green,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: DC.green,
                shape: BoxShape.circle,
                border: Border.all(color: DC.bg, width: 2.5),
                boxShadow: [
                  BoxShadow(color: DC.green.withOpacity(0.5), blurRadius: 8),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 13,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          doctorName,
          style: const TextStyle(
            color: DC.text,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: DC.greenGlow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: DC.green.withOpacity(0.5)),
          ),
          child: Text(
            subtitle.isNotEmpty ? subtitle : 'Doctor',
            style: const TextStyle(
              color: DC.green,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(String ratingStr, String experience) {
    return _glowCard(
      child: StreamBuilder<int>(
        stream: _totalPatientsStream,
        builder: (context, snap) {
          final total = snap.data ?? 0;
          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('appointments')
                .where(
                  'doctorId',
                  isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                )
                .where('status', isEqualTo: 'completed')
                .get(),
            builder: (context, caseSnap) {
              final cases = caseSnap.data?.docs.length ?? 0;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat(total.toString(), 'Patients'),
                  _divider(),
                  _stat(cases.toString(), 'Cases'),
                  _divider(),
                  _stat(ratingStr, 'Rating'),
                  _divider(),
                  _stat(experience, 'Experience'),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _stat(String v, String l) => Column(
    children: [
      Text(
        v,
        style: const TextStyle(
          color: DC.text,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      const SizedBox(height: 2),
      Text(l, style: const TextStyle(color: DC.textSub, fontSize: 10)),
    ],
  );

  Widget _divider() => Container(width: 1, height: 30, color: DC.border);

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
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
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: DC.green,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
        _glowCard(child: Column(children: items)),
      ],
    );
  }

  Widget _glowCard({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: DC.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: DC.green.withOpacity(0.25), width: 1.2),
      boxShadow: [
        BoxShadow(
          color: DC.green.withOpacity(0.08),
          blurRadius: 16,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );

  Widget _tile(
    BuildContext ctx,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          title: Text(
            label,
            style: const TextStyle(color: DC.text, fontSize: 14),
          ),
          trailing: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: DC.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: DC.green,
              size: 11,
            ),
          ),
          onTap: onTap,
        ),
        Divider(color: DC.green.withOpacity(0.08), height: 1, indent: 52),
      ],
    );
  }

  Widget _buildLogout(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: DC.danger.withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: DC.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: DC.danger.withOpacity(0.5)),
              ),
              title: const Text('Log Out', style: TextStyle(color: DC.text)),
              content: const Text(
                'Are you sure you want to log out?',
                style: TextStyle(color: DC.textSub),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: DC.textSub),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DC.danger,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                      );
                    }
                  },
                  child: const Text('Log Out'),
                ),
              ],
            ),
          ),
          icon: const Icon(Icons.logout_rounded, color: DC.danger),
          label: const Text(
            'Log Out',
            style: TextStyle(color: DC.danger, fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: DC.danger.withOpacity(0.7)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}

// ── PERSONAL INFO PAGE ────────────────────────────────────────────────────────
class _PersonalInfoPage extends StatefulWidget {
  final String doctorName;
  final String specialty;
  final String city;
  const _PersonalInfoPage({
    this.doctorName = '',
    this.specialty = '',
    this.city = '',
  });
  @override
  State<_PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<_PersonalInfoPage> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _clinic;
  late final TextEditingController _specialty;
  late final TextEditingController _experience;
  bool _editing = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _firstName = TextEditingController();
    _lastName = TextEditingController();
    _email = TextEditingController();
    _phone = TextEditingController();
    _clinic = TextEditingController(text: widget.city);
    _specialty = TextEditingController(text: widget.specialty);
    _experience = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _lastName,
      _email,
      _phone,
      _clinic,
      _specialty,
      _experience,
    ])
      c.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance
            .collection('doctors')
            .doc(uid)
            .get();
        if (doc.exists && mounted) {
          final d = doc.data()!;
          _firstName.text = d['firstName'] as String? ?? '';
          _lastName.text = d['lastName'] as String? ?? '';
          _email.text = d['email'] as String? ?? '';
          _phone.text = d['phone'] as String? ?? '';
          _clinic.text = (d['clinicName'] ?? d['city'] ?? '') as String;
          _specialty.text = d['specialty'] as String? ?? '';
          _experience.text = (d['yearsOfExperience'] ?? d['yearsExp'] ?? '')
              .toString();
        }
      }
    } catch (e) {
      debugPrint('Error loading doctor data: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  // FIX 1: Show SnackBar BEFORE popping so it's visible
  Future<void> _saveChanges() async {
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not logged in');

      await FirebaseFirestore.instance.collection('doctors').doc(uid).set({
        'firstName': _firstName.text.trim(),
        'lastName': _lastName.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'clinicName': _clinic.text.trim(),
        'specialty': _specialty.text.trim(),
        'yearsOfExperience': _experience.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _editing = false;
          _saving = false;
        });
        // FIX: Show snackbar first, then pop after a short delay
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully ✓'),
            backgroundColor: DC.green,
            duration: Duration(seconds: 2),
          ),
        );
        // Small delay so the snackbar is visible before screen closes
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DC.bg,
      appBar: _appBar(
        context,
        'Personal Information',
        action: IconButton(
          icon: Icon(
            _editing ? Icons.close_rounded : Icons.edit_rounded,
            color: DC.green,
          ),
          onPressed: () => setState(() => _editing = !_editing),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: DC.green))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _field(
                  _firstName,
                  'First Name',
                  Icons.person_outline,
                  _editing,
                ),
                const SizedBox(height: 14),
                _field(_lastName, 'Last Name', Icons.person_outline, _editing),
                const SizedBox(height: 14),
                _field(
                  _specialty,
                  'Specialty',
                  Icons.medical_services_outlined,
                  _editing,
                ),
                const SizedBox(height: 14),
                _field(
                  _email,
                  'Email',
                  Icons.email_outlined,
                  _editing,
                  type: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                _field(
                  _phone,
                  'Phone',
                  Icons.phone_outlined,
                  _editing,
                  type: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                _field(
                  _clinic,
                  'Clinic / City',
                  Icons.local_hospital_outlined,
                  _editing,
                ),
                const SizedBox(height: 14),
                _field(
                  _experience,
                  'Years of Experience',
                  Icons.workspace_premium_outlined,
                  _editing,
                  type: TextInputType.number,
                ),
                if (_editing) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _saveChanges,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        _saving ? 'Saving...' : 'Save Changes',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DC.green,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon,
    bool enabled, {
    TextInputType? type,
  }) {
    return TextField(
      controller: c,
      enabled: enabled,
      keyboardType: type,
      style: const TextStyle(color: DC.text),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: DC.textSub),
        prefixIcon: Icon(icon, color: DC.green, size: 18),
        filled: true,
        fillColor: DC.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DC.green.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DC.green.withOpacity(0.25)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DC.borderFaint),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DC.green, width: 1.5),
        ),
      ),
    );
  }
}

// ── LANGUAGE PAGE ─────────────────────────────────────────────────────────────
final appLocaleNotifier = ValueNotifier<Locale>(const Locale('en'));

class _LanguagePage extends StatefulWidget {
  const _LanguagePage();
  @override
  State<_LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<_LanguagePage> {
  static const _langs = [
    {'label': 'English', 'locale': 'en', 'flag': '🇬🇧'},
    {'label': 'Français', 'locale': 'fr', 'flag': '🇫🇷'},
    {'label': 'العربية', 'locale': 'ar', 'flag': '🇩🇿'},
  ];

  String _selected = appLocaleNotifier.value.languageCode;

  void _pick(String code) {
    setState(() => _selected = code);
    appLocaleNotifier.value = Locale(code);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore.instance.collection('doctors').doc(uid).set({
        'language': code,
      }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DC.bg,
      appBar: _appBar(context, 'Language'),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _langs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final l = _langs[i];
          final sel = _selected == l['locale'];
          return GestureDetector(
            onTap: () => _pick(l['locale']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: sel ? DC.greenGlow : DC.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: sel ? DC.green : DC.green.withOpacity(0.15),
                  width: sel ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(l['flag']!, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Text(
                    l['label']!,
                    style: TextStyle(
                      color: sel ? DC.green : DC.text,
                      fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  if (sel)
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: DC.green,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.black,
                        size: 14,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── STUB PAGES ────────────────────────────────────────────────────────────────
class _NotifSettingsPage extends StatelessWidget {
  const _NotifSettingsPage();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: DC.bg,
    appBar: _appBar(context, 'Notification Settings'),
    body: const Center(
      child: Text('Notification settings', style: TextStyle(color: DC.textSub)),
    ),
  );
}

class _SchedulePage extends StatefulWidget {
  const _SchedulePage();
  @override
  State<_SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<_SchedulePage> {
  final Map<String, Map<String, dynamic>> _schedule = {
    'Monday': {'open': true, 'from': '08:00', 'to': '17:00'},
    'Tuesday': {'open': true, 'from': '08:00', 'to': '17:00'},
    'Wednesday': {'open': true, 'from': '08:00', 'to': '13:00'},
    'Thursday': {'open': true, 'from': '08:00', 'to': '17:00'},
    'Friday': {'open': false, 'from': '08:00', 'to': '12:00'},
    'Saturday': {'open': true, 'from': '09:00', 'to': '13:00'},
    'Sunday': {'open': false, 'from': '09:00', 'to': '12:00'},
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DC.bg,
      appBar: _appBar(context, 'Schedule & Hours'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ..._schedule.entries.map((e) => _dayRow(e.key, e.value)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () async {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid == null) return;
                await FirebaseFirestore.instance
                    .collection('doctors')
                    .doc(uid)
                    .set({'schedule': _schedule}, SetOptions(merge: true));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Schedule saved ✓'),
                      backgroundColor: DC.green,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text(
                'Save Schedule',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: DC.green,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayRow(String day, Map<String, dynamic> info) {
    final isOpen = info['open'] as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: DC.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOpen ? DC.green.withOpacity(0.3) : DC.border,
          width: isOpen ? 1.2 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              day,
              style: TextStyle(
                color: isOpen ? DC.text : DC.textMuted,
                fontWeight: isOpen ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
          Switch(
            value: isOpen,
            onChanged: (v) => setState(() => _schedule[day]!['open'] = v),
            activeColor: DC.green,
            inactiveThumbColor: DC.textMuted,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isOpen ? DC.greenGlow : DC.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isOpen ? DC.green.withOpacity(0.3) : DC.border,
              ),
            ),
            child: Text(
              isOpen ? '${info['from']} – ${info['to']}' : 'Closed',
              style: TextStyle(
                color: isOpen ? DC.green : DC.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CasesPage extends StatelessWidget {
  const _CasesPage();
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: DC.bg,
      appBar: _appBar(context, 'My Cases'),
      body: uid == null
          ? const Center(
              child: Text('Not logged in', style: TextStyle(color: DC.textSub)),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('doctorId', isEqualTo: uid)
                  .where('status', isEqualTo: 'completed')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: DC.green),
                  );
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No completed cases yet',
                      style: TextStyle(color: DC.textSub),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final ts = d['date'] as Timestamp?;
                    final date = ts != null
                        ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
                        : '—';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: DC.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: DC.green.withOpacity(0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d['service'] ?? 'Appointment',
                            style: const TextStyle(
                              color: DC.text,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            d['patientName'] ?? 'Patient',
                            style: const TextStyle(
                              color: DC.textSub,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            date,
                            style: const TextStyle(
                              color: DC.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _HelpPage extends StatelessWidget {
  const _HelpPage();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: DC.bg,
    appBar: _appBar(context, 'Help & Support'),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DC.greenGlow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DC.green.withOpacity(0.4)),
          ),
          child: const Row(
            children: [
              Icon(Icons.support_agent_rounded, color: DC.green, size: 28),
              SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '24/7 Support',
                    style: TextStyle(
                      color: DC.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'support@docline.dz',
                    style: TextStyle(color: DC.green, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PrivacyPage extends StatelessWidget {
  const _PrivacyPage();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: DC.bg,
    appBar: _appBar(context, 'Privacy Policy'),
    body: const SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Text(
        'DocLine Dental Clinic Privacy Policy\n\nLast updated: April 2026\n\n'
        '1. DATA COLLECTION\nWe collect personal health information to provide dental care services.\n\n'
        '2. DATA USAGE\nYour data is used solely to manage patient records and appointments.\n\n'
        '3. DATA SHARING\nWe do not share data without explicit consent.\n\n'
        '4. DATA RETENTION\nRecords are retained for a minimum of 10 years.\n\n'
        '5. YOUR RIGHTS\nYou may access, correct, or request deletion of your data.',
        style: TextStyle(color: DC.textSub, height: 1.7, fontSize: 13),
      ),
    ),
  );
}

class _RateAppPage extends StatefulWidget {
  const _RateAppPage();
  @override
  State<_RateAppPage> createState() => _RateAppPageState();
}

class _RateAppPageState extends State<_RateAppPage> {
  int _stars = 0;
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DC.bg,
      appBar: _appBar(context, 'Rate the App'),
      body: _submitted
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: DC.green,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Thank You!',
                    style: TextStyle(
                      color: DC.text,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DC.green,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back'),
                  ),
                ],
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Rate DocLine',
                    style: TextStyle(
                      color: DC.text,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return GestureDetector(
                        onTap: () => setState(() => _stars = i + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            i < _stars
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: i < _stars ? DC.warning : DC.textMuted,
                            size: 42,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _stars == 0
                        ? null
                        : () => setState(() => _submitted = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DC.green,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: DC.border,
                    ),
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
    );
  }
}

PreferredSizeWidget _appBar(
  BuildContext context,
  String title, {
  Widget? action,
}) {
  return AppBar(
    backgroundColor: DC.surface,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(
        Icons.arrow_back_ios_new_rounded,
        color: DC.text,
        size: 18,
      ),
      onPressed: () => Navigator.pop(context),
    ),
    title: Text(
      title,
      style: const TextStyle(color: DC.text, fontWeight: FontWeight.bold),
    ),
    actions: action != null ? [action] : null,
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(
        height: 1,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, DC.green, Colors.transparent],
          ),
        ),
      ),
    ),
  );
}
