import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/neon_panel.dart';

class CredentialsPage extends StatefulWidget {
  const CredentialsPage({super.key});

  @override
  State<CredentialsPage> createState() => _CredentialsPageState();
}

class _CredentialsPageState extends State<CredentialsPage> {
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _emailCtrl = TextEditingController(text: 'patient@docline.dz');
  final _phoneCtrl = TextEditingController(text: '+213 555 123 456');

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _twoFactor = false;

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

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
                      _sectionLabel('Login Information'),
                      const SizedBox(height: 10),
                      NeonPanel(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            _buildField(
                              label: 'Email Address',
                              controller: _emailCtrl,
                              icon: Icons.email_rounded,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 14),
                            _buildField(
                              label: 'Phone Number',
                              controller: _phoneCtrl,
                              icon: Icons.phone_rounded,
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _sectionLabel('Change Password'),
                      const SizedBox(height: 10),
                      NeonPanel(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            _buildPasswordField(
                              label: 'Current Password',
                              controller: _currentPasswordCtrl,
                              visible: _showCurrent,
                              onToggle: () => setState(() => _showCurrent = !_showCurrent),
                            ),
                            const SizedBox(height: 14),
                            _buildPasswordField(
                              label: 'New Password',
                              controller: _newPasswordCtrl,
                              visible: _showNew,
                              onToggle: () => setState(() => _showNew = !_showNew),
                            ),
                            const SizedBox(height: 14),
                            _buildPasswordField(
                              label: 'Confirm New Password',
                              controller: _confirmPasswordCtrl,
                              visible: _showConfirm,
                              onToggle: () => setState(() => _showConfirm = !_showConfirm),
                            ),
                            _passwordStrengthBar(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _sectionLabel('Security'),
                      const SizedBox(height: 10),
                      NeonPanel(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                        child: Column(
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _twoFactor,
                              activeColor: AppColors.neonCyan,
                              onChanged: (v) => setState(() => _twoFactor = v),
                              title: const Text('Two-Factor Authentication',
                                  style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
                              subtitle: const Text('Add an extra layer of security',
                                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                              secondary: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.neonCyan.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.shield_rounded, color: AppColors.neonCyan, size: 20),
                              ),
                            ),
                            Divider(color: AppColors.stroke, height: 1),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.devices_rounded, color: Colors.orange, size: 20),
                              ),
                              title: const Text('Active Sessions',
                                  style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
                              subtitle: const Text('Manage logged-in devices',
                                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded,
                                  size: 14, color: AppColors.textMuted),
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
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
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _saveCredentials,
                            child: const Text('Save Changes',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
          const Text('Credentials',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.neonCyan.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.lock_rounded, color: AppColors.neonCyan, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(label,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.neonTeal, letterSpacing: 1.1));

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: AppColors.text),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.neonCyan, size: 18),
            filled: true,
            fillColor: AppColors.panel2,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.stroke)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.stroke)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.neonCyan, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool visible,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: !visible,
          style: const TextStyle(color: AppColors.text),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.neonCyan, size: 18),
            suffixIcon: IconButton(
              icon: Icon(visible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: AppColors.textMuted, size: 18),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: AppColors.panel2,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.stroke)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.stroke)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.neonCyan, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _passwordStrengthBar() {
    final pass = _newPasswordCtrl.text;
    if (pass.isEmpty) return const SizedBox.shrink();
    int strength = 0;
    if (pass.length >= 8) strength++;
    if (pass.contains(RegExp(r'[A-Z]'))) strength++;
    if (pass.contains(RegExp(r'[0-9]'))) strength++;
    if (pass.contains(RegExp(r'[!@#\$%^&*]'))) strength++;
    if (strength == 0) return const SizedBox.shrink();
    final colors = [Colors.red, Colors.orange, Colors.yellow, AppColors.neonTeal];
    final labels = ['Weak', 'Fair', 'Good', 'Strong'];
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(4, (i) => Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                height: 4,
                decoration: BoxDecoration(
                  color: i < strength ? colors[strength - 1] : AppColors.stroke,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            )),
          ),
          const SizedBox(height: 4),
          Text('Password strength: ${labels[strength - 1]}',
              style: TextStyle(color: colors[strength - 1], fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _saveCredentials() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.neonTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Row(children: [
          Icon(Icons.check_circle_rounded, color: Colors.white),
          SizedBox(width: 8),
          Text('Credentials updated successfully', style: TextStyle(color: Colors.white)),
        ]),
      ),
    );
  }
}
