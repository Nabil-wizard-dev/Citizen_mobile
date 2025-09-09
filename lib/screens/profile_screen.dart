import 'package:flutter/material.dart';
import 'dart:io';
import '../models/user.dart';
import '../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  final User user;
  final Function(String?)?
  onProfileUpdated; // Modifier pour accepter l'URL de la photo

  const ProfileScreen({super.key, required this.user, this.onProfileUpdated});

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
      print('🔄 Chargement des données du profil...');
      final result = await ProfileService.getProfile();
      print('📊 Résultat du profil: $result');
      
      if (result['success']) {
        setState(() {
          profile = result['data'];
          print('✅ Profil chargé: $profile');
          _populateForm();
          if (profile!['photoProfil'] != null && profile!['photoProfil'].toString().isNotEmpty) {
            currentPhotoUrl = 'http://192.168.1.70:8080/${profile!['photoProfil']}';
            print('📸 URL de la photo: $currentPhotoUrl');
          } else {
            currentPhotoUrl = null;
            print('📸 Aucune photo de profil');
          }
        });

        // Passer la photo à l'AppBar dès le chargement
        widget.onProfileUpdated?.call(currentPhotoUrl);
      } else {
        print('❌ Erreur lors du chargement du profil: ${result['message']}');
      }
    } catch (e) {
      print('❌ Exception lors du chargement du profil: $e');
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
      case 'AUTORITE_LOCALE':
        return 'Autorité Locale';
      case 'ADMINISTRATEUR':
        return 'Administrateur';
      case 'SERVICE_HYGIENE':
        return 'Service d\'Hygiène';
      case 'SERVICE_MUNICIPAL':
        return 'Service Municipal';
      default:
        return role;
    }
  }

  Widget _buildInfoField(
    String label,
    TextEditingController controller, {
    bool isReadOnly = false,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: const Color(0xFF1E3A8A),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            enabled: isEditing && !isReadOnly,
            decoration: InputDecoration(
              filled: true,
              fillColor: isEditing ? Colors.white : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: const Color(0xFF1E3A8A),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF334155),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
        ),
      );
    }

    // Si le profil n'est pas chargé, utiliser les données de l'utilisateur
    if (profile == null) {
      print('⚠️ Profil non chargé, utilisation des données utilisateur');
      profile = {
        'nom': widget.user.nom,
        'prenom': widget.user.prenom,
        'email': widget.user.email,
        'numero': widget.user.numero,
        'adresse': widget.user.adresse,
        'role': widget.user.role,
        'trackingId': widget.user.trackingId,
        'cni': widget.user.cni,
        'dateNaissance': widget.user.dateNaissance,
        'photoProfil': widget.user.photoProfil,
      };
      _populateForm();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // En-tête avec photo de profil
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                // Photo de profil
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1E3A8A),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 3,
                          ),
                        ),
                        child: ClipOval(
                          child: selectedImage != null
                              ? Image.file(selectedImage!, fit: BoxFit.cover)
                              : currentPhotoUrl != null
                                  ? Image.network(
                                      currentPhotoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.person, size: 50, color: Colors.white),
                        ),
                      ),
                      if (isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1E3A8A),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Nom complet
                Text(
                  '${profile?['prenom'] ?? ''} ${profile?['nom'] ?? ''}'.trim(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),

                const SizedBox(height: 8),

                // Rôle avec badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.3)),
                  ),
                  child: Text(
                    _getRoleDisplayName(profile?['role'] ?? ''),
                    style: const TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Indicateur de photo sélectionnée
                if (selectedImage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Photo sélectionnée',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Informations du profil
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: const Text(
                        'Informations personnelles',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                    if (!isEditing)
                      GestureDetector(
                        onTap: () => setState(() => isEditing = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
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

                const SizedBox(height: 24),

                // Champs éditables
                if (isEditing) ...[
                  _buildInfoField('Nom', _nomController, icon: Icons.person),
                  _buildInfoField('Prénom', _prenomController, icon: Icons.person_outline),
                  _buildInfoField('Email', _emailController, icon: Icons.email),
                  _buildInfoField('Numéro de téléphone', _numeroController, icon: Icons.phone),
                  _buildInfoField('Adresse', _adresseController, icon: Icons.location_on),
                ] else ...[
                  // Champs en lecture seule
                  _buildReadOnlyField('Nom', profile?['nom'] ?? '', icon: Icons.person),
                  _buildReadOnlyField('Prénom', profile?['prenom'] ?? '', icon: Icons.person_outline),
                  _buildReadOnlyField('Email', profile?['email'] ?? '', icon: Icons.email),
                  _buildReadOnlyField(
                    'Numéro de téléphone',
                    profile?['numero']?.toString() ?? '',
                    icon: Icons.phone,
                  ),
                  _buildReadOnlyField('Adresse', profile?['adresse'] ?? '', icon: Icons.location_on),
                ],

                // Champs en lecture seule (toujours)
                _buildReadOnlyField(
                  'Rôle',
                  _getRoleDisplayName(profile?['role'] ?? ''),
                  icon: Icons.work,
                ),
                if (profile?['trackingId'] != null)
                  _buildReadOnlyField('ID de suivi', profile?['trackingId'] ?? '', icon: Icons.fingerprint),
                if (profile?['cni'] != null)
                  _buildReadOnlyField('CNI', profile?['cni'] ?? '', icon: Icons.credit_card),
                if (profile?['dateNaissance'] != null)
                  _buildReadOnlyField(
                    'Date de naissance',
                    profile?['dateNaissance'] ?? '',
                    icon: Icons.cake,
                  ),

                // Boutons d'action
                if (isEditing) ...[
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Sauvegarder',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
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
                            foregroundColor: const Color(0xFF64748B),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          child: const Text(
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
