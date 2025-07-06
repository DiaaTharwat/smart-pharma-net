// lib/view/Widgets/common_ui_elements.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';

// ========== بداية التعديل: تم تحديث GlowingTextField لقبول ويدجت للأيقونات ==========
class GlowingTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final Widget? prefixIcon; // تم التغيير من IconData إلى Widget
  final Widget? suffixIcon; // تم إضافة SuffixIcon
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final Function(String)? onChanged;
  final bool enabled;
  final int? maxLines;
  final bool readOnly;
  final VoidCallback? onTap;

  const GlowingTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.prefixIcon, // قيمة اختيارية الآن
    this.suffixIcon,
    this.isPassword = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.enabled = true,
    this.maxLines,
    this.readOnly = false,
    this.onTap,
  });

  @override
  State<GlowingTextField> createState() => _GlowingTextFieldState();
}

class _GlowingTextFieldState extends State<GlowingTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _isObscured = true;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isFocused = _focusNode.hasFocus;
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.text, // تم التغيير ليعكس أنه حقل نصي
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: const Color(0xFF636AE8).withOpacity(0.1),
          boxShadow: _isFocused
              ? [
            BoxShadow(
              color: const Color(0xFF636AE8).withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ]
              : [],
        ),
        child: TextFormField(
          enabled: widget.enabled,
          focusNode: _focusNode,
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.isPassword ? _isObscured : false,
          style: const TextStyle(color: Colors.white),
          validator: widget.validator,
          onChanged: widget.onChanged,
          maxLines: widget.maxLines ?? (widget.isPassword ? 1 : null),
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            errorStyle: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 14),
            prefixIcon: widget.prefixIcon != null
                ? Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: widget.prefixIcon,
            )
                : null,
            suffixIcon: widget.isPassword
                ? IconButton(
              icon: Icon(
                _isObscured
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white70,
              ),
              onPressed: () {
                setState(() {
                  _isObscured = !_isObscured;
                });
              },
            )
                : widget.suffixIcon, // استخدام suffixIcon الجديد هنا
            border: InputBorder.none,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          ),
        ),
      ),
    );
  }
}
// ========== نهاية التعديل ==========


// Custom Pulsing Action Button (unchanged from previous version)
class PulsingActionButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color? buttonColor;
  final Color? shadowBaseColor;
  final IconData? leadingIcon;

  const PulsingActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.buttonColor,
    this.shadowBaseColor,
    this.leadingIcon,
  });

  @override
  State<PulsingActionButton> createState() => _PulsingActionButtonState();
}

class _PulsingActionButtonState extends State<PulsingActionButton> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 100), value: 1.0, lowerBound: 0.95, upperBound: 1.0);
    _scaleAnimation = CurvedAnimation(parent: _scaleController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.reverse();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.forward();
    widget.onTap();
  }

  void _onTapCancel() {
    _scaleController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final Color defaultButtonColor = const Color(0xFF636AE8);
    final Color defaultShadowBaseColor = const Color(0xFF636AE8);

    final Color actualButtonColor = widget.buttonColor ?? defaultButtonColor;
    final Color actualShadowBaseColor = widget.shadowBaseColor ?? defaultShadowBaseColor;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final glow = _pulseController.value * 0.2;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: actualButtonColor.withOpacity(0.8),
                  boxShadow: [
                    BoxShadow(
                      color: actualShadowBaseColor.withOpacity(glow),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  // Use a Row to place icon and text
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Make row shrink to content
                    children: [
                      if (widget.leadingIcon != null) ...[ // If icon is provided
                        Icon(widget.leadingIcon, color: Colors.white, size: 24), // Icon color white
                        const SizedBox(width: 8), // Space between icon and text
                      ],
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// The Interactive Particle Background (unchanged from previous version)
class InteractiveParticleBackground extends StatefulWidget {
  final Widget child;
  const InteractiveParticleBackground({super.key, required this.child});

  @override
  State<InteractiveParticleBackground> createState() => _InteractiveParticleBackgroundState();
}

class _InteractiveParticleBackgroundState extends State<InteractiveParticleBackground> {
  final List<Particle> particles = [];
  Offset? touchPoint;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = context.size;
      if (size != null) {
        for (int i = 0; i < 70; i++) {
          particles.add(Particle(size));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) => setState(() => touchPoint = details.localPosition),
      onPanUpdate: (details) => setState(() => touchPoint = details.localPosition),
      onPanEnd: (_) => setState(() => touchPoint = null),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D0D1A), Color(0xFF0A0A12)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: CustomPaint(
          painter: ParticlePainter(particles: particles, touchPoint: touchPoint),
          child: widget.child,
        ),
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Offset? touchPoint;
  final Paint linePaint = Paint()
    ..color = const Color(0xFF636AE8).withOpacity(0.05)
    ..strokeWidth = 1.0;

  ParticlePainter({required this.particles, this.touchPoint});

  @override
  void paint(Canvas canvas, Size size) {
    final particlePaint = Paint();
    for (int i = 0; i < particles.length; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        if (particles[i].position.dx.isFinite && particles[i].position.dy.isFinite &&
            particles[j].position.dx.isFinite && particles[j].position.dy.isFinite) {
          final distance = (particles[i].position - particles[j].position).distance;
          if (distance < 120) {
            canvas.drawLine(particles[i].position, particles[j].position, linePaint);
          }
        }
      }
    }

    for (var p in particles) {
      particlePaint.color = p.color;
      canvas.drawCircle(p.position, p.radius, particlePaint);
      p.update(size, touchPoint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Particle {
  late Offset position;
  late Color color;
  late double radius;
  late Offset velocity;
  final Random _random = Random();

  Particle(Size bounds) {
    position = Offset(_random.nextDouble() * bounds.width, _random.nextDouble() * bounds.height);
    color = const Color(0xFF636AE8).withOpacity(_random.nextDouble() * 0.5 + 0.2);
    radius = _random.nextDouble() * 2 + 1;
    velocity = Offset(_random.nextDouble() * 1.0 - 0.5, _random.nextDouble() * 1.0 - 0.5);
  }

  void update(Size bounds, Offset? touchPoint) {
    if (touchPoint != null) {
      final distance = (position - touchPoint).distance;
      if (distance < 200) {
        final direction = (position - touchPoint).scale(1 / (distance + 0.1), 1 / (distance + 0.1));
        velocity = (velocity + direction * 0.1).scale(0.99, 0.99);
      }
    }

    position += velocity;

    if (position.dx < 0 || position.dx > bounds.width) {
      velocity = Offset(-velocity.dx, velocity.dy);
    }
    if (position.dy < 0 || position.dy > bounds.height) {
      velocity = Offset(velocity.dx, -velocity.dy);
    }

    if (velocity.distance > 1.5) {
      velocity = velocity.scale(0.95, 0.95);
    }
  }
}