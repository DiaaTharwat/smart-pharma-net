import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_pharma_net/viewmodels/subscription_viewmodel.dart';
import 'package:smart_pharma_net/services/api_service.dart';
import 'package:smart_pharma_net/view/Widgets/common_ui_elements.dart';
import 'package:smart_pharma_net/viewmodels/auth_viewmodel.dart'; // Import AuthViewModel

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> with SingleTickerProviderStateMixin {
  bool _isMonthly = true;
  String? _currentSubscriptionType;
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
      _checkSubscriptionStatus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkSubscriptionStatus() async {
    final apiService = context.read<ApiService>();
    final subType = await apiService.getSubscriptionType();
    if (mounted) {
      setState(() {
        _currentSubscriptionType = subType;
      });
    }
  }

  Future<void> _showPaymentModal(String selectedPlanTitle, String selectedPlanType, String price) async {
    String cardNumber = '';
    String expiryDate = '';
    String cvv = '';
    String nameOnCard = '';
    bool isProcessingPayment = false;

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
        return;
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: const Color(0xFF0F0F1A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: const Color(0xFF636AE8).withOpacity(0.5)),
              ),
              elevation: 16,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Upgrade to $selectedPlanTitle Plan',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70),
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
                          color: const Color(0xFF636AE8).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF636AE8).withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Plan:', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                                Text(selectedPlanTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                                const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                Text('\$$price', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      GlowingTextField(
                        controller: TextEditingController(text: cardNumber),
                        hintText: 'Card Number (XXXX XXXX XXXX XXXX)',
                        prefixIcon: const Icon(Icons.credit_card, color: Colors.white70),
                        keyboardType: TextInputType.number,
                        onChanged: (value) { cardNumber = value; },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GlowingTextField(
                              controller: TextEditingController(text: expiryDate),
                              hintText: 'Expiry Date (MM/YY)',
                              prefixIcon: const Icon(Icons.calendar_today, color: Colors.white70),
                              keyboardType: TextInputType.datetime,
                              onChanged: (value) { expiryDate = value; },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GlowingTextField(
                              controller: TextEditingController(text: cvv),
                              hintText: 'CVV (123)',
                              prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                              keyboardType: TextInputType.number,
                              isPassword: true,
                              onChanged: (value) { cvv = value; },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GlowingTextField(
                        controller: TextEditingController(text: nameOnCard),
                        hintText: 'Name on Card (John Doe)',
                        prefixIcon: const Icon(Icons.person, color: Colors.white70),
                        onChanged: (value) { nameOnCard = value; },
                      ),
                      const SizedBox(height: 24),
                      PulsingActionButton(
                        label: isProcessingPayment ? 'Processing Payment...' : 'Pay \$$price',
                        onTap: isProcessingPayment
                            ? () {}
                            : () async {
                          if (cardNumber.isEmpty || expiryDate.isEmpty || cvv.isEmpty || nameOnCard.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill all payment details.'), backgroundColor: Colors.red, behavior: SnackBarBehavior.fixed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
                            );
                            return;
                          }

                          setState(() {
                            isProcessingPayment = true;
                          });

                          final subscriptionViewModel = Provider.of<SubscriptionViewModel>(dialogContext, listen: false);

                          await Future.delayed(const Duration(seconds: 1));

                          final success = await subscriptionViewModel.subscribeToPlan(selectedPlanType);

                          setState(() {
                            isProcessingPayment = false;
                          });

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Successfully subscribed to $selectedPlanTitle plan!'),
                                backgroundColor: Colors.green, behavior: SnackBarBehavior.fixed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                              ),
                            );
                            _checkSubscriptionStatus();
                            Navigator.of(context).pop();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to subscribe: ${subscriptionViewModel.error}'),
                                backgroundColor: Colors.red, behavior: SnackBarBehavior.fixed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock, color: Colors.white.withOpacity(0.7), size: 18),
                          const SizedBox(width: 8),
                          Text('Payments are secure and encrypted', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
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
      _checkSubscriptionStatus();
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
    required String planType,
  }) {
    final authViewModel = context.watch<AuthViewModel>();
    final bool isCurrentPlanLocally = _currentSubscriptionType == planType;
    final String price = _isMonthly ? monthlyPrice : yearlyPrice;
    final String billingPeriod = _isMonthly ? '/month' : '/year';

    return Container(
      margin: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1A),
        borderRadius: BorderRadius.circular(20),
        border: isPopular ? Border.all(color: const Color(0xFF636AE8), width: 2) : Border.all(color: const Color(0xFF636AE8).withOpacity(0.3)),
        boxShadow: [
          if (isPopular) BoxShadow(
            color: const Color(0xFF636AE8).withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 5,
          ) else BoxShadow(
            color: const Color(0xFF636AE8).withOpacity(0.15),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF636AE8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Popular', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
            Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(blurRadius: 8.0, color: Color(0xFF636AE8))])),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('\$$price', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50))),
                Text(billingPeriod, style: TextStyle(fontSize: 20, color: Colors.white.withOpacity(0.7))),
              ],
            ),
            const SizedBox(height: 16),
            Text(description, style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7))),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: features
                  .map((feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.greenAccent, size: 24),
                    const SizedBox(width: 10),
                    Expanded(child: Text(feature, style: const TextStyle(fontSize: 16, color: Colors.white))),
                  ],
                ),
              )).toList(),
            ),
            const SizedBox(height: 24),
            isCurrentPlanLocally && planType != 'Free'
                ? Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF636AE8).withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      side: BorderSide(color: const Color(0xFF636AE8).withOpacity(0.5)),
                      elevation: 0,
                    ),
                    child: const Text('Current Plan', style: TextStyle(color: Color(0xFF636AE8), fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                if (authViewModel.canActAsPharmacy)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleCancelSubscription,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withOpacity(0.8),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                          elevation: 5,
                          shadowColor: Colors.redAccent.withOpacity(0.6),
                        ),
                        child: const Text('Cancel Subscription', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
              ],
            )
                : SizedBox(
              width: double.infinity,
              child: Consumer<SubscriptionViewModel>(
                builder: (context, viewModel, child) {
                  return PulsingActionButton(
                    label: viewModel.isLoading
                        ? 'Loading...'
                        : (authViewModel.canActAsPharmacy
                        ? 'Upgrade to $title'
                        : 'Select a Pharmacy to Subscribe'),
                    onTap: viewModel.isLoading || !authViewModel.canActAsPharmacy
                        ? () {
                      if (!authViewModel.canActAsPharmacy) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select a pharmacy from the main menu to manage subscriptions.'), backgroundColor: Colors.orangeAccent)
                        );
                      }
                    }
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
    final authViewModel = context.watch<AuthViewModel>();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: InteractiveParticleBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        Text('Pricing Plans', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(blurRadius: 10.0, color: Color(0xFF636AE8))])),
                        const SizedBox(height: 16),
                        const Text(
                          'Simple, transparent pricing for pharmacies of all sizes',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF636AE8).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: const Color(0xFF636AE8).withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Monthly', style: TextStyle(fontWeight: FontWeight.bold, color: _isMonthly ? Colors.white : Colors.white.withOpacity(0.7), fontSize: 16)),
                              Switch(
                                value: !_isMonthly,
                                onChanged: (value) {
                                  setState(() {
                                    _isMonthly = !value;
                                  });
                                },
                                activeColor: const Color(0xFF636AE8),
                                inactiveThumbColor: Colors.grey.shade600,
                                inactiveTrackColor: Colors.grey.shade800,
                              ),
                              Text('Yearly', style: TextStyle(fontWeight: FontWeight.bold, color: !_isMonthly ? Colors.white : Colors.white.withOpacity(0.7), fontSize: 16)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        authViewModel.canActAsPharmacy
                            ? Text(
                          'Managing subscription for: ${authViewModel.activePharmacyName}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold),
                        )
                            : Text(
                          'Please select a pharmacy from the menu to manage subscriptions.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 16.0,
                          runSpacing: 16.0,
                          children: [
                            _buildPlanCard(title: 'Free', monthlyPrice: '0', yearlyPrice: '0', description: 'Perfect for small pharmacies just getting started', features: ['Up to 50 products', 'Basic inventory management', 'Email support'], planType: 'Free'),
                            _buildPlanCard(title: 'Pro', monthlyPrice: '29', yearlyPrice: '25', description: 'For growing pharmacies with more needs', features: ['Up to 500 products', 'Advanced inventory management', 'Priority email support', 'Basic analytics'], isPopular: true, planType: 'Pro'),
                            _buildPlanCard(title: 'Max', monthlyPrice: '99', yearlyPrice: '79', description: 'For large pharmacies with complex needs', features: ['Unlimited products', 'Premium inventory management', '24/7 phone & email support', 'Advanced analytics', 'API access'], planType: 'Max'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                const Text('Frequently asked questions', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(blurRadius: 10.0, color: Color(0xFF636AE8))])),
                const SizedBox(height: 24),
                ExpansionTile(
                  title: const Text('Can I change plans later?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  iconColor: Colors.white,
                  collapsedIconColor: Colors.white70,
                  backgroundColor: const Color(0xFF0F0F1A),
                  collapsedBackgroundColor: const Color(0xFF0F0F1A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: const Color(0xFF636AE8).withOpacity(0.3))),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Yes, you can upgrade or downgrade your plan at any time.', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
