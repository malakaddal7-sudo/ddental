import 'package:flutter/material.dart';
import 'doctor_colors.dart';
import 'dashboard_screen.dart';
import 'patient_screen.dart';
import 'appointment_screen.dart';
import 'requests_profile_screen.dart';
import 'profile_screen.dart';

class DoctorHome extends StatefulWidget {
  const DoctorHome({super.key});
  @override
  State<DoctorHome> createState() => _DoctorHomeState();
}

class _DoctorHomeState extends State<DoctorHome> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),     // 0 – Home
    PatientListScreen(),   // 1 – Patients
    AppointmentScreen(),   // 2 – Schedule
    RequestsScreen(),      // 3 – Requests
    ProfileScreen(),       // 4 – Profile
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DC.bg,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: DC.surface,
          border: Border(top: BorderSide(color: DC.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: DC.green,
          unselectedItemColor: DC.textMuted,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 9),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_rounded),
              label: 'Patients',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_rounded),
              label: 'Schedule',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.mark_email_unread_rounded),
              label: 'Requests',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
