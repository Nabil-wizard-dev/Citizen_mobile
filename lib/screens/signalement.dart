import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../services/signalement_service.dart';
import '../models/signalement.dart';

class SignalementPage extends StatefulWidget {
  const SignalementPage({super.key});

  @override
  _SignalementPageState createState() => _SignalementPageState();
}

class _SignalementPageState extends State<SignalementPage> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _codeController = TextEditingController();

  String? _selectedTypeService;
  File? _imageFile;
  bool _isSubmitting = false;
  bool _isLoadingLocation = false;
  double? _latitude;
  double? _longitude;

  final List<Map<String, dynamic>> _typeServices =
      TypeService.values
          .map(
            (type) => {
              'value': type.value,
              'name': type.displayName,
              'icon':
                  type == TypeService.SERVICE_HYGIENE
                      ? Icons.cleaning_services
                      : Icons.location_city,
            },
          )
          .toList();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Permission de localisation refusée', true);
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar(
          'Permission de localisation définitivement refusée',
          true,
        );
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      // Obtenir la position actuelle
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isLoadingLocation = false;
      });
    } catch (e) {
      _showSnackBar(
        'Erreur lors de la récupération de la localisation: $e',
        true,
      );
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _setFile(File file) {
    setState(() {
      _imageFile = file;
    });
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (image != null) {
      _setFile(File(image.path));
    }
  }

  Future<void> _takePhoto() async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (photo != null) {
      _setFile(File(photo.path));
    }
  }

  void _showSnackBar(String message, [bool isError = false]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _submitSignalement() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTypeService == null) {
      return _showSnackBar('Sélectionnez un type de service', true);
    }

    if (_latitude == null || _longitude == null) {
      return _showSnackBar('Localisation requise', true);
    }

    if (_imageFile == null) {
      return _showSnackBar(
        'Une photo est obligatoire pour le signalement',
        true,
      );
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await SignalementService.createSignalement(
        titre: _titreController.text.trim(),
        description: _descriptionController.text.trim(),
        code: _codeController.text.trim(),
        typeService: _selectedTypeService!,
        latitude: _latitude!,
        longitude: _longitude!,
        images: [_imageFile!], // Fichier obligatoire
        priorite: 1, // Priorité par défaut
        serviceId: 1, // Service par défaut
      );

      if (result['success']) {
        _showSnackBar('Signalement envoyé avec succès !');
        _resetForm();
      } else {
        _showSnackBar(
          result['message'] ?? 'Erreur lors de la création du signalement',
          true,
        );
      }
    } catch (e) {
      _showSnackBar('Erreur: $e', true);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    setState(() {
      _selectedTypeService = null;
      _imageFile = null;
      _titreController.clear();
      _descriptionController.clear();
      _codeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const Center(
                  child: Text(
                    'Faire un signalement',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                _buildTitreField(),
                const SizedBox(height: 20),
                _buildCodeField(),
                const SizedBox(height: 20),
                _buildTypeServiceDropdown(),
                const SizedBox(height: 20),
                _buildDescriptionField(),
                const SizedBox(height: 20),
                _buildLocationSection(),
                const SizedBox(height: 20),
                _buildImageSection(),
                const SizedBox(height: 30),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitreField() {
    return TextFormField(
      controller: _titreController,
      decoration: _inputDecoration(
        'Titre du signalement',
        'Ex: Problème de voirie',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Le titre est requis';
        }
        if (value.trim().length < 5) {
          return 'Le titre doit contenir au moins 5 caractères';
        }
        return null;
      },
    );
  }

  Widget _buildCodeField() {
    return TextFormField(
      controller: _codeController,
      decoration: _inputDecoration('Code/Adresse', 'Ex: Rue de la Paix, Lomé'),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Le code/adresse est requis';
        }
        return null;
      },
    );
  }

  Widget _buildTypeServiceDropdown() {
    return DropdownButtonFormField<String>(
      decoration: _inputDecoration('Type de service'),
      value: _selectedTypeService,
      isExpanded: true,
      icon: const Icon(Icons.arrow_drop_down_circle, color: Color(0xff007BFF)),
      items:
          _typeServices
              .map(
                (service) => DropdownMenuItem<String>(
                  value: service['value'],
                  child: Row(
                    children: [
                      Icon(
                        service['icon'],
                        size: 20,
                        color: const Color(0xff007BFF),
                      ),
                      const SizedBox(width: 12),
                      Text(service['name']),
                    ],
                  ),
                ),
              )
              .toList(),
      onChanged: (value) => setState(() => _selectedTypeService = value),
      validator:
          (value) => value == null ? 'Sélectionnez un type de service' : null,
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: _inputDecoration(
        'Description du problème',
        'Décrivez en détail ce que vous avez constaté...',
      ),
      maxLines: 5,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'La description est requise';
        }
        if (value.trim().length < 10) {
          return 'La description doit contenir au moins 10 caractères';
        }
        return null;
      },
    );
  }

  Widget _buildLocationSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xff007BFF)),
                const SizedBox(width: 8),
                const Text(
                  'Localisation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_isLoadingLocation)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_latitude != null && _longitude != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Localisation obtenue: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Localisation en cours...',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                    TextButton(
                      onPressed: _getCurrentLocation,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Photo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Obligatoire',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galerie'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Caméra'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff007BFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_imageFile != null) ...[
              const SizedBox(height: 16),
              _buildImagePreview(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(_imageFile!, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => setState(() => _imageFile = null),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitSignalement,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff007BFF),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
            _isSubmitting
                ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('ENVOI EN COURS...'),
                  ],
                )
                : const Text(
                  'ENVOYER LE SIGNALEMENT',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: Colors.white,
                  ),
                ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, [String? hintText]) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xff007BFF), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
