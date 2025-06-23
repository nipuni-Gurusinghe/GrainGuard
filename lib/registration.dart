import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _pwdController = TextEditingController();
  final _addrController = TextEditingController();

  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final pwd = _pwdController.text.trim();
    final address = _addrController.text.trim();

    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pwd);
      final uid = cred.user!.uid;

      await FirebaseDatabase.instance.ref('users/$uid').set({
        'name': name,
        'email': email,
        'address': address,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful')),
      );
      Navigator.pop(context); // Go back to login
    } on FirebaseAuthException catch (e) {
      final msg = e.message ?? 'Registration failed';
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D7CAD), // Set background
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D7CAD),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Register'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter your name' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter email';
                  final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v);
                  return ok ? null : 'Enter valid email';
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _pwdController,
                label: 'Password (≥6 chars)',
                obscureText: true,
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Password too short' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addrController,
                label: 'Address',
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter address' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2D7CAD),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF2D7CAD))
                      : const Text(
                          'Register',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white54),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _pwdController.dispose();
    _addrController.dispose();
    super.dispose();
  }
}
