import 'package:flutter/material.dart';
import 'register_page.dart';
import 'doctor_register_page.dart';
import 'theme/app_colors.dart';
import 'nav/app_routes.dart';
import 'main.dart';
 
class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});
 
  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}
 
class _RoleSelectionPageState extends State<RoleSelectionPage>
    with SingleTickerProviderStateMixin {
  String _selectedRole = 'patient';
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
 
  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }
 
  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }
 
  void _onContinue() {
    if (_selectedRole == 'patient') {
      Navigator.push(
        context,
        AppRoutes.fadeSlide(const RegisterPage()),
      );
    } else {
      Navigator.push(
        context,
        AppRoutes.fadeSlide(const DoctorRegisterPage()),
      );
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(context, AppRoutes.fadeSlide(const LoginPage())),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.panel.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.neonCyan.withOpacity(0.35),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: AppColors.text,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
 
                  // Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.panel.withOpacity(0.35),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.neonCyan.withOpacity(0.5),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.neonCyan.withOpacity(0.22),
                                blurRadius: 22,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.medical_services_rounded,
                            size: 40,
                            color: AppColors.neonCyan,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Join DocLine',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Select your role to get started',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
 
                  const Text(
                    'I am joining as a...',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 16),
 
                  // Role cards
                  Row(
                    children: [
                      Expanded(
                        child: _RoleCard(
                          title: 'Patient',
                          description:
                              'Book appointments\nand manage your\nmedical care',
                          icon: Icons.person_rounded,
                          isSelected: _selectedRole == 'patient',
                          onTap: () => setState(() => _selectedRole = 'patient'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _RoleCard(
                          title: 'Doctor',
                          description:
                              'Manage patients,\nclinic and your\nappointments',
                          icon: Icons.medical_services_rounded,
                          isSelected: _selectedRole == 'doctor',
                          onTap: () => setState(() => _selectedRole = 'doctor'),
                        ),
                      ),
                    ],
                  ),
 
                  const SizedBox(height: 20),
 
                  // Info box
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SizeTransition(sizeFactor: anim, child: child),
                    ),
                    child: _selectedRole == 'doctor'
                        ? _InfoBox(
                            key: const ValueKey('doctor'),
                            icon: Icons.verified_rounded,
                            title: 'Doctor account includes:',
                            items: const [
                              '✓  Personal & contact information',
                              '✓  Medical specialty & license number',
                              '✓  Clinic address & consultation fee',
                              '✓  University degree & credentials',
                              '✓  Account verification (1–2 business days)',
                            ],
                          )
                        : _InfoBox(
                            key: const ValueKey('patient'),
                            icon: Icons.person_pin_rounded,
                            title: 'Patient account includes:',
                            items: const [
                              '✓  Personal information & date of birth',
                              '✓  Phone & emergency contact',
                              '✓  Home address & blood type',
                              '✓  Instant access after registration',
                            ],
                          ),
                  ),
 
                  const SizedBox(height: 36),
 
                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonTeal,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _selectedRole == 'patient'
                                ? Icons.person_rounded
                                : Icons.medical_services_rounded,
                            size: 20,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _selectedRole == 'patient'
                                ? 'Continue as Patient'
                                : 'Continue as Doctor',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 20,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ),
 
                  const SizedBox(height: 20),
 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(context, AppRoutes.fadeSlide(const LoginPage())),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: AppColors.neonTeal,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
 
// ─── Role Card ────────────────────────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
 
  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.panel.withOpacity(0.55)
              : AppColors.panel.withOpacity(0.25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.neonTeal
                : AppColors.stroke.withOpacity(0.4),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.neonTeal.withOpacity(0.18),
                    blurRadius: 18,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.neonTeal.withOpacity(0.15)
                        : AppColors.panel.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.neonTeal.withOpacity(0.5)
                          : AppColors.stroke.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: isSelected ? AppColors.neonTeal : AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                // Radio dot
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.neonTeal
                          : AppColors.stroke.withOpacity(0.5),
                      width: 2,
                    ),
                    color: Colors.transparent,
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.neonTeal,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.text : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
// ─── Info Box ─────────────────────────────────────────────────────────────────
class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;
 
  const _InfoBox({
    super.key,
    required this.icon,
    required this.title,
    required this.items,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panel.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.neonTeal.withOpacity(0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonTeal.withOpacity(0.07),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.neonCyan, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.neonCyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Text(
                item,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}