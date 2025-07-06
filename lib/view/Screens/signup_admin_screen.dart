import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:smart_pharma_net/viewmodels/auth_viewmodel.dart';
import 'package:smart_pharma_net/view/Screens/welcome_screen.dart';
import 'package:smart_pharma_net/view/Widgets/common_ui_elements.dart';


class SignUpAdminScreen extends StatefulWidget {
  const SignUpAdminScreen({super.key});

  @override
  State<SignUpAdminScreen> createState() => _SignUpAdminScreenState();
}

class _SignUpAdminScreenState extends State<SignUpAdminScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedGender;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a gender.'),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating, // Consistent styling
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF636AE8)),
            ),
          ),
        ),
      );

      final success = await authViewModel.register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        gender: _selectedGender!,
        phone: _phoneController.text.trim(),
        nationalID: _nationalIdController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please log in.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
            ),
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                (route) => false,
          );

        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authViewModel.errorMessage ?? 'Registration failed.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
            ),
          );
        }
      }
    }
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    return PlayAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      delay: Duration(milliseconds: 200 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - value)),
            child: child,
          ),
        );
      },
    );
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
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: InteractiveParticleBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0).copyWith(top: 80, bottom: 40),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildAnimatedItem(
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 15.0, color: Color(0xFF636AE8))],
                      ),
                    ),
                    0,
                  ),
                  const SizedBox(height: 12),
                  _buildAnimatedItem(
                    Text('Join the network', style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.7))),
                    1,
                  ),
                  const SizedBox(height: 40),
                  _buildAnimatedItem(
                    GlowingTextField(
                      controller: _firstNameController,
                      hintText: 'First Name',
                      prefixIcon: const Icon(Icons.person_outline, color: Colors.white70),
                      validator: (value) => value!.isEmpty ? 'Please enter first name' : null,
                    ),
                    2,
                  ),
                  const SizedBox(height: 24),
                  _buildAnimatedItem(
                    GlowingTextField(
                      controller: _lastNameController,
                      hintText: 'Last Name',
                      prefixIcon: const Icon(Icons.person_outline, color: Colors.white70),
                      validator: (value) => value!.isEmpty ? 'Please enter last name' : null,
                    ),
                    3,
                  ),
                  const SizedBox(height: 24),
                  _buildAnimatedItem(
                    GlowingTextField(
                      controller: _usernameController,
                      hintText: 'Username',
                      prefixIcon: const Icon(Icons.alternate_email, color: Colors.white70),
                      validator: (value) => value!.isEmpty ? 'Please enter a username' : null,
                    ),
                    4,
                  ),
                  const SizedBox(height: 24),
                  _buildAnimatedItem(
                    GlowingTextField(
                      controller: _emailController,
                      hintText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => (value == null || !value.contains('@')) ? 'Enter a valid email' : null,
                    ),
                    5,
                  ),
                  const SizedBox(height: 24),
                  _buildAnimatedItem(
                    GlowingTextField(
                      controller: _phoneController,
                      hintText: 'Phone Number',
                      prefixIcon: const Icon(Icons.phone_outlined, color: Colors.white70),
                      keyboardType: TextInputType.phone,
                      validator: (value) => (value == null || value.isEmpty) ? 'Enter phone number' : null,
                    ),
                    6,
                  ),
                  const SizedBox(height: 24),
                  _buildAnimatedItem(
                    GlowingTextField(
                      controller: _nationalIdController,
                      hintText: 'National ID',
                      prefixIcon: const Icon(Icons.badge_outlined, color: Colors.white70),
                      keyboardType: TextInputType.number,
                      validator: (value) => (value == null || value.isEmpty) ? 'Enter National ID' : null,
                    ),
                    7,
                  ),
                  const SizedBox(height: 24),
                  _buildAnimatedItem(
                    GenderSelector(
                      selectedValue: _selectedGender,
                      onChanged: (value) {
                        setState(() => _selectedGender = value);
                      },
                    ),
                    8,
                  ),
                  const SizedBox(height: 24),
                  _buildAnimatedItem(
                    GlowingTextField(
                      controller: _passwordController,
                      hintText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                      isPassword: true,
                      validator: (value) => (value == null || value.length < 8) ? 'Password must be at least 8 characters' : null,
                    ),
                    9,
                  ),
                  const SizedBox(height: 40),
                  _buildAnimatedItem(
                    authViewModel.isLoading
                        ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : PulsingActionButton(
                      label: 'CREATE ACCOUNT',
                      onTap: _register,
                    ),
                    10,
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

class GenderSelector extends StatelessWidget {
  final String? selectedValue;
  final Function(String) onChanged;

  const GenderSelector({super.key, required this.selectedValue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildGenderOption('M', Icons.male, 'Male', context)),
        const SizedBox(width: 20),
        Expanded(child: _buildGenderOption('F', Icons.female, 'Female', context)),
      ],
    );
  }

  Widget _buildGenderOption(String value, IconData icon, String label, BuildContext context) {
    final isSelected = selectedValue == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: isSelected ? const Color(0xFF636AE8).withOpacity(0.3) : const Color(0xFF636AE8).withOpacity(0.1),
          border: isSelected ? Border.all(color: const Color(0xFF636AE8), width: 1.5) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white70),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
