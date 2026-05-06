import 'package:flutter/material.dart';
import 'main.dart';
import 'role_selection_page.dart'; // ✅ changed from register_page.dart
import 'theme/app_colors.dart';
import 'widgets/neon_button.dart';
import 'nav/app_routes.dart';
 
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
 
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}
 
class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;
 
  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Welcome to DocLine',
      'subtitle': 'What is DocLine?',
      'description':
          'DocLine helps dental clinics manage patients, appointments, and medical records more efficiently.',
      'icon': Icons.local_hospital_rounded,
      'icon2': Icons.person_rounded,
      'color1': AppColors.neonTeal,
      'color2': AppColors.tealDeep,
    },
    {
      'title': 'Dental Professionals',
      'subtitle': 'For Doctors',
      'description':
          'Manage your patients easily, set appointments, add diagnoses, and track medical records all in one place.',
      'icon': Icons.medical_information_rounded,
      'icon2': Icons.assignment_rounded,
      'color1': AppColors.neonCyan,
      'color2': AppColors.tealDeep,
    },
    {
      'title': 'We Take Care of Your Teeth!',
      'subtitle': 'For Patients',
      'description':
          'Book appointments online, view your medical records, track your dental health on your own terms.',
      'icon': Icons.calendar_today_rounded,
      'icon2': Icons.health_and_safety_rounded,
      'color1': AppColors.neonTeal,
      'color2': AppColors.tealDeep,
    },
    {
      'title': 'DocLine Services',
      'subtitle': 'What We Offer',
      'description':
          'Everything you need for a modern dental clinic experience.',
      'icon': Icons.star_rounded,
      'icon2': Icons.verified_rounded,
      'color1': AppColors.neonCyan,
      'color2': AppColors.tealDeep,
      'services': [
        {'icon': Icons.business_rounded, 'label': 'Dental Office'},
        {'icon': Icons.person_rounded, 'label': 'Dental Hygienist'},
        {'icon': Icons.medical_services_rounded, 'label': 'Dental Assistant'},
        {'icon': Icons.local_hospital_rounded, 'label': 'Associate Dentist'},
        {'icon': Icons.support_agent_rounded, 'label': 'Front Desk'},
      ],
    },
  ];
 
  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }
 
  void _goToLogin() {
    Navigator.push(
      context,
      AppRoutes.fadeSlide(const LoginPage()),
    );
  }
 
  void _goToRegister() {
    Navigator.push(
      context,
      AppRoutes.fadeSlide(const RoleSelectionPage()), // ✅ changed from RegisterPage()
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppColors.bgGradient)),
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _pages.length,
            itemBuilder: (context, index) => _buildPage(index),
          ),
 
          // Dots indicator
          Positioned(
            bottom: 140,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white38,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
 
          // Next arrow button
          Positioned(
            bottom: 170,
            right: 24,
            child: GestureDetector(
              onTap: _nextPage,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.panel.withOpacity(0.35),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: AppColors.neonCyan.withOpacity(0.8), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonCyan.withOpacity(0.22),
                      blurRadius: 18,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.neonCyan,
                  size: 28,
                ),
              ),
            ),
          ),
 
          // Skip button
          Positioned(
            top: 50,
            right: 24,
            child: GestureDetector(
              onTap: _goToLogin,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.panel.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.neonCyan.withOpacity(0.35), width: 1),
                ),
                child: const Text('Skip',
                    style: TextStyle(
                        color: AppColors.text, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
 
          // Buttons
          Positioned(
            bottom: 50,
            left: 24,
            right: 24,
            child: Row(
              children: [
                Expanded(
                  child: NeonButton(
                    label: 'Sign up',
                    icon: Icons.person_add_rounded,
                    onPressed: _goToRegister, // ✅ now goes to RoleSelectionPage
                    height: 52,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _goToLogin,
                    icon: const Icon(Icons.login_rounded, color: AppColors.neonCyan),
                    label: const Text(
                      'Log In',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: AppColors.text,
                      side: BorderSide(
                        color: AppColors.neonCyan.withOpacity(0.55),
                        width: 1.2,
                      ),
                      backgroundColor: AppColors.panel.withOpacity(0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _buildPage(int index) {
    final page = _pages[index];
    final bool isLastPage = index == _pages.length - 1;
 
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bg0,
            (page['color2'] as Color).withOpacity(0.35),
            AppColors.bg1,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 80),
 
              // Illustration
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: isLastPage
                    ? _buildServicesIllustration(page)
                    : _buildIconIllustration(page),
              ),
 
              const SizedBox(height: 40),
 
              // Subtitle
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  page['subtitle'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
 
              const SizedBox(height: 16),
 
              // Title
              Text(
                page['title'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
 
              const SizedBox(height: 16),
 
              // Description
              Text(
                page['description'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white70,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
 
  Widget _buildIconIllustration(Map<String, dynamic> page) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 20,
          left: 20,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(page['icon'], size: 60, color: Colors.white),
            ),
            const SizedBox(width: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(page['icon2'], size: 45, color: Colors.white70),
            ),
          ],
        ),
        const Positioned(
          top: 16,
          right: 30,
          child: Text('🦷', style: TextStyle(fontSize: 28)),
        ),
      ],
    );
  }
 
  Widget _buildServicesIllustration(Map<String, dynamic> page) {
    final services = page['services'] as List<Map<String, dynamic>>;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🦷', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: services.map((s) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white38),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(s['icon'] as IconData, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(s['label'] as String,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}