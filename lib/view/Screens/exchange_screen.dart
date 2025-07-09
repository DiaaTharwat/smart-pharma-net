// lib/view/exchange/exchange_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // ✨ تم إضافة هذه المكتبة لتهيئة شكل التاريخ
import 'package:provider/provider.dart';
import 'package:smart_pharma_net/models/exchange_medicine_model.dart';
import 'package:smart_pharma_net/view/Screens/menu_bar_screen.dart';
import 'package:smart_pharma_net/viewmodels/auth_viewmodel.dart';
import 'package:smart_pharma_net/viewmodels/exchange_viewmodel.dart';
import 'package:smart_pharma_net/view/Widgets/notification_icon.dart';
import 'package:smart_pharma_net/view/Screens/home_screen.dart';
import 'package:smart_pharma_net/view/Widgets/common_ui_elements.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ExchangeScreen extends StatefulWidget {
  const ExchangeScreen({Key? key}) : super(key: key);

  @override
  State<ExchangeScreen> createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends State<ExchangeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
  GlobalKey<ScaffoldMessengerState>();

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  File? _selectedImage;
  final TextRecognizer _textRecognizer = TextRecognizer();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initSpeech();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPharmacyAccessAndLoadMedicines();
    });
  }

  void _setupAnimations() {
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

  void _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (error) => print('Speech Recognition Error: $error'),
        onStatus: (status) {
          if (mounted) {
            setState(() {
              _isListening = _speechToText.isListening;
            });
            if (status == 'notListening' || status == 'done') {
              if (mounted) {
                setState(() => _isListening = false);
              }
            }
          }
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      print("Speech initialization failed: $e");
      if (mounted) setState(() => _speechEnabled = false);
    }
  }

  void _startListening() {
    if (_speechEnabled && !_isListening) {
      if (mounted) setState(() => _isListening = true);
      _speechToText.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _searchController.text = result.recognizedWords;
              _searchController.selection = TextSelection.fromPosition(
                TextPosition(offset: _searchController.text.length),
              );
              _triggerSearch(result.recognizedWords);
            });
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  void _stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      if (mounted) {
        setState(() => _isListening = false);
      }
    }
  }

  void _pickImageAndRecognizeText() async {
    final exchangeViewModel = context.read<ExchangeViewModel>();

    if (exchangeViewModel.allExchangeMedicineNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
            Text("Exchange list is not loaded yet. Please try again.")),
      );
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? imageFile =
      await picker.pickImage(source: ImageSource.gallery);
      if (imageFile == null) return;
      if (mounted) setState(() => _selectedImage = File(imageFile.path));

      final InputImage inputImage = InputImage.fromFilePath(imageFile.path);
      final RecognizedText recognizedText =
      await _textRecognizer.processImage(inputImage);
      final String fullTextFromImage = recognizedText.text;

      if (fullTextFromImage.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not recognize any text.")),
        );
        _clearImageSearch();
        return;
      }

      final List<String> medicineNames =
          exchangeViewModel.allExchangeMedicineNames;
      final BestMatch bestMatch =
      StringSimilarity.findBestMatch(fullTextFromImage, medicineNames);

      if (bestMatch.bestMatch.rating != null &&
          bestMatch.bestMatch.rating! > 0.2) {
        final String foundMedicineName = bestMatch.bestMatch.target!;
        _searchController.text = foundMedicineName;
        _searchController.selection = TextSelection.fromPosition(
            TextPosition(offset: _searchController.text.length));
        _triggerSearch(foundMedicineName);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not find a matching medicine.")),
        );
        _clearImageSearch();
      }
    } catch (e) {
      print("Error picking image or recognizing text: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e")),
      );
      _clearImageSearch();
    }
  }

  void _clearImageSearch() {
    setState(() {
      _selectedImage = null;
      _searchController.clear();
      _triggerSearch('');
    });
  }

  void _triggerSearch(String query) {
    context.read<ExchangeViewModel>().setSearchQuery(query);
  }

  Future<void> _checkPharmacyAccessAndLoadMedicines() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    if (!authViewModel.canActAsPharmacy) {
    } else {
      context.read<ExchangeViewModel>().loadExchangeMedicines();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    _textRecognizer.close();
    _speechToText.cancel();
    super.dispose();
  }

  void _handleBackNavigation() {
    Navigator.pop(context);
  }

  Future<void> _logoutFromPharmacy() async {
    final authViewModel = context.read<AuthViewModel>();
    try {
      await authViewModel.restoreAdminSession();
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Logged out from pharmacy session.'),
            backgroundColor: Color(0xFF636AE8),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10))),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Failed to logout from pharmacy: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10))),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return WillPopScope(
      onWillPop: () async {
        _handleBackNavigation();
        return false;
      },
      child: ScaffoldMessenger(
        key: _scaffoldMessengerKey,
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 0,
          ),
          body: InteractiveParticleBackground(
            child: Consumer<ExchangeViewModel>(
              builder: (context, exchangeViewModel, child) {
                if (exchangeViewModel.exchangeOrderPlacedSuccessfully) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Exchange order placed successfully!'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                    );
                    exchangeViewModel.resetExchangeOrderPlacedSuccess();
                  });
                }

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                      child: SafeArea(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_ios_new,
                                      color: Colors.white, size: 28),
                                  onPressed: _handleBackNavigation,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.menu,
                                      color: Colors.white, size: 28),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                        const MenuBarScreen(),
                                      ),
                                    );
                                  },
                                ),
                                Expanded(
                                  child: Text(
                                    authViewModel.canActAsPharmacy
                                        ? 'Exchange for ${authViewModel.activePharmacyName}'
                                        : 'Medicine Exchange',
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                            blurRadius: 10.0,
                                            color: Color(0xFF636AE8))
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh,
                                      color: Colors.white, size: 28),
                                  onPressed: () => context
                                      .read<ExchangeViewModel>()
                                      .loadExchangeMedicines(),
                                ),
                                const NotificationIcon(),
                                if (authViewModel.isAdmin &&
                                    authViewModel.isPharmacy)
                                  IconButton(
                                    icon: const Icon(Icons.exit_to_app,
                                        color: Colors.white, size: 28),
                                    tooltip: 'Logout from Pharmacy',
                                    onPressed: _logoutFromPharmacy,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: GlowingTextField(
                                  controller: _searchController,
                                  hintText: _isListening
                                      ? 'Listening...'
                                      : 'Search medicines or pharmacies...',
                                  onChanged: (value) {
                                    if (_selectedImage == null) {
                                      _triggerSearch(value);
                                    }
                                  },
                                  prefixIcon: _selectedImage != null
                                      ? Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: ClipRRect(
                                      borderRadius:
                                      BorderRadius.circular(8),
                                      child: Image.file(
                                        _selectedImage!,
                                        height: 30,
                                        width: 30,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                      : const Icon(Icons.search,
                                      color: Color(0xFF636AE8)),
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_selectedImage != null)
                                        IconButton(
                                          icon: const Icon(Icons.close,
                                              color: Colors.white70),
                                          onPressed: _clearImageSearch,
                                        ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.mic,
                                          color: _isListening
                                              ? Colors.redAccent
                                              : Colors.white70,
                                        ),
                                        onPressed: _speechEnabled
                                            ? (_isListening
                                            ? _stopListening
                                            : _startListening)
                                            : null,
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.camera_alt_outlined,
                                            color: Colors.white70),
                                        onPressed: _pickImageAndRecognizeText,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          if (exchangeViewModel.isLoading) {
                            return const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF636AE8)),
                              ),
                            );
                          }
                          if (exchangeViewModel.errorMessage != null) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 60,
                                      color: Colors.red.shade400,
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'Error: ${exchangeViewModel.errorMessage}',
                                      style: TextStyle(
                                          color: Colors.red.shade200,
                                          fontSize: 17),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 20),
                                    PulsingActionButton(
                                      label: 'Retry',
                                      onTap: () => exchangeViewModel
                                          .loadExchangeMedicines(),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final displayedMedicines =
                              exchangeViewModel.exchangeMedicines;

                          if (displayedMedicines.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 80,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    _searchController.text.isNotEmpty
                                        ? 'No matching medicines found.'
                                        : 'No medicines available for exchange right now.',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (_searchController.text.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      'Try a different search term or clear the search.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                  const SizedBox(height: 20),
                                  PulsingActionButton(
                                    label: 'Refresh List',
                                    onTap: () => exchangeViewModel
                                        .loadExchangeMedicines(),
                                  ),
                                ],
                              ),
                            );
                          }

                          final screenPadding = const EdgeInsets.all(20.0);
                          final horizontalSpacing = 20.0;
                          final verticalSpacing = 20.0;

                          return RefreshIndicator(
                            onRefresh: () =>
                                exchangeViewModel.loadExchangeMedicines(),
                            color: const Color(0xFF636AE8),
                            backgroundColor: Colors.white.withOpacity(0.8),
                            child: SingleChildScrollView(
                              padding: screenPadding,
                              child: Wrap(
                                spacing: horizontalSpacing,
                                runSpacing: verticalSpacing,
                                alignment: WrapAlignment.start,
                                children: displayedMedicines.map((medicine) {
                                  final double screenWidth =
                                      MediaQuery.of(context).size.width;
                                  final double totalHorizontalPadding =
                                      screenPadding.left + screenPadding.right;
                                  final double totalSpacing =
                                      horizontalSpacing * 2;
                                  final double cardWidth = (screenWidth >
                                      1200)
                                      ? (screenWidth -
                                      totalHorizontalPadding -
                                      totalSpacing) /
                                      3
                                      : (screenWidth > 800)
                                      ? (screenWidth -
                                      totalHorizontalPadding -
                                      horizontalSpacing) /
                                      2
                                      : (screenWidth -
                                      totalHorizontalPadding);
                                  return _buildExchangeMedicineCard(
                                      medicine, cardWidth);
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showMapDialog(String pharmacyName, String lat, String lon) {
    final double? latitude = double.tryParse(lat);
    final double? longitude = double.tryParse(lon);

    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Invalid location data for this pharmacy.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: const Color(0xFF636AE8).withOpacity(0.5)),
        ),
        title: Text(
          pharmacyName,
          style:
          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(latitude, longitude),
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.smart_pharma_net',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 80.0,
                    height: 80.0,
                    point: LatLng(latitude, longitude),
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.redAccent,
                      size: 40.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child:
            const Text('Close', style: TextStyle(color: Color(0xFF636AE8))),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeMedicineCard(
      ExchangeMedicineModel medicine, double cardWidth) {
    Widget imageWidget;
    if (medicine.imageUrl != null &&
        medicine.imageUrl!.isNotEmpty &&
        Uri.tryParse(medicine.imageUrl!)?.hasAbsolutePath == true) {
      imageWidget = Image.network(
        medicine.imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 140,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF636AE8)),
              ));
        },
        errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.medication_liquid_outlined,
            size: 90,
            color: Color(0xFF636AE8)),
      );
    } else {
      imageWidget = const Icon(Icons.medication_liquid_outlined,
          size: 90, color: Color(0xFF636AE8));
    }

    return Container(
      width: cardWidth,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF636AE8).withOpacity(0.3), width: 1.0),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF636AE8).withOpacity(0.15),
              blurRadius: 15,
              spreadRadius: 2),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => _showBuyMedicineModal(medicine),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                        color: const Color(0xFF636AE8).withOpacity(0.2)),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20)),
                          child: imageWidget,
                        ),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                                color: Colors.green, shape: BoxShape.circle),
                            child: const Icon(Icons.swap_horiz,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(medicine.medicineName,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.store_outlined,
                                size: 12, color: Colors.white.withOpacity(0.7)),
                            const SizedBox(width: 4),
                            Expanded(
                                child: Text('From: ${medicine.pharmacyName}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white.withOpacity(0.7)),
                                    overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => _showMapDialog(
                                  medicine.pharmacyName,
                                  medicine.pharmacyLatitude,
                                  medicine.pharmacyLongitude),
                              child: const Icon(Icons.location_on_outlined,
                                  size: 16, color: Color(0xFF636AE8)),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${medicine.medicineQuantityToSell} units',
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.white)),
                            Text(
                                '\$${double.parse(medicine.medicinePriceToSell).toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 17,
                                    color: Color(0xFF4CAF50),
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.swap_horiz_outlined, size: 18),
                label: const Text('Exchange'),
                onPressed: () => _showBuyMedicineModal(medicine),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF636AE8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -- ✨ تم التحديث الكامل لهذه الدالة لإضافة حقل اختيار التاريخ ✨ --
  void _showBuyMedicineModal(ExchangeMedicineModel medicine) {
    int quantityToBuy = 1;
    DateTime? selectedDate; // ✨ متغير لتخزين التاريخ الذي تم اختياره

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // ✨ دالة لفتح واجهة اختيار التاريخ
            Future<void> selectDate(BuildContext context) async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(), // لا يمكن اختيار تاريخ في الماضي
                lastDate: DateTime(2101),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: Color(0xFF636AE8), // لون العنوان
                        onPrimary: Colors.white, // لون النص في العنوان
                        onSurface: Colors.white, // لون أرقام الأيام
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor:
                          const Color(0xFF636AE8), // لون أزرار OK/Cancel
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null && picked != selectedDate) {
                setModalState(() {
                  selectedDate = picked;
                });
              }
            }

            return Container(
              padding: EdgeInsets.fromLTRB(
                  24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F1A),
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(25)),
                border: Border.all(
                    color: const Color(0xFF636AE8).withOpacity(0.3)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Text(
                      'Confirm Exchange',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    ListTile(
                      leading: const Icon(Icons.medication_outlined,
                          color: Color(0xFF636AE8), size: 30),
                      title: Text(medicine.medicineName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 18)),
                      subtitle: Text('From: ${medicine.pharmacyName}',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 16)),
                      trailing: Text(
                          '\$${double.parse(medicine.medicinePriceToSell).toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Color(0xFF636AE8), size: 30),
                          onPressed: () {
                            if (quantityToBuy > 1) {
                              setModalState(() {
                                quantityToBuy--;
                              });
                            }
                          },
                        ),
                        Text(quantityToBuy.toString(),
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline,
                              color: Color(0xFF636AE8), size: 30),
                          onPressed: () {
                            if (quantityToBuy <
                                int.parse(medicine.medicineQuantityToSell)) {
                              setModalState(() {
                                quantityToBuy++;
                              });
                            } else {
                              _scaffoldMessengerKey.currentState?.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Cannot buy more than available quantity.'),
                                  backgroundColor: Colors.orangeAccent,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // ✨ هذا هو الزر الجديد لاختيار التاريخ
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        selectedDate == null
                            ? 'Select Expected Receive Date'
                            : 'Receive Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      onPressed: () => selectDate(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                            color: const Color(0xFF636AE8).withOpacity(0.7)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 20),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Total: \$${(quantityToBuy * double.parse(medicine.medicinePriceToSell)).toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50)),
                    ),
                    const SizedBox(height: 24),
                    PulsingActionButton(
                      label: 'Confirm Order',
                      onTap: () async {
                        // ✨ فحص للتأكد من أن المستخدم اختار تاريخًا
                        if (selectedDate == null) {
                          _scaffoldMessengerKey.currentState?.showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Please select an expected receive date.'),
                              backgroundColor: Colors.orangeAccent,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                            ),
                          );
                          return; // إيقاف التنفيذ إذا لم يتم اختيار تاريخ
                        }

                        Navigator.pop(modalContext);

                        if (mounted) {
                          _scaffoldMessengerKey.currentState?.showSnackBar(
                            const SnackBar(
                              content: Text('Sending order...'),
                              backgroundColor: Colors.blueAccent,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                            ),
                          );
                        }

                        try {
                          // ✨ تم تحديث الاستدعاء لإرسال التاريخ
                          await this
                              .context
                              .read<ExchangeViewModel>()
                              .createBuyOrder(
                            medicineId: medicine.id,
                            medicineName: medicine.medicineName,
                            price: medicine.medicinePriceToSell,
                            quantity: quantityToBuy,
                            pharmacySeller: medicine.pharmacyName,
                            // ✨ إرسال التاريخ بعد تحويله لنص متوافق مع API
                            recieveDate: selectedDate!.toIso8601String(),
                          );
                        } catch (e) {
                          if (mounted) {
                            _scaffoldMessengerKey.currentState?.showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Failed to place order: ${e.toString()}'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                              ),
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(modalContext),
                      child: Text('Cancel',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 16)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}