// lib/view/Screens/pricing_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_pharma_net/viewmodels/subscription_viewmodel.dart';
import 'package:smart_pharma_net/services/api_service.dart';
// Import the new common UI elements file
import 'package:smart_pharma_net/view/Widgets/common_ui_elements.dart';


class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> with SingleTickerProviderStateMixin {
  bool _isMonthly = true;
  late final ApiService _apiService;
  bool _isLoggedInAsPharmacy = false;
  String? _pharmacyName;
  String? _currentSubscriptionType; // NEW: To store the locally known subscription type
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
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
    );
    _controller.forward();


    WidgetsBinding.instance.addPostFrameCallback((_) {
      _apiService = Provider.of<ApiService>(context, listen: false);
      _checkLoginStatusAndSubscription(); // Modified to check subscription too
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatusAndSubscription() async {
    final String? token = await _apiService.getAccessToken();
    final String? pharmacyName = await _apiService.getPharmacyName();
    final String? pharmacyId = await _apiService.getPharmacyId();
    // MODIFIED: Added 'await' to correctly get the value from the Future
    final String? subscriptionType = await _apiService.getSubscriptionType();

    setState(() {
      _isLoggedInAsPharmacy = token != null && pharmacyName != null && pharmacyId != null;
      _pharmacyName = pharmacyName;
      _currentSubscriptionType = subscriptionType; // Set local subscription type
    });
  }

  // New: Function to show the payment modal
  Future<void> _showPaymentModal(String selectedPlanTitle, String selectedPlanType, String price) async {
    String cardNumber = '';
    String expiryDate = '';
    String cvv = '';
    String nameOnCard = '';
    bool isProcessingPayment = false;

    // NEW: Handle overlap warning (frontend-only logic)
    if (_currentSubscriptionType != null &&
        _currentSubscriptionType!.isNotEmpty &&
        _currentSubscriptionType! != 'Free' &&
        _currentSubscriptionType! != selectedPlanType) {
      final bool? confirmChange = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF0F0F1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Change Subscription?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(
            'You are currently subscribed to the "$_currentSubscriptionType" plan. Subscribing to "$selectedPlanTitle" will replace your current subscription . Do you wish to continue?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Continue', style: TextStyle(color: Color(0xFF636AE8)))),
          ],
        ),
      );
      if (confirmChange != true) {
        return; // User cancelled the change
      }
    }


    await showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext dialogContext) {
        return StatefulBuilder( // Use StatefulBuilder to manage internal state of the dialog
          builder: (context, setState) {
            return Dialog(
              backgroundColor: const Color(0xFF0F0F1A), // Dark background for dialog
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: const Color(0xFF636AE8).withOpacity(0.5)), // Border
              ),
              elevation: 16,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView( // Allow scrolling for smaller screens
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Upgrade to $selectedPlanTitle Plan',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white), // White text
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70), // White close icon
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF636AE8).withOpacity(0.2), // Subtle background
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF636AE8).withOpacity(0.3)), // Border
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Plan:', style: TextStyle(color: Colors.white.withOpacity(0.7))), // Lighter text
                                Text(selectedPlanTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), // White text
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Billing:', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                                Text(_isMonthly ? 'Monthly' : 'Yearly', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)), // White text
                                Text('\$$price', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50))), // Green price
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      GlowingTextField( // Using GlowingTextField
                        controller: TextEditingController(text: cardNumber), // Needs controller
                        hintText: 'Card Number (XXXX XXXX XXXX XXXX)',
                        icon: Icons.credit_card,
                        keyboardType: TextInputType.number,
                        onChanged: (value) { cardNumber = value; },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GlowingTextField( // Using GlowingTextField
                              controller: TextEditingController(text: expiryDate), // Needs controller
                              hintText: 'Expiry Date (MM/YY)',
                              icon: Icons.calendar_today,
                              keyboardType: TextInputType.datetime,
                              onChanged: (value) { expiryDate = value; },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GlowingTextField( // Using GlowingTextField
                              controller: TextEditingController(text: cvv), // Needs controller
                              hintText: 'CVV (123)',
                              icon: Icons.lock,
                              keyboardType: TextInputType.number,
                              isPassword: true, // For CVV
                              onChanged: (value) { cvv = value; },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GlowingTextField( // Using GlowingTextField
                        controller: TextEditingController(text: nameOnCard), // Needs controller
                        hintText: 'Name on Card (John Doe)',
                        icon: Icons.person,
                        onChanged: (value) { nameOnCard = value; },
                      ),
                      const SizedBox(height: 24),
                      PulsingActionButton( // Using PulsingActionButton
                        label: isProcessingPayment ? 'Processing Payment...' : 'Pay \$$price',
                        onTap: isProcessingPayment
                            ? () {}
                            : () async {
                          // Basic validation (can be enhanced)
                          if (cardNumber.isEmpty || expiryDate.isEmpty || cvv.isEmpty || nameOnCard.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill all payment details.'), backgroundColor: Colors.red, behavior: SnackBarBehavior.fixed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10)))), // تم التعديل هنا
                            );
                            return;
                          }

                          setState(() {
                            isProcessingPayment = true;
                          });

                          final subscriptionViewModel = Provider.of<SubscriptionViewModel>(dialogContext, listen: false);

                          // Simulate payment processing delay (as in web version)
                          await Future.delayed(const Duration(seconds: 1));

                          final success = await subscriptionViewModel.subscribeToPlan(selectedPlanType);

                          setState(() {
                            isProcessingPayment = false;
                          });

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Successfully subscribed to $selectedPlanTitle plan!'),
                                backgroundColor: Colors.green, behavior: SnackBarBehavior.fixed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))), // تم التعديل هنا
                              ),
                            );
                            _checkLoginStatusAndSubscription(); // Update local subscription status
                            Navigator.of(context).pop(); // Close modal on success
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to subscribe: ${subscriptionViewModel.error}'),
                                backgroundColor: Colors.red, behavior: SnackBarBehavior.fixed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))), // تم التعديل هنا
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock, color: Colors.white.withOpacity(0.7), size: 18), // Lighter, slightly larger icon
                          const SizedBox(width: 8),
                          Text('Payments are secure and encrypted', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)), // Lighter, slightly larger text
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // NEW: Function to handle local cancellation
  Future<void> _handleCancelSubscription() async {
    final bool? confirmCancel = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F0F1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Confirm Cancellation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to cancel your current subscription ?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep', style: TextStyle(color: Colors.white70))),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Cancel ', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirmCancel == true) {
      context.read<SubscriptionViewModel>().clearLocalSubscription();
      _checkLoginStatusAndSubscription(); // Refresh UI after local clear
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription status cleared.'),
            backgroundColor: Colors.orangeAccent,
            behavior: SnackBarBehavior.fixed,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
          ),
        );
      }
    }
  }

  Widget _buildPlanCard({
    required String title,
    required String monthlyPrice,
    required String yearlyPrice,
    required String description,
    required List<String> features,
    bool isPopular = false,
    required String planType, // "Pro", "Max", or "Free"
  }) {
    final bool isCurrentPlanLocally = _currentSubscriptionType == planType; // NEW: Check local current plan
    final String price = _isMonthly ? monthlyPrice : yearlyPrice;
    final String billingPeriod = _isMonthly ? '/month' : '/year';

    return Container( // Changed from Card to Container for consistent styling
      margin: const EdgeInsets.all(12.0), // Increased margin
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1A), // Dark background
        borderRadius: BorderRadius.circular(20), // More rounded
        border: isPopular ? Border.all(color: const Color(0xFF636AE8), width: 2) : Border.all(color: const Color(0xFF636AE8).withOpacity(0.3)), // Border based on popular
        boxShadow: [
          if (isPopular) BoxShadow(
            color: const Color(0xFF636AE8).withOpacity(0.4), // Stronger glow for popular
            blurRadius: 20,
            spreadRadius: 5,
          ) else BoxShadow(
            color: const Color(0xFF636AE8).withOpacity(0.15), // Subtle glow
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPopular)
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), // Increased padding
                  decoration: BoxDecoration(
                    color: const Color(0xFF636AE8), // Blue for popular tag
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Popular',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), // White, bold text
                  ),
                ),
              ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 26, // Larger font
                fontWeight: FontWeight.bold,
                color: Colors.white, // White text
                shadows: [Shadow(blurRadius: 8.0, color: Color(0xFF636AE8))], // Glowing effect
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '\$$price',
                  style: const TextStyle(
                    fontSize: 56, // Larger font
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50), // Green for price
                  ),
                ),
                Text(
                  billingPeriod,
                  style: TextStyle(
                    fontSize: 20, // Larger font
                    color: Colors.white.withOpacity(0.7), // Lighter color
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7), // Lighter color
              ),
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: features
                  .map((feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0), // Increased padding
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.greenAccent, size: 24), // Brighter green, larger icon
                    const SizedBox(width: 10), // Increased spacing
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(fontSize: 16, color: Colors.white), // White text
                      ),
                    ),
                  ],
                ),
              ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            // NEW: Conditional buttons based on local subscription status
            isCurrentPlanLocally
                ? Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton( // Styled like PulsingActionButton but static
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF636AE8).withOpacity(0.3), // Darker, subtle color
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)), // More rounded
                      side: BorderSide(color: const Color(0xFF636AE8).withOpacity(0.5)), // Border
                      elevation: 0,
                    ),
                    child: const Text('Current Plan', style: TextStyle(color: Color(0xFF636AE8), fontSize: 16, fontWeight: FontWeight.bold)), // Blue text
                  ),
                ),
                if (planType != 'Free' && _isLoggedInAsPharmacy) // Only show cancel for paid plans
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleCancelSubscription,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withOpacity(0.8), // Red for cancel
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                          elevation: 5,
                          shadowColor: Colors.redAccent.withOpacity(0.6),
                        ),
                        child: const Text('Cancel Subscription ', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
              ],
            )
                : SizedBox(
              width: double.infinity,
              child: Consumer<SubscriptionViewModel>(
                builder: (context, viewModel, child) {
                  return PulsingActionButton( // Using PulsingActionButton
                    label: viewModel.isLoading
                        ? 'Loading...'
                        : (_isLoggedInAsPharmacy
                        ? 'Upgrade to $title'
                        : 'Login as Pharmacy to Subscribe'),
                    onTap: viewModel.isLoading || !_isLoggedInAsPharmacy
                        ? () {} // Disable onTap if loading or not logged in
                        : () async {
                      await _showPaymentModal(title, planType, price);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Extend body behind custom app bar
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparent AppBar
        elevation: 0, // No shadow
        leading: IconButton( // Back button consistent with others
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Pricing Plans', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 10.0, color: Color(0xFF636AE8))])), // Glowing title
      ),
      body: InteractiveParticleBackground( // Using InteractiveParticleBackground
        child: Column( // Use Column to fix header
          children: [
            // Custom AppBar content (Fixed Header)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 16), // Adjust padding as needed for fixed header
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton( // Back button consistent with others
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text('Pricing Plans', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 10.0, color: Color(0xFF636AE8))]), textAlign: TextAlign.center), // Title
                    ),
                    SizedBox(width: 48), // Space for leading icon
                  ],
                ),
              ),
            ),
            Expanded( // Remaining content is scrollable
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), // Adjusted top padding to 0, since header is now separate
                child: Column(
                  children: [
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          children: [
                            const Text(
                              'Simple, transparent pricing for pharmacies of all sizes',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w500), // White text
                            ),
                            const SizedBox(height: 24),
                            Container( // Wrap switch row in container for styling
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF636AE8).withOpacity(0.2), // Subtle background
                                borderRadius: BorderRadius.circular(30), // Rounded corners
                                border: Border.all(color: const Color(0xFF636AE8).withOpacity(0.3)), // Border
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min, // To make container wrap content
                                children: [
                                  Text(
                                    'Monthly',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _isMonthly ? Colors.white : Colors.white.withOpacity(0.7), // White for active, lighter for inactive
                                      fontSize: 16,
                                    ),
                                  ),
                                  Switch(
                                    value: !_isMonthly,
                                    onChanged: (value) {
                                      setState(() {
                                        _isMonthly = !value;
                                      });
                                    },
                                    activeColor: const Color(0xFF636AE8), // Blue for active
                                    inactiveThumbColor: Colors.grey.shade600, // Dark grey for inactive thumb
                                    inactiveTrackColor: Colors.grey.shade800, // Dark grey for inactive track
                                  ),
                                  Text(
                                    'Yearly',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: !_isMonthly ? Colors.white : Colors.white.withOpacity(0.7), // White for active, lighter for inactive
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            _isLoggedInAsPharmacy
                                ? Text(
                              'Logged in as Pharmacy: $_pharmacyName',
                              textAlign: TextAlign.center, // Center text
                              style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold), // Brighter green
                            )
                                : Text(
                              'You need to login as a pharmacy to subscribe to plans.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold), // Brighter red
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 16.0, // Space between cards
                              runSpacing: 16.0, // Space between rows of cards
                              children: [
                                _buildPlanCard(
                                  title: 'Free',
                                  monthlyPrice: '0',
                                  yearlyPrice: '0',
                                  description: 'Perfect for small pharmacies just getting started',
                                  features: [
                                    'Up to 50 products',
                                    'Basic inventory management',
                                    'Email support',
                                  ],
                                  planType: 'Free',
                                ),
                                _buildPlanCard(
                                  title: 'Pro',
                                  monthlyPrice: '29',
                                  yearlyPrice: '25',
                                  description: 'For growing pharmacies with more needs',
                                  features: [
                                    'Up to 500 products',
                                    'Advanced inventory management',
                                    'Priority email support',
                                    'Basic analytics',
                                  ],
                                  isPopular: true,
                                  planType: 'Pro',
                                ),
                                _buildPlanCard(
                                  title: 'Max',
                                  monthlyPrice: '99',
                                  yearlyPrice: '79',
                                  description: 'For large pharmacies with complex needs',
                                  features: [
                                    'Unlimited products',
                                    'Premium inventory management',
                                    '24/7 phone & email support',
                                    'Advanced analytics',
                                    'API access',
                                  ],
                                  planType: 'Max',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    const Text(
                      'Frequently asked questions',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(blurRadius: 10.0, color: Color(0xFF636AE8))]), // Glowing title
                    ),
                    const SizedBox(height: 24),
                    ExpansionTile(
                      title: const Text('Can I change plans later?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), // White, larger text
                      iconColor: Colors.white, // White icon
                      collapsedIconColor: Colors.white70, // Lighter icon when collapsed
                      backgroundColor: const Color(0xFF0F0F1A), // Dark background for expanded tile
                      collapsedBackgroundColor: const Color(0xFF0F0F1A), // Dark background for collapsed tile
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: const Color(0xFF636AE8).withOpacity(0.3))), // Rounded border
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('Yes, you can upgrade or downgrade your plan at any time.', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16)), // White text
                        ),
                      ],
                    ),
                    const SizedBox(height: 16), // Spacing between FAQ items
                    ExpansionTile(
                      title: const Text('What payment methods do you accept?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      iconColor: Colors.white,
                      collapsedIconColor: Colors.white70,
                      backgroundColor: const Color(0xFF0F0F1A),
                      collapsedBackgroundColor: const Color(0xFF0F0F1A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: const Color(0xFF636AE8).withOpacity(0.3))),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('We accept all major credit cards and PayPal.', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ExpansionTile(
                      title: const Text('Is there a contract or long-term commitment?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      iconColor: Colors.white,
                      collapsedIconColor: Colors.white70,
                      backgroundColor: const Color(0xFF0F0F1A),
                      collapsedBackgroundColor: const Color(0xFF0F0F1A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: const Color(0xFF636AE8).withOpacity(0.3))),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('No, all plans are month-to-month or year-to-year with no long-term commitment.', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ExpansionTile(
                      title: const Text('Do you offer discounts for non-profits?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      iconColor: Colors.white,
                      collapsedIconColor: Colors.white70,
                      backgroundColor: const Color(0xFF0F0F1A),
                      collapsedBackgroundColor: const Color(0xFF0F0F1A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: const Color(0xFF636AE8).withOpacity(0.3))),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('Yes, we offer special pricing for non-profit organizations. Please contact us for more information.', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48), // Padding at the bottom
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}