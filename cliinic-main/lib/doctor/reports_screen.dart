import 'package:flutter/material.dart';
import 'doctor_colors.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DC.bg,
      appBar: AppBar(
        backgroundColor: DC.surface,
        title: const Text("Reports"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _reportCard("Monthly Patients", "128", Icons.people),
            _reportCard("Appointments", "42", Icons.calendar_today),
            _reportCard("Completed Treatments", "30", Icons.check_circle),
          ],
        ),
      ),
    );
  }

  Widget _reportCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: DC.cardDecoration,
      child: Row(
        children: [
          Icon(icon, color: DC.green),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: const TextStyle(color: DC.text)),
          ),
          Text(value,
              style: const TextStyle(
                  color: DC.text, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}