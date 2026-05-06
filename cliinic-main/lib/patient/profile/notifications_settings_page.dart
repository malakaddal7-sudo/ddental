import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bar_widget.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});
  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends State<NotificationSettingsPage> {
  final _settings = {
    'Appointment Updates': true,
    'Reminders (24h before)': true,
    'Medical Record Changes': false,
    'Promotions & Offers': false,
    'System Alerts': true,
  };

  final _subtitles = {
    'Appointment Updates': 'Confirmations, cancellations and changes',
    'Reminders (24h before)': 'Get reminded a day before your visit',
    'Medical Record Changes': 'When doctor updates your file',
    'Promotions & Offers': 'Special deals and clinic news',
    'System Alerts': 'Important app notifications',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(children: [
            CustomAppBar(title: 'Notifications'),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  decoration: AppColors.cardDecoration,
                  child: Column(
                    children: List.generate(
                        _settings.keys.length, (i) {
                      final key = _settings.keys.elementAt(i);
                      final isLast = i == _settings.length - 1;
                      return Column(children: [
                        SwitchListTile(
                          value: _settings[key]!,
                          onChanged: (v) =>
                              setState(() => _settings[key] = v),
                          activeColor: AppColors.neonTeal,
                          inactiveTrackColor: AppColors.stroke,
                          title: Text(key, style: const TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w500,
                              fontSize: 14)),
                          subtitle: Text(_subtitles[key]!,
                              style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12)),
                        ),
                        if (!isLast)
                          Divider(height: 1,
                              color: AppColors.stroke.withOpacity(0.4)),
                      ]);
                    }),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}