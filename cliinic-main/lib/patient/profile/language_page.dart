import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  String _selected = 'English';

  final _langs = [
    {'name': 'English', 'flag': '🇬🇧'},
    {'name': 'Français', 'flag': '🇫🇷'},
    {'name': 'العربية', 'flag': '🇩🇿'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Language'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.text),
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.bgGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Container(
              decoration: AppColors.cardDecoration, // لا const هنا
              child: Column(
                children: _langs.map((l) {
                  final sel = _selected == l['name'];
                  return ListTile(
                    leading: Text(
                      l['flag']!,
                      style: TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      l['name']!,
                      style: TextStyle(
                        color: sel ? AppColors.neonTeal : AppColors.text,
                        fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: sel
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.neonTeal,
                          )
                        : null,
                    onTap: () => setState(() => _selected = l['name']!),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}