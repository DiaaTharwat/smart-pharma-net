// lib/view/Screens/home_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_pharma_net/models/pharmacy_model.dart';
import 'package:smart_pharma_net/view/Screens/menu_bar_screen.dart';
import 'package:smart_pharma_net/view/Screens/welcome_screen.dart';
import 'package:smart_pharma_net/viewmodels/auth_viewmodel.dart';
import 'package:smart_pharma_net/viewmodels/pharmacy_viewmodel.dart';
import '../../viewmodels/medicine_viewmodel.dart';
import '../../models/medicine_model.dart';
import 'add_medicine_screen.dart';
import 'chat_ai_screen.dart';
import 'package:smart_pharma_net/view/Widgets/common_ui_elements.dart';
import 'user_purchase_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:flutter_map/flutter_map.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isSortingByDistance = false;
  bool _isLoadingLocation = false;

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  File? _selectedImage;
  final TextRecognizer _textRecognizer = TextRecognizer();

  Timer? _debounce;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _animationController.forward();
    _initSpeech();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authViewModel = context.read<AuthViewModel>();
      final medicineViewModel = context.read<MedicineViewModel>();
      final pharmacyViewModel = context.read<PharmacyViewModel>();

      medicineViewModel.loadMedicines(
          pharmacyId: authViewModel.activePharmacyId,
          forceLoadAll:
          authViewModel.isAdmin && !authViewModel.canActAsPharmacy);

      pharmacyViewModel
          .loadPharmacies(searchQuery: '', authViewModel: authViewModel)
          .catchError((error) {
        print(
            "Could not load pharmacies, continuing without them. Error: $error");
      });
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<MedicineViewModel>().loadMoreMedicines();
    }
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
          }
          if (status == 'notListening' || status == 'done') {
            if (mounted) {
              setState(() {
                _isListening = false;
              });
              if (_searchController.text.isNotEmpty) {
                _triggerSearch(_searchController.text);
              }
            }
          }
        },
      );
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print("Speech initialization failed: $e");
      setState(() {
        _speechEnabled = false;
      });
    }
  }

  void _startListening() {
    if (_speechEnabled && !_isListening) {
      if (mounted) {
        setState(() => _isListening = true);
      }
      _speechToText.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _searchController.text = result.recognizedWords;
              _searchController.selection = TextSelection.fromPosition(
                TextPosition(offset: _searchController.text.length),
              );
            });
          }
        },
        listenFor: const Duration(seconds: 5),
        pauseFor: const Duration(seconds: 2),
      );
    } else {
      print(
          'Could not start listening. Speech enabled: $_speechEnabled, Is listening: $_isListening');
    }
  }

  void _stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
    }
  }

  // =========================================================================
  // =================== START: الكود الذي تم تعديله =======================
  // =========================================================================
  /// The final, correct implementation for image search on the HomeScreen.
  void _pickImageAndRecognizeText() async {
    final medicineViewModel = context.read<MedicineViewModel>();

    // Use the currently loaded medicines as a guide for string matching.
    // This list is incomplete but serves as an excellent filter.
    final List<String> localMedicineNames = medicineViewModel.medicines.map((m) => m.name).toList();

    if (localMedicineNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Medicine list is empty. Please wait for it to load.")),
      );
      return;
    }

    try {
      // 1. Pick Image
      final ImagePicker picker = ImagePicker();
      final XFile? imageFile = await picker.pickImage(source: ImageSource.gallery);
      if (imageFile == null) return;

      if (mounted) {
        setState(() {
          _selectedImage = File(imageFile.path);
        });
      }

      // 2. Recognize Text
      final InputImage inputImage = InputImage.fromFilePath(imageFile.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      final String fullTextFromImage = recognizedText.text;

      if (fullTextFromImage.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not recognize any text.")),
        );
        _clearImageSearch();
        return;
      }

      // 3. THE HYBRID SOLUTION: Find the best match using the local (paginated) list as a guide.
      final BestMatch bestMatch = StringSimilarity.findBestMatch(fullTextFromImage, localMedicineNames);

      // 4. If a good match is found, use that CLEAN name for the network search.
      if (bestMatch.bestMatch.rating != null && bestMatch.bestMatch.rating! > 0.2) {
        final String foundMedicineName = bestMatch.bestMatch.target!;
        print("Image text matched to clean name: '$foundMedicineName'. Triggering network search.");

        _searchController.text = foundMedicineName;
        _searchController.selection = TextSelection.fromPosition(
            TextPosition(offset: _searchController.text.length));
        _triggerSearch(foundMedicineName);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not find a matching medicine from the image.")),
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
  // =========================================================================
  // ====================== END: الكود الذي تم تعديله ========================
  // =========================================================================

  void _clearImageSearch() {
    setState(() {
      _selectedImage = null;
      _searchController.clear();
      _triggerSearch('');
    });
  }

  void _triggerSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      if (_isSortingByDistance) {
        setState(() {
          _isSortingByDistance = false;
        });
      }
      final authViewModel = context.read<AuthViewModel>();
      context.read<MedicineViewModel>().searchMedicines(query,
          pharmacyId:
          authViewModel.isPharmacy ? authViewModel.activePharmacyId : null);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _textRecognizer.close();
    _speechToText.cancel();
    _debounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authViewModel = context.read<AuthViewModel>();
    await authViewModel.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
              (route) => false);
    }
  }

  Future<void> _returnToAdminHomeAndLogoutPharmacy() async {
    final authViewModel = context.read<AuthViewModel>();
    await authViewModel.restoreAdminSession();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }

  Future<LatLng?> _getUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print("Failed to get location: $e");
      return null;
    }
  }

  Future<void> _handleDeleteMedicine(
      BuildContext context, MedicineModel medicine) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F0F1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: const Color(0xFF636AE8).withOpacity(0.5)),
        ),
        title:
        const Text('Confirm Delete', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete ${medicine.name}?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final medicineViewModel = context.read<MedicineViewModel>();

      await medicineViewModel.deleteMedicine(
          pharmacyId: medicine.pharmacyId, medicineId: medicine.id);

      if (mounted && medicineViewModel.error.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(medicineViewModel.error),
              backgroundColor: Colors.red),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Medicine deleted successfully'),
              backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _handleEditMedicine(
      BuildContext context, MedicineModel medicine) async {
    final authViewModel = context.read<AuthViewModel>();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicineScreen(
          medicine: medicine,
          pharmacyId: medicine.pharmacyId,
        ),
      ),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Medicine updated successfully!'),
            backgroundColor: Colors.green),
      );
      context.read<MedicineViewModel>().loadMedicines(
          pharmacyId: authViewModel.activePharmacyId,
          forceLoadAll: authViewModel.isAdmin);
    }
  }

  void _showMapDialog(String pharmacyName, String? lat, String? lon) {
    if (lat == null || lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Location not available for this pharmacy.")),
      );
      return;
    }
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

  Widget _buildMedicineCard(
      BuildContext context, MedicineModel medicine, double cardWidth) {
    final authViewModel = context.watch<AuthViewModel>();
    final pharmacyViewModel = context.watch<PharmacyViewModel>();

    bool canManage = false;

    if (authViewModel.isAdmin && !authViewModel.isImpersonating) {
      final ownedPharmacyIds =
      pharmacyViewModel.pharmacies.map((p) => p.id).toSet();
      canManage = ownedPharmacyIds.contains(medicine.pharmacyId);
    } else if (authViewModel.canActAsPharmacy) {
      canManage = medicine.pharmacyId == authViewModel.activePharmacyId;
    }

    final bool isNormalUser =
        !authViewModel.isAdmin && !authViewModel.isPharmacy;

    Widget imageWidget;
    if (medicine.imageUrl != null && medicine.imageUrl!.isNotEmpty) {
      final imageUrl = medicine.imageUrl!;
      if (imageUrl.toLowerCase().endsWith('.svg')) {
        imageWidget = SvgPicture.network(
          imageUrl,
          fit: BoxFit.contain,
          width: double.infinity,
          height: 140,
          placeholderBuilder: (context) => const Center(
              child:
              CircularProgressIndicator(color: Color(0xFF636AE8))),
        );
      } else {
        imageWidget = Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 140,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
                child:
                CircularProgressIndicator(color: Color(0xFF636AE8)));
          },
          errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.medication_liquid_outlined,
              size: 90,
              color: Color(0xFF636AE8)),
        );
      }
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
              onTap: () => _showReadOnlyMedicineDetails(medicine),
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
                        if (medicine.canBeSell)
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
                        Text(medicine.name,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(medicine.category,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.6)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        if (!authViewModel.isPharmacy)
                          Row(
                            children: [
                              Icon(Icons.store_outlined,
                                  size: 12,
                                  color: Colors.white.withOpacity(0.7)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  medicine.pharmacyName,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.7)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () {
                                  final pharmacyViewModel =
                                  context.read<PharmacyViewModel>();
                                  PharmacyModel? pharmacy;
                                  try {
                                    pharmacy = pharmacyViewModel.pharmacies
                                        .firstWhere((p) =>
                                    p.id == medicine.pharmacyId);
                                  } catch (e) {
                                    pharmacy = null;
                                  }

                                  if (pharmacy != null) {
                                    _showMapDialog(
                                      pharmacy.name,
                                      pharmacy.latitude.toString(),
                                      pharmacy.longitude.toString(),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              "Location details for this pharmacy are not available.")),
                                    );
                                  }
                                },
                                child: const Icon(Icons.location_on_outlined,
                                    size: 16, color: Color(0xFF636AE8)),
                              ),
                            ],
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 11,
                                color: Colors.white.withOpacity(0.7)),
                            const SizedBox(width: 4),
                            Text('Exp: ${medicine.expiryDate}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.7))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${medicine.quantity} units',
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.white)),
                            Text('\$${medicine.price.toStringAsFixed(2)}',
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
            if (canManage)
              _buildAdminActionButtons(context, medicine)
            else if (isNormalUser)
              _buildUserActionButtons(context, medicine)
          ],
        ),
      ),
    );
  }

  Widget _buildAdminActionButtons(
      BuildContext context, MedicineModel medicine) {
    return Container(
      decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
                  color: const Color(0xFF636AE8).withOpacity(0.3),
                  width: 1.0))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: TextButton.icon(
              icon: const Icon(Icons.edit, color: Colors.white70, size: 18),
              label: const Text('Edit',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              onPressed: () => _handleEditMedicine(context, medicine),
              style: TextButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            ),
          ),
          Container(
              height: 20,
              width: 1,
              color: const Color(0xFF636AE8).withOpacity(0.3)),
          Expanded(
            child: TextButton.icon(
              icon: const Icon(Icons.delete_forever,
                  color: Colors.redAccent, size: 18),
              label: const Text('Delete',
                  style: TextStyle(color: Colors.redAccent, fontSize: 12)),
              onPressed: () => _handleDeleteMedicine(context, medicine),
              style: TextButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserActionButtons(
      BuildContext context, MedicineModel medicine) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.shopping_cart_checkout, size: 18),
        label: const Text('Buy Now'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => UserPurchaseScreen(medicine: medicine)),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF636AE8),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          textStyle:
          const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _showReadOnlyMedicineDetails(MedicineModel medicine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F1A),
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(25)),
                border:
                Border.all(color: const Color(0xFF636AE8).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF636AE8).withOpacity(0.6),
                      borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.medication_outlined,
                            color: Colors.white, size: 30),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(medicine.name,
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Pharmacy', medicine.pharmacyName),
                          _buildDetailRow('Description', medicine.description),
                          _buildDetailRow('Price',
                              '\$${medicine.price.toStringAsFixed(2)}'),
                          _buildDetailRow(
                              'Quantity', '${medicine.quantity} units'),
                          _buildDetailRow('Expiry Date', medicine.expiryDate),
                          _buildDetailRow('Category', medicine.category),
                          if (medicine.canBeSell) ...[
                            _buildDetailRow('Sell Price',
                                '\$${medicine.priceSell.toStringAsFixed(2)}'),
                            _buildDetailRow('Quantity To Sell',
                                '${medicine.quantityToSell ?? 'N/A'} units'),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.8)),
          ),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(fontSize: 17, color: Colors.white)),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withOpacity(0.2)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final medicineViewModel = context.watch<MedicineViewModel>();

    return WillPopScope(
      onWillPop: () async {
        if (authViewModel.isImpersonating) {
          await _returnToAdminHomeAndLogoutPharmacy();
          return false;
        }
        return true;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 0,
        ),
        body: InteractiveParticleBackground(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                child: SafeArea(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.menu,
                                color: Colors.white, size: 28),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MenuBarScreen(),
                                ),
                              );
                            },
                          ),
                          const Expanded(
                            child: Text(
                              'Smart PharmaNet',
                              style: TextStyle(
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
                            ),
                          ),
                          InkWell(
                            onTap: authViewModel.isImpersonating
                                ? _returnToAdminHomeAndLogoutPharmacy
                                : () => _handleLogout(context),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    authViewModel.isImpersonating
                                        ? Icons.exit_to_app
                                        : Icons.logout,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    authViewModel.isImpersonating
                                        ? 'Exit Pharmacy'
                                        : 'Logout',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 8),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: const Text(
                          'Available Medications',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(blurRadius: 8.0, color: Color(0xFF636AE8))
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          children: [
                            GlowingTextField(
                              controller: _searchController,
                              hintText: _isListening
                                  ? 'Listening...'
                                  : 'Search medicines...',
                              onChanged: (value) {
                                if (_selectedImage == null) {
                                  _triggerSearch(value);
                                }
                              },
                              prefixIcon: _selectedImage != null
                                  ? Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
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
                                    icon: const Icon(Icons.camera_alt_outlined,
                                        color: Colors.white70),
                                    onPressed: _pickImageAndRecognizeText,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (!authViewModel.isPharmacy)
                              ElevatedButton.icon(
                                icon: Icon(
                                  _isLoadingLocation
                                      ? null
                                      : (_isSortingByDistance
                                      ? Icons.filter_list_off_outlined
                                      : Icons.location_on_outlined),
                                  color: _isLoadingLocation
                                      ? Colors.transparent
                                      : Colors.white,
                                  size: 24,
                                ),
                                label: _isLoadingLocation
                                    ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                          Colors.white)),
                                )
                                    : Text(
                                  _isSortingByDistance
                                      ? "CLEAR SORT"
                                      : "SORT BY DISTANCE",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF636AE8)
                                      .withAlpha(
                                      _isSortingByDistance ? 200 : 255),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(15.0),
                                      side: BorderSide(
                                          color: Colors.white.withOpacity(0.5),
                                          width: 1.0)),
                                  elevation: 5,
                                  shadowColor:
                                  const Color(0xFF636AE8).withOpacity(0.6),
                                ),
                                onPressed: _isLoadingLocation
                                    ? null
                                    : () async {
                                  final pharmacyViewModel =
                                  context.read<PharmacyViewModel>();
                                  final medicineViewModel =
                                  context.read<MedicineViewModel>();
                                  setState(() {
                                    _isLoadingLocation = true;
                                  });

                                  if (_isSortingByDistance) {
                                    medicineViewModel
                                        .clearDistanceSort();
                                    setState(() {
                                      _isSortingByDistance = false;
                                    });
                                  } else {
                                    LatLng? userLocation =
                                    await _getUserLocation();
                                    if (userLocation != null &&
                                        mounted) {
                                      if (pharmacyViewModel
                                          .pharmacies.isEmpty) {
                                        await pharmacyViewModel
                                            .loadPharmacies(
                                            searchQuery: '',
                                            authViewModel:
                                            authViewModel);
                                      }

                                      if (mounted &&
                                          pharmacyViewModel
                                              .pharmacies.isNotEmpty) {
                                        await medicineViewModel
                                            .sortMedicinesByDistance(
                                            userLocation,
                                            pharmacyViewModel
                                                .pharmacies);
                                        setState(() {
                                          _isSortingByDistance = true;
                                        });
                                      } else if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content: Text(
                                              'Could not load pharmacies for sorting.'),
                                          backgroundColor: Colors.red,
                                          behavior:
                                          SnackBarBehavior.fixed,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.all(
                                                  Radius.circular(
                                                      10))),
                                        ));
                                      }
                                    } else if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                        content: Text(
                                            'Could not get location. Please ensure location services and permissions are enabled.'),
                                        backgroundColor: Colors.red,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.all(
                                                Radius.circular(
                                                    10))),
                                      ));
                                    }
                                  }
                                  setState(() {
                                    _isLoadingLocation = false;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Consumer<MedicineViewModel>(
                  builder: (context, medicineViewModel, child) {
                    if (medicineViewModel.isLoading &&
                        !medicineViewModel.isFetchingMore) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF636AE8)),
                        ),
                      );
                    }

                    if (medicineViewModel.error.isNotEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 60,
                              color: Colors.red.shade400,
                            ),
                            const SizedBox(height: 20),
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Text(
                                'Error: ${medicineViewModel.error}',
                                style: TextStyle(
                                  color: Colors.red.shade200,
                                  fontSize: 17,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 20),
                            PulsingActionButton(
                              label: 'Retry',
                              onTap: () {
                                medicineViewModel.loadMedicines(
                                    pharmacyId: authViewModel.activePharmacyId,
                                    forceLoadAll: !authViewModel.isPharmacy);
                              },
                            ),
                          ],
                        ),
                      );
                    }

                    final displayedMedicines = medicineViewModel.medicines;

                    if (displayedMedicines.isEmpty &&
                        !medicineViewModel.isFetchingMore) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.medication_outlined,
                              size: 80,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'No medicines match your search'
                                  : 'No medicines found',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            if (_searchController.text.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                'Try a different search term',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    final screenPadding = const EdgeInsets.all(20.0);
                    final horizontalSpacing = 20.0;
                    final verticalSpacing = 20.0;

                    return RefreshIndicator(
                      onRefresh: () async {
                        if (_isSortingByDistance) {
                          setState(() {
                            _isSortingByDistance = false;
                          });
                        }
                        await medicineViewModel.loadMedicines(
                            pharmacyId: authViewModel.activePharmacyId,
                            forceLoadAll: !authViewModel.isPharmacy);
                      },
                      color: const Color(0xFF636AE8),
                      backgroundColor: Colors.white.withOpacity(0.8),
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: screenPadding,
                        child: Column(
                          children: [
                            Wrap(
                              spacing: horizontalSpacing,
                              runSpacing: verticalSpacing,
                              alignment: WrapAlignment.start,
                              children: displayedMedicines.map((medicine) {
                                final double screenWidth =
                                    MediaQuery.of(context).size.width;
                                final double totalHorizontalPadding =
                                    screenPadding.left + screenPadding.right;

                                int crossAxisCount;
                                if (screenWidth >= 1600) {
                                  crossAxisCount = 4;
                                } else if (screenWidth >= 1200) {
                                  crossAxisCount = 3;
                                } else if (screenWidth >= 800) {
                                  crossAxisCount = 2;
                                } else {
                                  crossAxisCount = 1;
                                }

                                final double totalSpacing =
                                    horizontalSpacing * (crossAxisCount - 1);
                                final double cardWidth = (screenWidth -
                                    totalHorizontalPadding -
                                    totalSpacing) /
                                    crossAxisCount;

                                return _buildMedicineCard(
                                    context, medicine, cardWidth);
                              }).toList(),
                            ),
                            if (medicineViewModel.isFetchingMore)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20.0),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF636AE8)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: Stack(
          children: <Widget>[
            if (authViewModel.isPharmacy)
              Positioned(
                bottom: 0,
                right: 0,
                child: FloatingActionButton.extended(
                  heroTag: 'add_medicine_fab',
                  onPressed: () async {
                    if (authViewModel.activePharmacyId != null && mounted) {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddMedicineScreen(
                            pharmacyId: authViewModel.activePharmacyId!,
                          ),
                        ),
                      );
                      if (result == true && mounted) {
                        medicineViewModel.loadMedicines(
                            pharmacyId: authViewModel.activePharmacyId);
                      }
                    } else if (mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(
                        content: Text(
                            'Could not determine pharmacy to add medicine.'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.fixed,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(10))),
                      ));
                    }
                  },
                  backgroundColor: const Color(0xFF636AE8),
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Add Medicine',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  elevation: 8,
                ),
              ),
            Positioned(
              bottom: authViewModel.isPharmacy ? 80.0 : 0.0,
              right: 0,
              child: FloatingActionButton(
                heroTag: 'chat_ai_fab',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ChatAiScreen()),
                  );
                },
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                tooltip: 'Chat with AI',
                child: const Icon(Icons.support_agent, color: Colors.white),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                elevation: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}