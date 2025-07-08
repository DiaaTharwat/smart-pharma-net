// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_pharma_net/repositories/auth_repository.dart';
import 'package:smart_pharma_net/repositories/dashboard_repository.dart';
import 'package:smart_pharma_net/repositories/medicine_repository.dart';
import 'package:smart_pharma_net/repositories/pharmacy_repository.dart';
import 'package:smart_pharma_net/services/api_service.dart';
import 'package:smart_pharma_net/viewmodels/auth_viewmodel.dart';
import 'package:smart_pharma_net/viewmodels/dashboard_viewmodel.dart';
import 'package:smart_pharma_net/viewmodels/medicine_viewmodel.dart';
import 'package:smart_pharma_net/viewmodels/pharmacy_viewmodel.dart';
import 'package:smart_pharma_net/view/screens/welcome_screen.dart';
import 'package:smart_pharma_net/repositories/exchange_repository.dart';
import 'package:smart_pharma_net/viewmodels/exchange_viewmodel.dart';
import 'package:smart_pharma_net/repositories/order_repository.dart';
import 'package:smart_pharma_net/viewmodels/order_viewmodel.dart';
import 'package:smart_pharma_net/repositories/purchase_repository.dart';
import 'package:smart_pharma_net/viewmodels/purchase_viewmodel.dart';
import 'package:smart_pharma_net/repositories/subscription_repository.dart';
import 'package:smart_pharma_net/viewmodels/subscription_viewmodel.dart';
import 'package:smart_pharma_net/repositories/chat_ai_repository.dart';
import 'package:smart_pharma_net/viewmodels/chat_ai_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiService = ApiService();
  await apiService.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>(
          create: (_) => apiService,
        ),
        Provider<MedicineRepository>(
          create: (context) => MedicineRepository(
            context.read<ApiService>(),
          ),
        ),
        ProxyProvider<ApiService, AuthRepository>(
          update: (_, apiService, __) => AuthRepository(apiService),
        ),
        ProxyProvider<ApiService, PharmacyRepository>(
          update: (_, apiService, __) => PharmacyRepository(apiService),
        ),
        ProxyProvider<ApiService, ExchangeRepository>(
          update: (_, apiService, __) => ExchangeRepository(apiService),
        ),
        ProxyProvider<ApiService, OrderRepository>(
          update: (_, apiService, __) => OrderRepository(apiService),
        ),
        ProxyProvider<ApiService, PurchaseRepository>(
          update: (_, apiService, __) => PurchaseRepository(apiService),
        ),
        ProxyProvider<ApiService, SubscriptionRepository>(
          update: (_, apiService, __) => SubscriptionRepository(apiService),
        ),
        ProxyProvider<ApiService, ChatAiRepository>(
          update: (_, apiService, __) => ChatAiRepository(apiService),
        ),
        ProxyProvider<ApiService, DashboardRepository>(
          update: (_, apiService, __) => DashboardRepository(apiService),
        ),
        ChangeNotifierProxyProvider<ChatAiRepository, ChatAiViewModel>(
          create: (context) =>
              ChatAiViewModel(context.read<ChatAiRepository>()),
          update: (context, repo, previous) =>
          previous ?? ChatAiViewModel(repo),
        ),
        ChangeNotifierProxyProvider2<AuthRepository, ApiService, AuthViewModel>(
          create: (context) => AuthViewModel(
            context.read<AuthRepository>(),
            context.read<ApiService>(),
          ),
          update: (context, authRepo, apiService, previous) =>
          previous ?? AuthViewModel(authRepo, apiService),
        ),
        ChangeNotifierProvider<PharmacyViewModel>(
          create: (context) =>
              PharmacyViewModel(
                context.read<PharmacyRepository>(),
                context.read<MedicineRepository>(),
              ),
        ),
        ChangeNotifierProvider<MedicineViewModel>(
          create: (context) => MedicineViewModel(
            context.read<MedicineRepository>(),
            context.read<PharmacyRepository>(),
          ),
        ),
        ChangeNotifierProxyProvider2<AuthViewModel, MedicineViewModel, ExchangeViewModel>(
          create: (context) => ExchangeViewModel(
            context.read<ExchangeRepository>(),
            context.read<AuthViewModel>(),
            context.read<MedicineViewModel>(),
          ),
          update: (context, authViewModel, medicineViewModel, previous) => ExchangeViewModel(
            context.read<ExchangeRepository>(),
            authViewModel,
            medicineViewModel,
          ),
        ),
        ChangeNotifierProxyProvider<AuthViewModel, OrderViewModel>(
          create: (context) => OrderViewModel(
            context.read<OrderRepository>(),
            context.read<AuthViewModel>(),
          ),
          update: (context, authViewModel, previous) => OrderViewModel(
            context.read<OrderRepository>(),
            authViewModel,
          ),
        ),
        ChangeNotifierProxyProvider<PurchaseRepository, PurchaseViewModel>(
          create: (context) => PurchaseViewModel(context.read<PurchaseRepository>()),
          update: (context, repo, previous) => previous ?? PurchaseViewModel(repo),
        ),
        ChangeNotifierProxyProvider<AuthViewModel, SubscriptionViewModel>(
          create: (context) => SubscriptionViewModel(
            context.read<SubscriptionRepository>(),
            context.read<ApiService>(),
            context.read<AuthViewModel>(),
          ),
          update: (context, authViewModel, previous) => SubscriptionViewModel(
            context.read<SubscriptionRepository>(),
            context.read<ApiService>(),
            authViewModel,
          ),
        ),
        // =================== الجزء الذي تم تصحيحه ===================
        ChangeNotifierProxyProvider<DashboardRepository, DashboardViewModel>(
          create: (context) => DashboardViewModel(context.read<DashboardRepository>()),
          update: (context, repo, previous) => previous ?? DashboardViewModel(repo),
        ),
        // ==========================================================
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Smart PharmaNet',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF636AE8),
          colorScheme:
          ColorScheme.fromSeed(seedColor: const Color(0xFF636AE8)),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
            titleTextStyle: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        home: const WelcomeScreen(),
        routes: {
          '/welcome': (context) => const WelcomeScreen(),
        });
  }
}