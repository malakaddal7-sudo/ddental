import 'package:flutter/material.dart';
import 'role_selection_page.dart';
import 'onboarding_page.dart';
import 'patient/patient_home.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'widgets/neon_panel.dart';
import 'widgets/neon_button.dart';
import 'widgets/focus_bounce_field.dart';
import 'nav/app_routes.dart';
import 'doctor/doctor_home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
 
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
 
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCHpgoFhwen5MiXbRgY69zTGWN7qANjIJo",
      appId: "1:878273031126:web:da142a3c3b3da1e97ed277",
      messagingSenderId: "878273031126",
      projectId: "my-firebase-app-2026-bns",
      authDomain: "my-firebase-app-2026-bns.firebaseapp.com",
      storageBucket: "my-firebase-app-2026-bns.firebasestorage.app",
    ),
  );
 
  runApp(const MyApp());
}
 
class MyApp extends StatelessWidget {
  const MyApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DocLine',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const OnboardingPage(),
    );
  }
}
 
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
 
  @override
  State<LoginPage> createState() => _LoginPageState();
}
 
class _LoginPageState extends State<LoginPage> {
  Future<void> login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );
 
      print("✅ Login success");
 
      final route = _isPatient
          ? AppRoutes.fadeSlide(const PatientHome())
          : AppRoutes.fadeSlide(const DoctorHome());
 
      Navigator.of(context).pushReplacement(route);
    } catch (e) {
      print("❌ Error: $e");
 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email or password incorrect")),
      );
    }
  }
 
  bool _obscurePassword = true;
  bool _isPatient = true;
 
  final _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;
 
  final _email = TextEditingController();
  final _password = TextEditingController();
 
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }
 
  void _resetLoginValidation() {
    _formKey.currentState?.reset();
    setState(() => _autoValidate = false);
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 50),
 
                // Logo & Title
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.panel.withOpacity(0.35),
                        shape: BoxShape.circle,
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
                        size: 70,
                        color: AppColors.neonCyan,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'DocLine',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Your Dental Care Partner',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textMuted,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
 
                const SizedBox(height: 40),
 
                // Card
                NeonPanel(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(22),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _autoValidate
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Toggle Patient / Doctor
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.panel2,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: AppColors.stroke.withOpacity(0.9),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (_isPatient) return;
                                    setState(() => _isPatient = true);
                                    _resetLoginValidation();
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: _isPatient
                                          ? AppColors.accentGradient
                                          : null,
                                      color: _isPatient
                                          ? null
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: _isPatient
                                          ? [
                                              BoxShadow(
                                                color: AppColors.neonCyan
                                                    .withOpacity(0.22),
                                                blurRadius: 18,
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.person_rounded,
                                          color: _isPatient
                                              ? Colors.black
                                              : AppColors.textMuted,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Patient',
                                          style: TextStyle(
                                            color: _isPatient
                                                ? Colors.black
                                                : AppColors.textMuted,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (!_isPatient) return;
                                    setState(() => _isPatient = false);
                                    _resetLoginValidation();
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: !_isPatient
                                          ? AppColors.accentGradient
                                          : null,
                                      color: !_isPatient
                                          ? null
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: !_isPatient
                                          ? [
                                              BoxShadow(
                                                color: AppColors.neonCyan
                                                    .withOpacity(0.22),
                                                blurRadius: 18,
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.medical_information_rounded,
                                          color: !_isPatient
                                              ? Colors.black
                                              : AppColors.textMuted,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Doctor',
                                          style: TextStyle(
                                            color: !_isPatient
                                                ? Colors.black
                                                : AppColors.textMuted,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
 
                        const SizedBox(height: 28),
 
                        // Welcome text
                        Text(
                          _isPatient ? 'Welcome Back!' : 'Doctor Login',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isPatient
                              ? 'Sign in to manage your appointments'
                              : 'Sign in to manage your patients',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
 
                        const SizedBox(height: 24),
 
                        FocusBounceField(
                          controller: _email,
                          label: 'Email Address',
                          icon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.isEmpty) return 'Email is required';
                            final ok = RegExp(
                              r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$',
                            ).hasMatch(value);
                            if (!ok) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
 
                        FocusBounceField(
                          controller: _password,
                          label: 'Password',
                          icon: Icons.lock_rounded,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.isEmpty) return 'Password is required';
                            return null;
                          },
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
 
                        const SizedBox(height: 10),
 
                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: AppColors.neonTeal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
 
                        NeonButton(
                          label: 'Login',
                          onPressed: () {
                            setState(() => _autoValidate = true);
                            final ok =
                                _formKey.currentState?.validate() ?? false;
                            if (!ok) return;
                            login();
                          },
                        ),
 
                        const SizedBox(height: 20),
 
                        // ✅ Register goes to RoleSelectionPage
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account? ",
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                            GestureDetector(
                              onTap: () {
                                // ✅ This is the key fix — always go to RoleSelectionPage
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RoleSelectionPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Register',
                                style: TextStyle(
                                  color: AppColors.neonTeal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
 
                const SizedBox(height: 30),
 
                const Text(
                  'DocLine — Dental Care Made Easy',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}