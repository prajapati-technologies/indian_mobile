import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/auth_layout.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
    required this.api,
    this.onSuccess,
    this.onSwitchToLogin,
  });

  final ApiService api;
  final void Function(String token)? onSuccess;
  final VoidCallback? onSwitchToLogin;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _password = TextEditingController();
  final _password2 = TextEditingController();
  
  bool _busy = false;
  bool _obscurePassword = true;
  bool _obscurePassword2 = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _mobile.dispose();
    _password.dispose();
    _password2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms & Conditions and Privacy Policy')),
      );
      return;
    }
    
    setState(() => _busy = true);
    try {
      final body = <String, dynamic>{
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'mobile': _mobile.text.trim(), // added from design
        'password': _password.text,
        'password_confirmation': _password2.text,
      };

      final j = await widget.api.postJson('/auth/register', body);
      final token = j['token'] as String?;
      if (!mounted) return;
      if (token != null) {
        if (widget.onSuccess != null) {
          widget.onSuccess!(token);
        } else {
          Navigator.of(context).pop(token);
        }
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      final msg = _parseError(e.body);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String _parseError(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        final msg = decoded['message'];
        if (msg is String) {
          return msg;
        }
        final errs = decoded['errors'];
        if (errs is Map && errs.isNotEmpty) {
          final first = errs.values.first;
          if (first is List && first.isNotEmpty) {
            return first.first.toString();
          }
        }
      }
    } catch (_) {}
    return body;
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.orange.shade700),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.orange, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      isLogin: false,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create Account',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F2C59),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Join us and stay updated with real information',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _name,
              decoration: _inputDecoration('Full Name', Icons.person_outline),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              decoration: _inputDecoration('Email Address', Icons.email_outlined),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter email' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mobile,
              decoration: _inputDecoration('Mobile Number', Icons.phone_outlined),
              keyboardType: TextInputType.phone,
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter mobile number' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              obscureText: _obscurePassword,
              decoration: _inputDecoration('Password', Icons.lock_outline).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password2,
              obscureText: _obscurePassword2,
              decoration: _inputDecoration('Confirm Password', Icons.lock_outline).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword2 ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword2 = !_obscurePassword2;
                    });
                  },
                ),
              ),
              validator: (v) => v != _password.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _agreedToTerms,
                    onChanged: (val) {
                      setState(() {
                        _agreedToTerms = val ?? false;
                      });
                    },
                    activeColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.5),
                        children: [
                          TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'Terms & Conditions\n',
                            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: 'and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _busy ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008A20), // Green button
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('or continue with', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SocialLoginButton(
                  icon: Icons.g_mobiledata,
                  color: Colors.red,
                  onTap: () {},
                ),
                const SizedBox(width: 16),
                _SocialLoginButton(
                  icon: Icons.facebook,
                  color: Colors.blue,
                  onTap: () {},
                ),
                const SizedBox(width: 16),
                _SocialLoginButton(
                  icon: Icons.apple,
                  color: Colors.black,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Already have an account? ",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                GestureDetector(
                  onTap: () {
                    if (widget.onSwitchToLogin != null) {
                      widget.onSwitchToLogin!();
                    } else {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => LoginPage(api: widget.api),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    "Login Now",
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SocialLoginButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
