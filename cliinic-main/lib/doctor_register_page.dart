import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'doctor/doctor_home.dart';
import 'theme/app_colors.dart';
import 'widgets/neon_button.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

class DoctorRegisterPage extends StatefulWidget {
  const DoctorRegisterPage({super.key});

  @override
  State<DoctorRegisterPage> createState() => _DoctorRegisterPageState();
}

class _DoctorRegisterPageState extends State<DoctorRegisterPage> {
  Future<String?> uploadToCloudinaryWeb(
    Uint8List fileBytes,
    String fileName,
  ) async {
    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/dsd8zea8q/auto/upload",
    );

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = 'doctor_license'
      ..files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
      );

    final response = await request.send();
    final resBody = await response.stream.bytesToString();

    print("STATUS: ${response.statusCode}");
    print("BODY: $resBody");

    if (response.statusCode == 200) {
      final match = RegExp(r'"secure_url":"(.*?)"').firstMatch(resBody);
      return match?.group(1);
    } else {
      return null;
    }
  }

  // ─── Firebase register ──────────────────────────────────────────────────────
  Future<void> register() async {
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('doctors').doc(user.uid).set({
        'role': 'doctor',
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': email,
        'gender': _selectedGender,
        // ✅ FIX 1: dateOfBirth was never saved — now it is
        'dateOfBirth': _selectedDate != null
            ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
            : null,
        'medicalLicenseUrl': _medicalLicenseFileName,
        // Page 2
        'phone': _phoneController.text.trim(),
        'clinicPhone': _clinicPhoneController.text.trim(),
        'consultationFee': _consultationFeeController.text.trim(),
        // Page 3
        // ✅ FIX 2: was _specialtyController.text (always empty string!)
        //           now correctly uses _selectedSpecialty from the dropdown
        'specialty': _selectedSpecialty,
        'licenseNumber': _licenseNumberController.text.trim(),
        'yearsOfExperience': _yearsOfExperienceController.text.trim(),
        'clinicName': _clinicNameController.text.trim(),
        'universityDegree': _universityDegreeController.text.trim(),
        'nationalId': _nationalIdController.text.trim(),
        'medicalLicenseFileName': _medicalLicenseFileName,
        'streetAddress': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'wilaya': _selectedWilaya,
        'postalCode': _postalController.text.trim(),
        'isVerified': false,
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DoctorHome()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Auth error'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ─── Controllers ────────────────────────────────────────────────────────────
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  // Page 1
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Page 2 — doctor contact (no emergency contact, that's for patients)
  final _phoneController = TextEditingController();
  final _clinicPhoneController = TextEditingController();
  final _consultationFeeController = TextEditingController();

  // Page 3
  final _licenseNumberController = TextEditingController();
  final _yearsOfExperienceController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _universityDegreeController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _addressController = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _postalController = TextEditingController();
  String? _medicalLicenseFileName;

  // ─── State ──────────────────────────────────────────────────────────────────
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreeToTerms = false;
  bool _autoValidate1 = false;
  bool _autoValidate2 = false;
  bool _autoValidate3 = false;
  String _selectedGender = 'Male';
  String? _selectedWilaya;
  DateTime? _selectedDate;

  // ✅ Only one specialty variable — the dropdown state
  String _selectedSpecialty = 'General Practitioner';

  final List<String> _specialties = [
    'General Practitioner',
    'Cardiologist',
    'Dermatologist',
    'Endocrinologist',
    'Gastroenterologist',
    'Gynecologist',
    'Hematologist',
    'Infectious Disease',
    'Nephrologist',
    'Neurologist',
    'Oncologist',
    'Ophthalmologist',
    'Orthopedic Surgeon',
    'Otolaryngologist (ENT)',
    'Pediatrician',
    'Plastic Surgeon',
    'Psychiatrist',
    'Pulmonologist',
    'Radiologist',
    'Rheumatologist',
    'Surgeon',
    'Urologist',
    'Orthodontist',
    'Dentist',
    'Other',
  ];

  final List<String> _wilayas = [
    '01 - Adrar',
    '02 - Chlef',
    '03 - Laghouat',
    '04 - Oum El Bouaghi',
    '05 - Batna',
    '06 - Béjaïa',
    '07 - Biskra',
    '08 - Béchar',
    '09 - Blida',
    '10 - Bouira',
    '11 - Tamanrasset',
    '12 - Tébessa',
    '13 - Tlemcen',
    '14 - Tiaret',
    '15 - Tizi Ouzou',
    '16 - Alger',
    '17 - Djelfa',
    '18 - Jijel',
    '19 - Sétif',
    '20 - Saïda',
    '21 - Skikda',
    '22 - Sidi Bel Abbès',
    '23 - Annaba',
    '24 - Guelma',
    '25 - Constantine',
    '26 - Médéa',
    '27 - Mostaganem',
    "28 - M'Sila",
    '29 - Mascara',
    '30 - Ouargla',
    '31 - Oran',
    '32 - El Bayadh',
    '33 - Illizi',
    '34 - Bordj Bou Arréridj',
    '35 - Boumerdès',
    '36 - El Tarf',
    '37 - Tindouf',
    '38 - Tissemsilt',
    '39 - El Oued',
    '40 - Khenchela',
    '41 - Souk Ahras',
    '42 - Tipaza',
    '43 - Mila',
    '44 - Aïn Defla',
    '45 - Naâma',
    '46 - Aïn Témouchent',
    '47 - Ghardaïa',
    '48 - Relizane',
    '49 - Timimoun',
    '50 - Bordj Badji Mokhtar',
    '51 - Ouled Djellal',
    '52 - Béni Abbès',
    '53 - In Salah',
    '54 - In Guezzam',
    '55 - Touggourt',
    '56 - Djanet',
    "57 - El M'Ghair",
    '58 - El Meniaa',
  ];

  // ─── Navigation ─────────────────────────────────────────────────────────────
  void _nextPage() {
    bool isValid = false;

    if (_currentPage == 0) {
      setState(() => _autoValidate1 = true);
      isValid = _formKey1.currentState!.validate();
      if (isValid && _selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Please select your date of birth'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (isValid && !_agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Please agree to Terms and Conditions'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else if (_currentPage == 1) {
      setState(() => _autoValidate2 = true);
      isValid = _formKey2.currentState!.validate();
    } else if (_currentPage == 2) {
      setState(() => _autoValidate3 = true);
      isValid = _formKey3.currentState!.validate();
    }

    if (!isValid) return;

    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    }
  }

  Map<String, bool> _getPasswordStrength(String password) {
    return {
      'length': password.length >= 6,
      'uppercase': password.contains(RegExp(r'[A-Z]')),
      'lowercase': password.contains(RegExp(r'[a-z]')),
      'digit': password.contains(RegExp(r'[0-9]')),
      'special': password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
    };
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        bool localAgree = _agreeToTerms;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.bgGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(maxHeight: 550),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.gavel_rounded,
                          color: AppColors.neonCyan,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Terms and Conditions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.text),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    Divider(color: AppColors.stroke.withOpacity(0.7)),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTermsSection(
                              '1. Acceptance of Terms',
                              'By creating a doctor account on DocLine, you agree to these Terms.',
                            ),
                            _buildTermsSection(
                              '2. Professional Responsibility',
                              'All credentials you provide must be accurate and valid. Falsifying credentials results in account termination.',
                            ),
                            _buildTermsSection(
                              '3. Patient Data',
                              'Patient data is confidential and must be handled in compliance with applicable medical privacy laws.',
                            ),
                            _buildTermsSection(
                              '4. Appointment Policy',
                              'You are responsible for honoring scheduled appointments.',
                            ),
                            _buildTermsSection(
                              '5. Verification',
                              'Your account will be reviewed before you can accept patients.',
                            ),
                            _buildTermsSection(
                              '6. Contact Us',
                              'Questions? Contact us at support@docline.dz',
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(color: AppColors.stroke.withOpacity(0.7)),
                    Row(
                      children: [
                        Checkbox(
                          value: localAgree,
                          activeColor: AppColors.neonTeal,
                          checkColor: Colors.black,
                          onChanged: (v) =>
                              setDialogState(() => localAgree = v!),
                        ),
                        const Expanded(
                          child: Text(
                            'I have read and agree to the Terms and Conditions',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: localAgree
                            ? () {
                                setState(() => _agreeToTerms = true);
                                Navigator.pop(context);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonTeal,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Agree & Continue',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTermsSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.text,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.registerBgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _currentPage == 0
                          ? () => Navigator.pop(context)
                          : _prevPage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.panel.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.neonCyan.withOpacity(0.35),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_rounded,
                          color: AppColors.text,
                          size: 20,
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(3, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 24 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _currentPage >= index
                                ? Colors.white
                                : Colors.white38,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        );
                      }),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.panel.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.neonCyan.withOpacity(0.35),
                        ),
                      ),
                      child: Text(
                        '${_currentPage + 1}/3',
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [_buildPage1(), _buildPage2(), _buildPage3()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── PAGE 1: Personal ────────────────────────────────────────────────────────
  Widget _buildPage1() {
    final strength = _getPasswordStrength(_passwordController.text);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey1,
        autovalidateMode: _autoValidate1
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Icon(
              Icons.medical_services_rounded,
              size: 60,
              color: AppColors.neonCyan,
            ),
            const SizedBox(height: 10),
            const Text(
              'Doctor Registration',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Step 1: Personal Information',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildValidatedField(
                          _firstNameController,
                          'First Name',
                          Icons.person_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildValidatedField(
                          _lastNameController,
                          'Last Name',
                          Icons.person_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Date of birth
                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime(1985),
                        firstDate: DateTime(1940),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) setState(() => _selectedDate = date);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FFF8),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: _selectedDate == null
                              ? Colors.transparent
                              : const Color(0xFF00897B),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cake_rounded,
                            color: Color(0xFF00897B),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _selectedDate == null
                                ? 'Date of Birth *'
                                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                            style: TextStyle(
                              color: _selectedDate == null
                                  ? Colors.grey
                                  : Colors.black87,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Gender
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FFF8),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: const Color(0xFF00897B).withOpacity(0.25),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedGender,
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFF00897B),
                        ),
                        items: ['Male', 'Female'].map((g) {
                          return DropdownMenuItem(
                            value: g,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.wc_rounded,
                                  color: Color(0xFF00897B),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  g,
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedGender = v!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildValidatedField(
                    _emailController,
                    'Email Address',
                    Icons.email_rounded,
                    type: TextInputType.emailAddress,
                    isEmail: true,
                  ),
                  const SizedBox(height: 16),
                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.black87),
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Password is required';
                      if (value.length < 6) return 'Minimum 6 characters';
                      if (!value.contains(RegExp(r'[A-Z]')))
                        return 'Add an uppercase letter';
                      if (!value.contains(RegExp(r'[a-z]')))
                        return 'Add a lowercase letter';
                      if (!value.contains(RegExp(r'[0-9]')))
                        return 'Add a number';
                      if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')))
                        return 'Add a special character';
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Colors.black54),
                      prefixIcon: const Icon(
                        Icons.lock_rounded,
                        color: Color(0xFF00897B),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF0FFF8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Color(0xFF00897B),
                          width: 1.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 1.5,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  if (_passwordController.text.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FFF8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Password Requirements:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00897B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildStrengthRow(
                            '6+ characters',
                            strength['length']!,
                          ),
                          _buildStrengthRow(
                            'Uppercase (A-Z)',
                            strength['uppercase']!,
                          ),
                          _buildStrengthRow(
                            'Lowercase (a-z)',
                            strength['lowercase']!,
                          ),
                          _buildStrengthRow('Number (0-9)', strength['digit']!),
                          _buildStrengthRow(
                            'Special character',
                            strength['special']!,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _buildValidatedField(
                    _confirmPasswordController,
                    'Confirm Password',
                    Icons.lock_outline_rounded,
                    isPassword: true,
                    obscure: _obscureConfirm,
                    onToggle: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    isConfirmPassword: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Switch(
                        value: _agreeToTerms,
                        onChanged: (v) {
                          if (v) {
                            _showTermsDialog();
                          } else {
                            setState(() => _agreeToTerms = false);
                          }
                        },
                        activeColor: const Color(0xFF00897B),
                        inactiveThumbColor: Colors.grey,
                        inactiveTrackColor: Colors.black12,
                      ),
                      const Text(
                        'Agree to ',
                        style: TextStyle(color: Colors.black87),
                      ),
                      GestureDetector(
                        onTap: _showTermsDialog,
                        child: const Text(
                          'Terms and Conditions',
                          style: TextStyle(
                            color: Color(0xFF00897B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  NeonButton(
                    label: 'Continue',
                    icon: Icons.arrow_forward_rounded,
                    height: 52,
                    onPressed: _nextPage,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(color: Colors.black54),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'LOGIN',
                          style: TextStyle(
                            color: Color(0xFF00897B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── PAGE 2: Contact (doctor-specific, no emergency contact) ─────────────────
  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey2,
        autovalidateMode: _autoValidate2
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Icon(Icons.phone_rounded, size: 60, color: Colors.white),
            const SizedBox(height: 10),
            const Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Step 2: Personal & Clinic Contact',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal Mobile *',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FFF8),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Row(
                          children: [
                            Text('🇩🇿', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 6),
                            Text(
                              '+213',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00897B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.black87),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty)
                              return 'Phone is required';
                            if (value.length != 10)
                              return 'Must be exactly 10 digits';
                            if (!RegExp(r'^[0-9]+$').hasMatch(value))
                              return 'Numbers only';
                            return null;
                          },
                          decoration: _inputDeco(
                            'Phone Number',
                            Icons.phone_rounded,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: const Color(0xFF00897B).withOpacity(0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFF00897B),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Enter exactly 10 digits (e.g. 0555123456)',
                            style: TextStyle(
                              color: Color(0xFF00897B),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Clinic phone (optional)
                  const Text(
                    'Clinic Phone Number',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _clinicPhoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.black87),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return null; // optional
                      if (value.length != 10)
                        return 'Must be exactly 10 digits';
                      if (!RegExp(r'^[0-9]+$').hasMatch(value))
                        return 'Numbers only';
                      return null;
                    },
                    decoration: _inputDeco(
                      'Clinic Phone (Optional)',
                      Icons.local_hospital_rounded,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Consultation fee
                  TextFormField(
                    controller: _consultationFeeController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.black87),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'Consultation fee is required';
                      final n = double.tryParse(value.trim());
                      if (n == null || n < 0) return 'Enter a valid amount';
                      return null;
                    },
                    decoration: _inputDeco(
                      'Consultation Fee (DZD)',
                      Icons.payments_rounded,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildNextButton('Continue', () {
                    setState(() => _autoValidate2 = true);
                    final ok = _formKey2.currentState?.validate() ?? false;
                    if (!ok) return;
                    _nextPage();
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── PAGE 3: Professional + Address ─────────────────────────────────────────
  Widget _buildPage3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey3,
        autovalidateMode: _autoValidate3
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Icon(Icons.badge_rounded, size: 60, color: Colors.white),
            const SizedBox(height: 10),
            const Text(
              'Professional Details',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Step 3: Medical Credentials & Address',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildValidatedField(
                    _licenseNumberController,
                    'License / Registration Number',
                    Icons.badge_rounded,
                  ),
                  const SizedBox(height: 16),
                  // ✅ Specialty dropdown
                  const Text(
                    'Specialty *',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FFF8),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: const Color(0xFF00897B).withOpacity(0.25),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSpecialty,
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFF00897B),
                        ),
                        items: _specialties.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.local_hospital_rounded,
                                  color: Color(0xFF00897B),
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  s,
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        // ✅ This is what gets saved to Firestore
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _selectedSpecialty = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _yearsOfExperienceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.black87),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'Years of experience is required';
                      final n = int.tryParse(value.trim());
                      if (n == null || n < 0 || n > 60)
                        return 'Enter a valid number of years (0–60)';
                      return null;
                    },
                    decoration: _inputDeco(
                      'Years of Experience',
                      Icons.work_history_rounded,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildValidatedField(
                    _clinicNameController,
                    'Clinic Name',
                    Icons.local_hospital_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildValidatedField(
                    _universityDegreeController,
                    'University / Degree',
                    Icons.school_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildValidatedField(
                    _nationalIdController,
                    'National ID / Passport',
                    Icons.credit_card_rounded,
                    isOptional: true,
                  ),
                  const SizedBox(height: 16),
                  // Upload license
                  const Text(
                    'Upload Medical License (PDF or Image)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      FilePickerResult? result = await FilePicker.platform
                          .pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                            withData: true, // 🔥 REQUIRED for web
                          );

                      if (result != null) {
                        final fileBytes = result.files.single.bytes!;
                        final fileName = result.files.single.name;

                        String? url = await uploadToCloudinaryWeb(
                          fileBytes,
                          fileName,
                        );

                        print("UPLOAD URL: $url");

                        // 👇 أضف هذا هنا
                        if (url != null) {
                          setState(() {
                            _medicalLicenseFileName = url;
                          });
                        }
                      }
                      // TODO: add file_picker to pubspec.yaml, then use:
                      // import 'package:file_picker/file_picker.dart';
                      // FilePickerResult? result = await FilePicker.platform.pickFiles(
                      //   type: FileType.custom,
                      //   allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                      // );
                      // if (result != null) {
                      //   setState(() => _medicalLicenseFileName = result.files.single.name);
                      // }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FFF8),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: _medicalLicenseFileName != null
                              ? const Color(0xFF00897B)
                              : const Color(0xFF00897B).withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _medicalLicenseFileName != null
                                ? Icons.check_circle_rounded
                                : Icons.upload_file_rounded,
                            color: const Color(0xFF00897B),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _medicalLicenseFileName ??
                                  'Tap to upload PDF or Image',
                              style: TextStyle(
                                color: _medicalLicenseFileName != null
                                    ? Colors.black87
                                    : Colors.grey,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_medicalLicenseFileName != null)
                            GestureDetector(
                              onTap: () => setState(
                                () => _medicalLicenseFileName = null,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.red,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Clinic / Work Address',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildValidatedField(
                    _addressController,
                    'Street Address',
                    Icons.home_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildValidatedField(
                    _address2Controller,
                    'Street Address 2 (Optional)',
                    Icons.home_work_rounded,
                    isOptional: true,
                  ),
                  const SizedBox(height: 16),
                  _buildValidatedField(
                    _cityController,
                    'City',
                    Icons.location_city_rounded,
                  ),
                  const SizedBox(height: 16),
                  // Wilaya
                  FormField<String>(
                    validator: (_) => _selectedWilaya == null
                        ? 'Please select your Wilaya'
                        : null,
                    builder: (formFieldState) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FFF8),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: formFieldState.hasError
                                    ? Colors.red
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedWilaya,
                                isExpanded: true,
                                dropdownColor: Colors.white,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                                hint: const Row(
                                  children: [
                                    Icon(
                                      Icons.map_rounded,
                                      color: Color(0xFF00897B),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Select Wilaya *',
                                      style: TextStyle(color: Colors.black54),
                                    ),
                                  ],
                                ),
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: Color(0xFF00897B),
                                ),
                                items: _wilayas.map((w) {
                                  return DropdownMenuItem(
                                    value: w,
                                    child: Text(
                                      w,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  setState(() => _selectedWilaya = v);
                                  formFieldState.didChange(v);
                                },
                              ),
                            ),
                          ),
                          if (formFieldState.hasError)
                            Padding(
                              padding: const EdgeInsets.only(left: 12, top: 6),
                              child: Text(
                                formFieldState.errorText!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildValidatedField(
                    _postalController,
                    'Postal Code',
                    Icons.markunread_mailbox_rounded,
                    type: TextInputType.number,
                    isPostal: true,
                  ),
                  const SizedBox(height: 24),
                  NeonButton(
                    label: 'Create Doctor Account',
                    onPressed: () async {
                      setState(() => _autoValidate3 = true);
                      final ok = _formKey3.currentState?.validate() ?? false;
                      if (!ok) return;
                      await register();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────
  Widget _buildStrengthRow(String label, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: met ? AppColors.neonTeal : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: met ? AppColors.neonTeal : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54),
      prefixIcon: Icon(icon, color: const Color(0xFF00897B)),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF0FFF8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF00897B), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  Widget _buildValidatedField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggle,
    bool isEmail = false,
    bool isPostal = false,
    bool isOptional = false,
    bool isConfirmPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      style: const TextStyle(color: Colors.black87),
      validator: (value) {
        if (isOptional) return null;
        final v = (value ?? '').trim();
        if (v.isEmpty) return 'This field is required';
        if (isEmail &&
            !RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(v)) {
          return 'Enter a valid email address';
        }
        if (isPostal && v.length < 4) return 'Enter a valid postal code';
        if (isConfirmPassword && v != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF00897B)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: Colors.grey,
                ),
                onPressed: onToggle,
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF0FFF8),
        labelStyle: const TextStyle(color: Colors.black54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF00897B), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildNextButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00897B),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 3,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded),
          ],
        ),
      ),
    );
  }
}
