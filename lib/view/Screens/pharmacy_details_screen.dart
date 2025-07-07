import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:string_similarity/string_similarity.dart';
import '../../models/pharmacy_model.dart';
import '../../viewmodels/pharmacy_viewmodel.dart';
import 'add_medicine_screen.dart';
import '../../models/medicine_model.dart';
import 'package:smart_pharma_net/view/Widgets/common_ui_elements.dart';


class PharmacyDetailsScreen extends StatefulWidget {
  final PharmacyModel pharmacy;

  const PharmacyDetailsScreen({Key? key, required this.pharmacy}) : super(key: key);

  @override
  State<PharmacyDetailsScreen> createState() => _PharmacyDetailsScreenState();
}

class _PharmacyDetailsScreenState extends State<PharmacyDetailsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _searchController = TextEditingController();
  List<MedicineModel> _originalMedicines = [];
  List<MedicineModel> _filteredMedicines = [];

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
      context.read<PharmacyViewModel>().loadMedicinesForPharmacy(widget.pharmacy.id);
      _initSpeech();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _textRecognizer.close();
    _speechToText.cancel();
    super.dispose();
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

  // --- ✅ التصحيح النهائي لدالة البحث بالصورة ---
  void _pickImageAndRecognizeText() async {
    if (_originalMedicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Medicines are not loaded yet.")),
      );
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? imageFile = await picker.pickImage(source: ImageSource.gallery);
      if (imageFile == null) return;
      if (mounted) setState(() => _selectedImage = File(imageFile.path));

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

      // --- هذا هو المنطق الصحيح ---
      final List<String> medicineNames = _originalMedicines.map((m) => m.name).toList();
      final BestMatch bestMatch = StringSimilarity.findBestMatch(fullTextFromImage, medicineNames);

      if (bestMatch.bestMatch.rating != null && bestMatch.bestMatch.rating! > 0.2) {
        final String foundMedicineName = bestMatch.bestMatch.target!;
        _searchController.text = foundMedicineName;
        _searchController.selection = TextSelection.fromPosition(TextPosition(offset: _searchController.text.length));
        _triggerSearch(foundMedicineName);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not find a matching medicine.")),
        );
        _clearImageSearch();
      }
      // --------------------------

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
    if (query.isEmpty) {
      setState(() {
        _filteredMedicines = List.from(_originalMedicines);
      });
    } else {
      final lowerCaseQuery = query.toLowerCase().trim();
      setState(() {
        _filteredMedicines = _originalMedicines
            .where((medicine) =>
        medicine.name.toLowerCase().contains(lowerCaseQuery) ||
            medicine.category.toLowerCase().contains(lowerCaseQuery))
            .toList();
      });
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F0F1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: const Color(0xFF636AE8).withOpacity(0.5)),
          ),
          title: const Text('Delete Pharmacy', style: TextStyle(color: Colors.white)),
          content: Text('Are you sure you want to delete ${widget.pharmacy.name}?', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      final viewModel = Provider.of<PharmacyViewModel>(context, listen: false);
      try {
        await viewModel.deletePharmacy(widget.pharmacy.id);
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pharmacy deleted successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete pharmacy: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
            ),
          );
        }
      }
    }
  }

  Widget _buildDetailRow({required String title, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF636AE8).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF636AE8).withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF636AE8).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7))),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(MedicineModel medicine) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF636AE8).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF636AE8).withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  medicine.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (medicine.canBeSell)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.swap_horiz, size: 16, color: Colors.greenAccent),
                      SizedBox(width: 4),
                      Text(
                        'For Exchange',
                        style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            medicine.category,
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.15), height: 20),
          Row(
            children: [
              _buildDetailItem(Icons.attach_money, 'Price', '\$${medicine.price.toStringAsFixed(2)}'),
              _buildDetailItem(Icons.inventory_2_outlined, 'Stock Qty', '${medicine.quantity}'),
              _buildDetailItem(Icons.calendar_today_outlined, 'Expiry', medicine.expiryDate),
            ],
          ),
          if (medicine.canBeSell) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _buildDetailItem(Icons.sell_outlined, 'Sell Price', '\$${medicine.priceSell.toStringAsFixed(2)}'),
                _buildDetailItem(Icons.shopping_cart_checkout_outlined, 'Sell Qty', '${medicine.quantityToSell ?? 'N/A'}'),
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF636AE8).withOpacity(0.8)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.pharmacy.name,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(blurRadius: 10.0, color: Color(0xFF636AE8))],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
            onPressed: () => context.read<PharmacyViewModel>().loadMedicinesForPharmacy(widget.pharmacy.id),
            tooltip: 'Refresh Medicines',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 28),
            onPressed: () => _showDeleteConfirmation(context),
            tooltip: 'Delete Pharmacy',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddMedicineScreen(
                pharmacyId: widget.pharmacy.id,
              ),
            ),
          );
        },
        backgroundColor: const Color(0xFF636AE8),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Colors.white, size: 28),
        label: const Text('Add Medicine', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 8,
      ),
      body: InteractiveParticleBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 120, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      _buildDetailRow(title: 'Name', value: widget.pharmacy.name, icon: Icons.store),
                      const SizedBox(height: 20),
                      _buildDetailRow(title: 'City', value: widget.pharmacy.city, icon: Icons.location_city),
                      const SizedBox(height: 20),
                      _buildDetailRow(title: 'License Number', value: widget.pharmacy.licenseNumber, icon: Icons.badge),
                      const SizedBox(height: 20),
                      _buildDetailRow(title: 'Location (Lat, Long)', value: '${widget.pharmacy.latitude}, ${widget.pharmacy.longitude}', icon: Icons.location_on),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Text(
                    'Medicines in ${widget.pharmacy.name}:',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 8.0, color: Color(0xFF636AE8))],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GlowingTextField(
                controller: _searchController,
                hintText: _isListening ? 'Listening...' : 'Search medicines in this pharmacy...',
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
              const SizedBox(height: 20),
              Consumer<PharmacyViewModel>(
                builder: (context, viewModel, child) {
                  if (viewModel.pharmacyMedicines.isNotEmpty && _originalMedicines.isEmpty) {
                    _originalMedicines = List.from(viewModel.pharmacyMedicines);
                    _filteredMedicines = List.from(viewModel.pharmacyMedicines);
                  } else if (viewModel.pharmacyMedicines.length != _originalMedicines.length) {
                    _originalMedicines = List.from(viewModel.pharmacyMedicines);
                    _triggerSearch(_searchController.text);
                  }

                  if (viewModel.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF636AE8)),
                      ),
                    );
                  }
                  if (viewModel.error.isNotEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          'Error loading medicines: ${viewModel.error}',
                          style: const TextStyle(color: Colors.red, fontSize: 17),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  if (_filteredMedicines.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 80,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'No medicines match your search.'
                                  : 'No medicines available for this pharmacy.',
                              style: TextStyle(fontSize: 20, color: Colors.white.withOpacity(0.7)),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredMedicines.length,
                    itemBuilder: (context, index) {
                      final medicine = _filteredMedicines[index];
                      return _buildMedicineCard(medicine);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}