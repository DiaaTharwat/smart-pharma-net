import 'dart:io'; // NEW: Added for File handling
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // NEW: Added for image picking
import 'package:provider/provider.dart';
import 'package:smart_pharma_net/view/Screens/home_screen.dart';
import 'package:smart_pharma_net/view/Screens/menu_bar_screen.dart';
import 'package:smart_pharma_net/view/Screens/welcome_screen.dart';
import 'package:smart_pharma_net/viewmodels/pharmacy_viewmodel.dart';
import 'package:smart_pharma_net/models/pharmacy_model.dart';
import 'package:smart_pharma_net/viewmodels/auth_viewmodel.dart';
import 'package:smart_pharma_net/view/Screens/add_pharmacy_screen.dart';
import 'package:smart_pharma_net/view/Screens/pharmacy_details_screen.dart';
import 'package:smart_pharma_net/view/Widgets/common_ui_elements.dart';
import 'package:smart_pharma_net/view/Screens/medicine_screen.dart';
import 'package:speech_to_text/speech_to_text.dart'; // NEW: Added for speech recognition
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'; // NEW: Added for text recognition from image

class AvailablePharmaciesScreen extends StatefulWidget {
  const AvailablePharmaciesScreen({super.key});

  @override
  State<AvailablePharmaciesScreen> createState() =>
      _AvailablePharmaciesScreenState();
}

