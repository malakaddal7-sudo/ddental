// lib/patient/explore_page.dart
// FIX: removed `const` from NotificationsPage() call (line 75)
//      NotificationsPage uses AppColors which are not compile-time constants

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../widgets/neon_panel.dart';
import '../widgets/neon_button.dart';
import 'checkup_page.dart';
import 'cleaning_page.dart';
import 'profile/xray_images_page.dart';
import 'surgery_page.dart';
import 'book_appointment_screen.dart';
import 'find_clinic_page.dart';
import 'notifications_page.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good Morning!',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          'Find Your Care',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          // FIX: removed `const` — NotificationsPage uses
                          // AppColors which are not compile-time constants
                          builder: (_) => const NotificationsPage(),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.panel.withOpacity(0.5),
                          border: Border.all(
                            color: AppColors.neonCyan.withOpacity(0.35),
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_rounded,
                          color: AppColors.neonCyan,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Search bar ────────────────────────────────────────────
                NeonPanel(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: AppColors.text),
                    onChanged: (v) =>
                        setState(() => _searchQuery = v.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search doctors by name or specialty...',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.neonCyan,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear_rounded,
                                color: AppColors.textMuted,
                                size: 18,
                              ),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                if (_searchQuery.isNotEmpty) ...[
                  const Text(
                    'Search Results',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DoctorList(query: _searchQuery),
                ] else ...[
                  // ── Banner ────────────────────────────────────────────
                  NeonPanel(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your Dental Health',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Book an Appointment\nToday!',
                                style: TextStyle(
                                  color: AppColors.text,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: 160,
                                child: NeonButton(
                                  label: 'Book Now',
                                  icon: Icons.calendar_today_rounded,
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const BookAppointmentPage(),
                                    ),
                                  ),
                                  height: 44,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text('🦷', style: TextStyle(fontSize: 56)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Services ──────────────────────────────────────────
                  const Text(
                    'Our Services',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 16),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CheckupPage(),
                          ),
                        ),
                        child: _buildServiceCard(
                          'Checkup',
                          Icons.search_rounded,
                          const Color(0xFF00897B),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CleaningPage(),
                          ),
                        ),
                        child: _buildServiceCard(
                          'Cleaning',
                          Icons.clean_hands_rounded,
                          const Color(0xFF00ACC1),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const XRayImagesPage(),
                          ),
                        ),
                        child: _buildServiceCard(
                          'X-Ray',
                          Icons.image_rounded,
                          const Color(0xFF26A69A),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SurgeryPage(),
                          ),
                        ),
                        child: _buildServiceCard(
                          'Surgery',
                          Icons.medical_services_rounded,
                          const Color(0xFF00695C),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Our Doctors ───────────────────────────────────────
                  const Text(
                    'Our Doctors',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _DoctorList(query: ''),

                  const SizedBox(height: 16),

                  // ── Find Clinic ───────────────────────────────────────
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FindClinicPage()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppColors.cardDecoration,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.neonCyan.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: AppColors.neonCyan,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Find the Clinic',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.text,
                                  ),
                                ),
                                Text(
                                  'Address, hours & directions',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppColors.neonCyan,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppColors.cardDecoration,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
bool _hasValidName(Map<String, dynamic> d) {
  final first = (d['firstName'] ?? '').toString().trim();
  final last = (d['lastName'] ?? '').toString().trim();
  if (first.isEmpty && last.isEmpty) return false;
  final full = '$first $last'.trim().toLowerCase();
  if (full.length <= 2) return false;
  if (full == 'dr') return false;
  return true;
}

// ─────────────────────────────────────────────────────────────────────────────
class _DoctorList extends StatelessWidget {
  final String query;
  const _DoctorList({required this.query});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(
                color: AppColors.neonCyan,
                strokeWidth: 2,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading doctors',
              style: TextStyle(color: Colors.red.shade300, fontSize: 13),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        final validDocs = docs
            .where((doc) => _hasValidName(doc.data() as Map<String, dynamic>))
            .toList();

        final filtered = query.isEmpty
            ? validDocs
            : validDocs.where((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final name = '${d['firstName'] ?? ''} ${d['lastName'] ?? ''}'
                    .toLowerCase();
                final spec = (d['specialty'] ?? '').toString().toLowerCase();
                return name.contains(query) || spec.contains(query);
              }).toList();

        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: AppColors.textMuted.withOpacity(0.4),
                ),
                const SizedBox(height: 10),
                Text(
                  query.isEmpty
                      ? 'No doctors registered yet'
                      : 'No doctors found for "$query"',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: filtered.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final doctorId = doc.id;
            final name = 'Dr. ${d['firstName'] ?? ''} ${d['lastName'] ?? ''}'
                .trim();
            final specialty = d['specialty'] ?? 'Dentist';
            final clinic = (d['clinicName'] ?? '').toString();
            final city = (d['city'] ?? '').toString();
            final photoUrl = d['profileImageUrl'] as String?;

            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _DoctorProfilePage(
                    doctorId: doctorId,
                    name: name,
                    specialty: specialty,
                    clinic: clinic,
                    city: city,
                    photoUrl: photoUrl,
                    data: d,
                  ),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: AppColors.cardDecoration,
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.panel2,
                        borderRadius: BorderRadius.circular(14),
                        image: photoUrl != null
                            ? DecorationImage(
                                image: NetworkImage(photoUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: photoUrl == null
                          ? const Icon(
                              Icons.person_rounded,
                              color: AppColors.neonCyan,
                              size: 28,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.text,
                            ),
                          ),
                          Text(
                            specialty,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                          if (clinic.isNotEmpty)
                            Text(
                              clinic,
                              style: const TextStyle(
                                color: AppColors.neonCyan,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Book button — passes doctorId + doctorName
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookAppointmentScreen(
                            doctorId: doctorId,
                            doctorName: name,
                          ),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Book',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Doctor Profile Page
// ─────────────────────────────────────────────────────────────────────────────
class _DoctorProfilePage extends StatelessWidget {
  final String doctorId;
  final String name;
  final String specialty;
  final String clinic;
  final String city;
  final String? photoUrl;
  final Map<String, dynamic> data;

  const _DoctorProfilePage({
    required this.doctorId,
    required this.name,
    required this.specialty,
    required this.clinic,
    required this.city,
    required this.photoUrl,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final phone = (data['phone'] ?? data['phoneNumber'] ?? '').toString();
    final email = (data['email'] ?? '').toString();
    final bio = (data['bio'] ?? data['about'] ?? '').toString();
    final experience = (data['experience'] ?? data['yearsOfExperience'] ?? '')
        .toString();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Top bar
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
                      const Spacer(),
                      const Text(
                        'Doctor Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Avatar
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.panel2,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.neonCyan.withOpacity(0.4),
                      width: 2,
                    ),
                    image: photoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(photoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: photoUrl == null
                      ? const Icon(
                          Icons.person_rounded,
                          color: AppColors.neonCyan,
                          size: 44,
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  specialty,
                  style: const TextStyle(
                    color: AppColors.neonCyan,
                    fontSize: 14,
                  ),
                ),
                if (clinic.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    clinic,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (city.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.textMuted,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        city,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 28),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      if (bio.isNotEmpty)
                        _infoSection('About', bio, Icons.info_rounded),
                      _infoRow(
                        Icons.medical_services_rounded,
                        'Specialty',
                        specialty,
                      ),
                      if (experience.isNotEmpty)
                        _infoRow(
                          Icons.workspace_premium_rounded,
                          'Experience',
                          experience,
                        ),
                      if (phone.isNotEmpty)
                        _infoRow(Icons.phone_rounded, 'Phone', phone),
                      if (email.isNotEmpty)
                        _infoRow(Icons.email_rounded, 'Email', email),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        child: NeonButton(
                          label: 'Book Appointment',
                          icon: Icons.calendar_today_rounded,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookAppointmentScreen(
                                doctorId: doctorId,
                                doctorName: name,
                              ),
                            ),
                          ),
                          height: 52,
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
      ),
    );
  }

  Widget _infoSection(String title, String content, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppColors.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.neonCyan, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.neonCyan,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: AppColors.cardDecoration,
      child: Row(
        children: [
          Icon(icon, color: AppColors.neonCyan, size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
