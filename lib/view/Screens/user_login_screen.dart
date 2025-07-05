import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_pharma_net/view/Screens/home_screen.dart';
import 'package:smart_pharma_net/viewmodels/auth_viewmodel.dart';
// Import the new common UI elements file
import 'package:smart_pharma_net/view/Widgets/common_ui_elements.dart'; //


class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> with SingleTickerProviderStateMixin { // Added TickerProviderStateMixin for animations
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false; // Still needed for internal state if not handled by GlowingTextField directly
  String? _loginErrorMessage; // For displaying login errors

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _controller.dispose(); // Dispose animation controller
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loginErrorMessage = null; // Clear previous errors
    });

    final success = await context.read<AuthViewModel>().login(
      _emailController.text,
      _passwordController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.fixed, // تم التعديل هنا
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    } else if (mounted) {
      setState(() {
        _loginErrorMessage = context.read<AuthViewModel>().errorMessage ?? 'Login failed.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_loginErrorMessage!),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.fixed, // تم التعديل هنا
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      extendBodyBehindAppBar: true, // Extend body behind custom app bar
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparent AppBar
        elevation: 0, // No shadow
        leading: IconButton( // Back button consistent with others
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'User Login',
          style: TextStyle(
            fontSize: 26, // Larger font
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(blurRadius: 10.0, color: Color(0xFF636AE8))], // Glowing effect
          ),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
      ),
      body: InteractiveParticleBackground( // Using InteractiveParticleBackground
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 50), // Spacing for AppBar
                  // Title and subtitle
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          const Text(
                            'Welcome Back, User',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 32, // Adjusted font size
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // Changed to white
                              shadows: [
                                Shadow(blurRadius: 15.0, color: Color(0xFF636AE8)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Login to your user account',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18, // Adjusted font size
                              color: Colors.white.withOpacity(0.7), // Adjusted color
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Error message
                  if (_loginErrorMessage != null)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50.withOpacity(0.2), // Darker background for error
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade400), // Adjusted color
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _loginErrorMessage!,
                                style: TextStyle(color: Colors.red.shade200), // Adjusted color
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () => setState(() => _loginErrorMessage = null),
                              color: Colors.red.shade400, // Adjusted color
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Email Field
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: GlowingTextField( // Using GlowingTextField
                        controller: _emailController,
                        hintText: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          // Basic email validation
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24), // Spacing between fields

                  // Password Field
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: GlowingTextField( // Using GlowingTextField
                        controller: _passwordController,
                        hintText: 'Password',
                        icon: Icons.lock_outline,
                        isPassword: true, // Handles obscureText and suffixIcon automatically
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 40), // Spacing before button

                  // Login Button
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: PulsingActionButton( // Using PulsingActionButton
                        label: authViewModel.isLoading ? 'Logging in...' : 'LOGIN',
                        onTap: authViewModel.isLoading ? () {} : _handleLogin, // Disable onTap when loading
                      ),
                    ),
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