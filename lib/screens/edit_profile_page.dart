import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class EditProfilePage extends StatefulWidget {
  final ApiService api;
  final String token;
  final Map<String, dynamic> initialUser;

  const EditProfilePage({
    super.key,
    required this.api,
    required this.token,
    required this.initialUser,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _bioCtrl;
  late TextEditingController _qualCtrl;
  late TextEditingController _skillsCtrl;
  late TextEditingController _upiCtrl;
  late TextEditingController _bankNameCtrl;
  late TextEditingController _bankAccountNameCtrl;
  late TextEditingController _bankAccountNumberCtrl;
  late TextEditingController _bankIfscCtrl;

  DateTime? _dateOfBirth;
  bool _isLoading = false;
  File? _profileImageFile;
  String? _currentProfilePic;

  @override
  void initState() {
    super.initState();
    final u = widget.initialUser;
    _bioCtrl = TextEditingController(text: u['bio']?.toString() ?? '');
    _qualCtrl = TextEditingController(text: u['qualification']?.toString() ?? '');
    _skillsCtrl = TextEditingController(text: u['skills']?.toString() ?? '');
    _upiCtrl = TextEditingController(text: u['upi_id']?.toString() ?? '');
    _bankNameCtrl = TextEditingController(text: u['bank_name']?.toString() ?? '');
    _bankAccountNameCtrl = TextEditingController(text: u['bank_account_name']?.toString() ?? '');
    _bankAccountNumberCtrl = TextEditingController(text: u['bank_account_number']?.toString() ?? '');
    _bankIfscCtrl = TextEditingController(text: u['bank_ifsc']?.toString() ?? '');

    if (u['date_of_birth'] != null) {
      try {
        _dateOfBirth = DateTime.parse(u['date_of_birth'].toString());
      } catch (_) {}
    }
    _currentProfilePic = u['profile_pic']?.toString();
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _qualCtrl.dispose();
    _skillsCtrl.dispose();
    _upiCtrl.dispose();
    _bankNameCtrl.dispose();
    _bankAccountNameCtrl.dispose();
    _bankAccountNumberCtrl.dispose();
    _bankIfscCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.brandNavy,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.brandNavy,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _profileImageFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final payload = <String, dynamic>{
      'bio': _bioCtrl.text.trim(),
      'qualification': _qualCtrl.text.trim(),
      'skills': _skillsCtrl.text.trim(),
      'upi_id': _upiCtrl.text.trim(),
      'bank_name': _bankNameCtrl.text.trim(),
      'bank_account_name': _bankAccountNameCtrl.text.trim(),
      'bank_account_number': _bankAccountNumberCtrl.text.trim(),
      'bank_ifsc': _bankIfscCtrl.text.trim(),
    };

    if (_dateOfBirth != null) {
      payload['date_of_birth'] = DateFormat('yyyy-MM-dd').format(_dateOfBirth!);
    }

    try {
      dynamic res;
      if (_profileImageFile != null) {
        // Convert dynamic payload to string map
        final stringPayload = payload.map((k, v) => MapEntry(k, v.toString()));
        final List<http.MultipartFile> files = [
          await http.MultipartFile.fromPath('profile_pic', _profileImageFile!.path),
        ];
        res = await widget.api.postMultipart(
          '/me',
          stringPayload,
          token: widget.token,
          files: files,
        );
      } else {
        res = await widget.api.postJson(
          '/me',
          payload,
          token: widget.token,
        );
      }
      
      final data = res as Map<String, dynamic>;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // true indicates a refresh is needed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ApiConnectionException ? e.message : e.toString()),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _inputDeco(String label, {String? hint, IconData? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.brandOrange, size: 20) : null,
      filled: true,
      fillColor: AppColors.cardMutedBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.brandOrange, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.brandOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.brandOrange, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.brandNavy,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.brandNavy),
        title: const Text('Edit Profile', style: TextStyle(color: AppColors.brandNavy, fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.cardMutedBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.brandOrange, width: 2),
                        image: _profileImageFile != null
                            ? DecorationImage(image: FileImage(_profileImageFile!), fit: BoxFit.cover)
                            : (_currentProfilePic != null && _currentProfilePic!.isNotEmpty)
                                ? DecorationImage(image: NetworkImage(_currentProfilePic!), fit: BoxFit.cover)
                                : null,
                      ),
                      child: (_profileImageFile == null && (_currentProfilePic == null || _currentProfilePic!.isEmpty))
                          ? const Icon(Icons.person, size: 50, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.brandNavy,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildSectionHeader('Personal Information', Icons.person_outline),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardMutedBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: AppColors.brandOrange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _dateOfBirth == null 
                            ? 'Select Date of Birth' 
                            : DateFormat('MMM dd, yyyy').format(_dateOfBirth!),
                        style: TextStyle(
                          color: _dateOfBirth == null ? Colors.grey.shade600 : AppColors.brandNavy,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioCtrl,
              maxLines: 3,
              decoration: _inputDeco('Bio', prefixIcon: Icons.edit_note),
            ),
            
            _buildSectionHeader('Professional Details', Icons.work_outline),
            TextFormField(
              controller: _qualCtrl,
              decoration: _inputDeco('Highest Qualification', prefixIcon: Icons.school_outlined),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _skillsCtrl,
              decoration: _inputDeco('Skills (comma separated)', prefixIcon: Icons.star_border_outlined),
            ),

            _buildSectionHeader('Banking & Payments', Icons.account_balance_outlined),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Add these details carefully to receive your withdrawal payments securely.',
                      style: TextStyle(color: Colors.blue, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _upiCtrl,
              decoration: _inputDeco('UPI ID', hint: 'e.g. yourname@okaxis', prefixIcon: Icons.qr_code_scanner),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR Bank Transfer', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
            ),

            TextFormField(
              controller: _bankNameCtrl,
              decoration: _inputDeco('Bank Name', prefixIcon: Icons.account_balance),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bankAccountNameCtrl,
              decoration: _inputDeco('Account Holder Name', prefixIcon: Icons.badge_outlined),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bankAccountNumberCtrl,
              keyboardType: TextInputType.number,
              decoration: _inputDeco('Account Number', prefixIcon: Icons.numbers),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bankIfscCtrl,
              decoration: _inputDeco('IFSC Code', prefixIcon: Icons.pin_outlined),
            ),

            const SizedBox(height: 48),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandOrange.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FilledButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