class _AvailablePharmaciesScreenState extends State<AvailablePharmaciesScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // NEW: State variables for new features
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  File? _selectedImage;
  final TextRecognizer _textRecognizer = TextRecognizer();

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataBasedOnRole();
      _initSpeech(); // NEW: Initialize speech recognition
    });
  }

  // NEW: Initialize speech-to-text
  void _initSpeech() async {
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
          }
        }
      },
    );
    if (mounted) {
      setState(() {});
    }
  }

  // NEW: Start listening function
  void _startListening() async {
    if (!_isListening) {
      bool available = await _speechToText.initialize();
      if (available) {
        if (mounted) {
          setState(() => _isListening = true);
        }
        _speechToText.listen(
          onResult: (result) {
            if (result.finalResult) {
              if (mounted) {
                _searchController.text = result.recognizedWords;
                _searchController.selection = TextSelection.fromPosition(TextPosition(offset: _searchController.text.length));
                _triggerSearch(result.recognizedWords);
              }
            }
          },
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 3),
        );
      }
    }
  }


  // NEW: Stop listening function
  void _stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      if (mounted) {
        setState(() => _isListening = false);
      }
    }
  }

  // NEW: Pick image and recognize text
  void _pickImageAndRecognizeText() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imageFile = await picker.pickImage(source: ImageSource.gallery);

    if (imageFile == null) return;

    if (mounted) {
      setState(() {
        _selectedImage = File(imageFile.path);
      });
    }

    final InputImage inputImage = InputImage.fromFilePath(imageFile.path);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

    String extractedText = recognizedText.text;
    if (extractedText.isNotEmpty) {
      extractedText = extractedText.replaceAll('\n', ' ').trim();
      _searchController.text = extractedText;
      _searchController.selection = TextSelection.fromPosition(TextPosition(offset: _searchController.text.length));
      _triggerSearch(extractedText);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not recognize any text in the image.")),
      );
      if (mounted) {
        setState(() {
          _selectedImage = null;
        });
      }
    }
  }

  // NEW: Function to clear image and search
  void _clearImageSearch() {
    setState(() {
      _selectedImage = null;
      _searchController.clear();
      _triggerSearch('');
    });
  }

  // NEW: Centralized search trigger
  void _triggerSearch(String query) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final pharmacyViewModel = Provider.of<PharmacyViewModel>(context, listen: false);
    pharmacyViewModel.loadPharmacies(
      searchQuery: query,
      authViewModel: authViewModel,
    );
  }

  Future<void> _loadDataBasedOnRole() async {
    _triggerSearch(_searchController.text.trim());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    _textRecognizer.close(); // NEW: Dispose text recognizer
    _speechToText.cancel(); // NEW: Cancel speech recognition
    super.dispose();
  }

  Future<void> _reloadData() async {
    await _loadDataBasedOnRole();
  }

  void _goToAdminHome() {
    final authViewModel = context.read<AuthViewModel>();
    if (authViewModel.isImpersonating) {
      authViewModel.stopImpersonation();
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
    );
  }

  Widget _buildPharmacyCard(PharmacyModel pharmacy, int index, AuthViewModel authViewModel) {
    final canManage = authViewModel.isAdmin || authViewModel.isPharmacy;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF636AE8).withOpacity(0.3), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF636AE8).withOpacity(0.15),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PharmacyDetailsScreen(pharmacy: pharmacy)),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF636AE8).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.local_pharmacy,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pharmacy.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              pharmacy.city,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (canManage)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          color: const Color(0xFF0F0F1A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          onSelected: (value) async {
                            if (value == 'details') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PharmacyDetailsScreen(pharmacy: pharmacy),
                                ),
                              );
                            } else if (value == 'edit') {
                              final result = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddPharmacyScreen(pharmacyToEdit: pharmacy),
                                ),
                              );
                              if (result == true && mounted) {
                                _reloadData();
                              }
                            } else if (value == 'delete') {
                              final confirmDelete = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: const Color(0xFF0F0F1A),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    side: BorderSide(color: const Color(0xFF636AE8).withOpacity(0.5)),
                                  ),
                                  title: const Text('Confirm Delete', style: TextStyle(color: Colors.white)),
                                  content: Text('Are you sure you want to delete ${pharmacy.name}?', style: TextStyle(color: Colors.white70)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
                                    TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
                                  ],
                                ),
                              );

                              if (confirmDelete == true && mounted) {
                                final pharmacyViewModel = context.read<PharmacyViewModel>();
                                try {
                                  await pharmacyViewModel.deletePharmacy(pharmacy.id);

                                  if (authViewModel.isPharmacy) {
                                    await authViewModel.logout();
                                    if(mounted) {
                                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const WelcomeScreen()), (route) => false);
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Pharmacy deleted successfully'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    _reloadData();
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to delete pharmacy: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'details',
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, color: Colors.cyan),
                                  const SizedBox(width: 8),
                                  Text('Details', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit, color: Color(0xFF636AE8)),
                                  const SizedBox(width: 8),
                                  Text('Edit', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete, color: Colors.redAccent),
                                  const SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(
                        Icons.badge,
                        size: 20,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'License: ${pharmacy.licenseNumber}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if(authViewModel.isAdmin)
                    PulsingActionButton(
                      label: 'Manage Pharmacy Medicines',
                      onTap: () async {
                        await authViewModel.impersonatePharmacy(pharmacy);
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MedicineScreen()),
                          );
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pharmacyViewModel = Provider.of<PharmacyViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context);

    return WillPopScope(
      onWillPop: () async {
        _goToAdminHome();
        return false;
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
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 28),
                            onPressed: _goToAdminHome,
                          ),
                          IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                            onPressed: () {
                              // Corrected navigation to MenuBarScreen
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const MenuBarScreen()));
                            },
                          ),
                          Expanded(
                            child: Text(
                              authViewModel.isAdmin ? 'Available Pharmacies' : 'My Pharmacy Details',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [Shadow(blurRadius: 10.0, color: Color(0xFF636AE8))],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
                            onPressed: () => _reloadData(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if(authViewModel.isAdmin)
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            // NEW: Modified search field to include new icons
                            child: GlowingTextField(
                              controller: _searchController,
                              hintText: _isListening ? 'Listening...' : 'Search pharmacies...',
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
                                  : const Icon(Icons.search, color: Color(0xFF636AE8)),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_selectedImage != null)
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white70),
                                      onPressed: _clearImageSearch,
                                    ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.mic,
                                      color: _isListening ? Colors.redAccent : Colors.white70,
                                    ),
                                    onPressed: _speechEnabled ? (_isListening ? _stopListening : _startListening) : null,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.camera_alt_outlined, color: Colors.white70),
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
                child: pharmacyViewModel.isLoading
                    ? const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Color(0xFF636AE8)),
                  ),
                )
                    : pharmacyViewModel.pharmacies.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.storefront,
                        size: 80,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _searchController.text.isNotEmpty ? 'No pharmacies match your search' : 'No Pharmacy Data Found',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                )
                    : RefreshIndicator(
                  onRefresh: _reloadData,
                  color: const Color(0xFF636AE8),
                  backgroundColor: Colors.white.withOpacity(0.8),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: pharmacyViewModel.pharmacies.length,
                    itemBuilder: (context, index) {
                      final pharmacy = pharmacyViewModel.pharmacies[index];
                      return _buildPharmacyCard(pharmacy, index, authViewModel);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: authViewModel.isAdmin
            ? FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddPharmacyScreen(),
              ),
            );
            if (result == true) {
              _reloadData();
            }
          },
          backgroundColor: const Color(0xFF636AE8),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Add Pharmacy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 8,
        )
            : null,
      ),
    );
  }
}