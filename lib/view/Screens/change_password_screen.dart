import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_pharma_net/view/Widgets/common_ui_elements.dart';
import 'package:smart_pharma_net/viewmodels/auth_viewmodel.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final authViewModel = context.read<AuthViewModel>();
      final success = await authViewModel.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        // START OF FIX: Used 'errorMessage' instead of 'error'
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to change password: ${authViewModel.errorMessage}'), backgroundColor: Colors.red),
        );
        // END OF FIX
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Change Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: InteractiveParticleBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ========== بداية التعديل: تم تصحيح طريقة استدعاء الأيقونة ==========
                  GlowingTextField(
                    controller: _currentPasswordController,
                    hintText: 'Current Password',
                    prefixIcon: const Icon(Icons.lock_open_outlined, color: Colors.white70), // تم التصحيح هنا
                    isPassword: true,
                    validator: (value) => value!.isEmpty ? 'Please enter your current password' : null,
                  ),
                  const SizedBox(height: 20),
                  GlowingTextField(
                    controller: _newPasswordController,
                    hintText: 'New Password',
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70), // تم التصحيح هنا
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter a new password';
                      if (value.length < 8) return 'Password must be at least 8 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  GlowingTextField(
                    controller: _confirmPasswordController,
                    hintText: 'Confirm New Password',
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70), // تم التصحيح هنا
                    isPassword: true,
                    validator: (value) {
                      if (value != _newPasswordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  // ========== نهاية التعديل ==========
                  const SizedBox(height: 40),
                  authViewModel.isLoading
                      ? const CircularProgressIndicator()
                      : PulsingActionButton(
                    label: 'Change Password',
                    onTap: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
