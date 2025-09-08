import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final User user;
  final Function(String?)?
  onProfileUpdated; // Modifier pour accepter l'URL de la photo

  const ProfileScreen({Key? key, required this.user, this.onProfileUpdated})
    : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profile;
  bool isLoading = true;
  bool isEditing = false;
  File? selectedImage;
  String? currentPhotoUrl;

  // Contrôleurs pour les champs de texte
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => isLoading = true);

    try {
      final result = await ProfileService.getProfile();
      if (result['success']) {
        setState(() {
          profile = result['data'];
          _populateForm();
          if (profile!['photoProfil'] != null) {
            currentPhotoUrl =
                'http://192.168.1.70:8080/${profile!['photoProfil']}';
          }
        });

        // Passer la photo à l'AppBar dès le chargement
        widget.onProfileUpdated?.call(currentPhotoUrl);
      }
    } catch (e) {
      print('Erreur: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _populateForm() {
    if (profile != null) {
      _nomController.text = profile!['nom'] ?? '';
      _prenomController.text = profile!['prenom'] ?? '';
      _emailController.text = profile!['email'] ?? '';
      _numeroController.text = profile!['numero']?.toString() ?? '';
      _adresseController.text = profile!['adresse'] ?? '';
    }
  }

  Future<void> _pickImage() async {
    final image = await ProfileService.pickImageFromGallery();
    if (image != null) {
      setState(() => selectedImage = image);
    }
  }

  Future<void> _saveProfile() async {
    if (profile == null) return;

    setState(() => isLoading = true);

    try {
      // Upload de la photo si sélectionnée
      if (selectedImage != null) {
        final photoResult = await ProfileService.uploadProfilePhoto(
          selectedImage!,
        );
        if (photoResult['success']) {
          setState(() {
            selectedImage = null;
            currentPhotoUrl = 'http://192.168.1.70:8080/${photoResult['data']}';
          });
          // Rafraîchir l'AppBar immédiatement après l'upload de photo
          widget.onProfileUpdated?.call(currentPhotoUrl);
        } else {
          _showMessage(
            'Erreur lors de l\'upload de la photo: ${photoResult['message']}',
          );
          setState(() => isLoading = false);
          return;
        }
      }

      // Mise à jour du profil
      final updateData = {
        'nom': _nomController.text,
        'prenom': _prenomController.text,
        'email': _emailController.text,
        'numero': int.tryParse(_numeroController.text) ?? 0,
        'adresse': _adresseController.text,
      };

      final result = await ProfileService.updateProfile(updateData);
      if (result['success']) {
        setState(() {
          isEditing = false;
          profile = result['data'];
        });
        _showMessage('Profil mis à jour avec succès');
        // Passer la photo actuelle à l'AppBar
        widget.onProfileUpdated?.call(currentPhotoUrl);
      } else {
        _showMessage('Erreur: ${result['message']}');
      }
    } catch (e) {
      _showMessage('Erreur lors de la sauvegarde');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: message.contains('succès') ? Colors.green : Colors.red,
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'CITOYEN':
        return 'Citoyen';
      case 'OUVRIER':
        return 'Ouvrier';
      case 'AUTORITE':
        return 'Autorité Locale';
      default:
        return role;
    }
  }

  Widget _buildInfoField(
    String label,
    TextEditingController controller, {
    bool isReadOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: controller,
            enabled: isEditing && !isReadOnly,
            decoration: InputDecoration(
              filled: true,
              fillColor: isEditing ? Colors.white : Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFF1E3A8A)),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // Photo de profil
          Center(
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.blue[400]!, Colors.blue[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child:
                        selectedImage != null
                            ? Image.file(selectedImage!, fit: BoxFit.cover)
                            : currentPhotoUrl != null
                            ? Image.network(
                              currentPhotoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.white,
                                  ),
                            )
                            : Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                ),
                if (isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Indicateur de photo sélectionnée
          if (selectedImage != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Photo sélectionnée',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: 30),

          // Informations du profil
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Informations ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                    if (!isEditing)
                      GestureDetector(
                        onTap: () => setState(() => isEditing = true),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Modifier',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 20),

                // Champs éditables
                if (isEditing) ...[
                  _buildInfoField('Nom', _nomController),
                  _buildInfoField('Prénom', _prenomController),
                  _buildInfoField('Email', _emailController),
                  _buildInfoField('Numéro de téléphone', _numeroController),
                  _buildInfoField('Adresse', _adresseController),
                ] else ...[
                  // Champs en lecture seule
                  _buildReadOnlyField('Nom', profile?['nom'] ?? ''),
                  _buildReadOnlyField('Prénom', profile?['prenom'] ?? ''),
                  _buildReadOnlyField('Email', profile?['email'] ?? ''),
                  _buildReadOnlyField(
                    'Numéro de téléphone',
                    profile?['numero']?.toString() ?? '',
                  ),
                  _buildReadOnlyField('Adresse', profile?['adresse'] ?? ''),
                ],

                // Champs en lecture seule (toujours)
                _buildReadOnlyField(
                  'Rôle',
                  _getRoleDisplayName(profile?['role'] ?? ''),
                ),
                if (profile?['cni'] != null)
                  _buildReadOnlyField('CNI', profile?['cni'] ?? ''),
                if (profile?['dateNaissance'] != null)
                  _buildReadOnlyField(
                    'Date de naissance',
                    profile?['dateNaissance'] ?? '',
                  ),

                // Boutons d'action
                if (isEditing) ...[
                  SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Sauvegarder',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              isEditing = false;
                              selectedImage = null;
                              _populateForm();
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[600],
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            'Annuler',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
