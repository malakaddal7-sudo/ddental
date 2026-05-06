// lib/patient/profile/personal_info_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  bool _loading = true;
  bool _saving = false;
  bool _editing = false;

  late TextEditingController _firstName;
  late TextEditingController _lastName;
  late TextEditingController _email;
  late TextEditingController _phone;
  late TextEditingController _age;
  late TextEditingController _address;

  @override
  void initState() {
    super.initState();
    _firstName = TextEditingController();
    _lastName = TextEditingController();
    _email = TextEditingController();
    _phone = TextEditingController();
    _age = TextEditingController();
    _address = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _age.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() => _loading = false);
        return;
      }
      final doc = await FirebaseFirestore.instance
          .collection('patients') // reads from patients collection
          .doc(uid)
          .get();
      if (doc.exists && mounted) {
        final d = doc.data()!;
        _firstName.text = d['firstName'] as String? ?? '';
        _lastName.text = d['lastName'] as String? ?? '';
        _email.text =
            (d['email'] as String?) ??
            FirebaseAuth.instance.currentUser?.email ??
            '';
        _phone.text = (d['phone'] ?? d['phoneNumber'] ?? '') as String;
        _age.text = (d['age'] ?? '').toString();
        _address.text = d['address'] as String? ?? '';
      }
    } catch (e) {
      debugPrint('PersonalInfoPage load error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Saves to both patients/{uid} and users/{uid} so both collections stay in sync.
  Future<void> _saveChanges() async {
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not logged in');

      final data = {
        'firstName': _firstName.text.trim(),
        'lastName': _lastName.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'age': _age.text.trim(),
        'address': _address.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      // Write to patients/{uid} — primary source for PersonalInfoPage
      batch.set(
        db.collection('patients').doc(uid),
        data,
        SetOptions(merge: true),
      );

      // Write to users/{uid} — keeps it in sync for any other readers
      batch.set(db.collection('users').doc(uid), data, SetOptions(merge: true));

      await batch.commit();

      if (mounted) {
        setState(() => _editing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully ✓'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  /// Re-authenticates then calls updatePassword so the new password
  /// takes effect immediately and persists for the next login.
  void _showChangePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool saving = false;
    bool showCurrent = false;
    bool showNew = false;
    bool showConfirm = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.neonCyan.withOpacity(0.4)),
          ),
          title: const Text(
            'Change Password',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Current password
              TextField(
                controller: currentCtrl,
                obscureText: !showCurrent,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showCurrent
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: Colors.white38,
                    ),
                    onPressed: () => setS(() => showCurrent = !showCurrent),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // New password
              TextField(
                controller: newCtrl,
                obscureText: !showNew,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showNew
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: Colors.white38,
                    ),
                    onPressed: () => setS(() => showNew = !showNew),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Confirm new password
              TextField(
                controller: confirmCtrl,
                obscureText: !showConfirm,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showConfirm
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: Colors.white38,
                    ),
                    onPressed: () => setS(() => showConfirm = !showConfirm),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonCyan,
                foregroundColor: Colors.black,
              ),
              onPressed: saving
                  ? null
                  : () async {
                      // Validation
                      if (newCtrl.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Password must be at least 6 characters',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      if (newCtrl.text != confirmCtrl.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Passwords do not match'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      setS(() => saving = true);
                      try {
                        final user = FirebaseAuth.instance.currentUser!;
                        // Re-authenticate first — required by Firebase before
                        // sensitive operations like password change.
                        final cred = EmailAuthProvider.credential(
                          email: user.email!,
                          password: currentCtrl.text,
                        );
                        await user.reauthenticateWithCredential(cred);
                        // Update password in Firebase Auth — persists across
                        // sessions so next login must use this new password.
                        await user.updatePassword(newCtrl.text);

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password updated successfully ✓'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } on FirebaseAuthException catch (e) {
                        String message;
                        switch (e.code) {
                          case 'wrong-password':
                            message = 'Current password is incorrect.';
                            break;
                          case 'weak-password':
                            message = 'New password is too weak.';
                            break;
                          case 'requires-recent-login':
                            message =
                                'Please log out and log back in before changing your password.';
                            break;
                          default:
                            message = e.message ?? 'Authentication error.';
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(message),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        setS(() => saving = false);
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
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This action is permanent and cannot be undone.\n'
          'All your data, appointments, and records will be deleted.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete Forever',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    // Ask for password to re-authenticate
    String? password;
    if (mounted) {
      password = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final ctrl = TextEditingController();
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Confirm Password',
              style: TextStyle(color: Colors.white),
            ),
            content: TextField(
              controller: ctrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter your current password',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, ctrl.text),
                child: const Text(
                  'Confirm',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );
    }

    if (password == null || password.isEmpty) return;

    // Show loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: AppColors.neonCyan),
        ),
      );
    }

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(cred);

      final uid = user.uid;
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      // Delete patient document
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

      // Delete patient sub-collection: appointments
      final patientAppts = await db
          .collection('patients')
          .doc(uid)
          .collection('appointments')
          .get();
      for (final d in patientAppts.docs) {
        batch.delete(d.reference);
      }

      // Delete patient sub-collection: notifications
      final notifs = await db
          .collection('patients')
          .doc(uid)
          .collection('notifications')
          .get();
      for (final d in notifs.docs) {
        batch.delete(d.reference);
      }

      // Delete patient sub-collection: xrays
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
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        Navigator.pop(context); // dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Authentication error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
          child: Column(
            children: [
              // ── AppBar ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.neonCyan,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Personal Information',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _editing ? Icons.close_rounded : Icons.edit_rounded,
                        color: AppColors.neonCyan,
                      ),
                      onPressed: () => setState(() => _editing = !_editing),
                    ),
                  ],
                ),
              ),

              // ── Body ─────────────────────────────────────────────────
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.neonCyan,
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          _field(
                            _firstName,
                            'First Name',
                            Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 12),
                          _field(
                            _lastName,
                            'Last Name',
                            Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 12),
                          _field(
                            _email,
                            'Email',
                            Icons.email_outlined,
                            type: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),
                          _field(
                            _phone,
                            'Phone',
                            Icons.phone_outlined,
                            type: TextInputType.phone,
                          ),
                          const SizedBox(height: 12),
                          _field(
                            _age,
                            'Age',
                            Icons.cake_outlined,
                            type: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          _field(
                            _address,
                            'Address',
                            Icons.location_on_outlined,
                          ),

                          // Save button — only visible in edit mode
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
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.neonCyan,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Change Password button
                          SizedBox(
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: _showChangePasswordDialog,
                              icon: const Icon(
                                Icons.lock_outline,
                                color: AppColors.neonCyan,
                              ),
                              label: const Text(
                                'Change Password',
                                style: TextStyle(
                                  color: AppColors.neonCyan,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: AppColors.neonCyan.withOpacity(0.7),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),
                          const Divider(color: Colors.white12),
                          const SizedBox(height: 16),

                          // Delete Account button
                          SizedBox(
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: _saving ? null : _deleteAccount,
                              icon: const Icon(
                                Icons.delete_forever_rounded,
                                color: Colors.red,
                              ),
                              label: const Text(
                                'Delete Account',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Colors.red.withOpacity(0.7),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType? type,
  }) {
    return TextField(
      controller: c,
      enabled: _editing,
      keyboardType: type,
      style: const TextStyle(color: AppColors.text),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        prefixIcon: Icon(icon, color: AppColors.neonCyan, size: 18),
        filled: true,
        fillColor: AppColors.panel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.neonCyan.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.neonCyan.withOpacity(0.3)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neonCyan, width: 1.5),
        ),
      ),
    );
  }
}
