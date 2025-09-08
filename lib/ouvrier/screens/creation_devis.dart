import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../models/user.dart';
import '../../models/signalement.dart' as model;
import '../../services/pdf_service.dart';
import '../../services/devis_service.dart';
import 'package:open_file/open_file.dart';

class CreationDevisScreen extends StatefulWidget {
  final model.Signalement signalement;
  final User user;

  const CreationDevisScreen({
    Key? key,
    required this.signalement,
    required this.user,
  }) : super(key: key);

  @override
  State<CreationDevisScreen> createState() => _CreationDevisScreenState();
}

class _CreationDevisScreenState extends State<CreationDevisScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dureeController = TextEditingController();
  final _montantController = TextEditingController();
  final _commentaireController = TextEditingController();

  List<File> _selectedPhotos = [];
  bool _isLoading = false;
  bool _isGeneratingPdf = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Pré-remplir le titre avec le titre du signalement
    _titreController.text = 'Devis pour ${widget.signalement.titre}';
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _dureeController.dispose();
    _montantController.dispose();
    _commentaireController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedPhotos.add(File(image.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection de l\'image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sélectionner une image'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Appareil photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  Future<void> _generateAndSendPdf() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter au moins une photo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isGeneratingPdf = true;
    });

    try {
      // Générer le PDF
      print('📄 Génération du PDF...');
      final pdfFile = await PdfService.genererDevisPdf(
        titre: _titreController.text.trim(),
        description: _descriptionController.text.trim(),
        duree: int.parse(_dureeController.text.trim()),
        montant: double.parse(_montantController.text.trim()),
        commentaireOuvrier:
            _commentaireController.text.trim().isEmpty
                ? null
                : _commentaireController.text.trim(),
        signalement: widget.signalement,
        ouvrier: widget.user,
        photos: _selectedPhotos,
      );

      print('✅ PDF généré: ${pdfFile.path}');
      setState(() {
        _isGeneratingPdf = false;
      });

      // Afficher le PDF généré
      await _showPdfPreview(pdfFile);

      // Envoyer le PDF au backend
      print('📤 Envoi du PDF au backend...');
      final result = await DevisService.envoyerDevisPdf(
        pdfFile: pdfFile,
        titre: _titreController.text.trim(),
        signalement: widget.signalement,
        ouvrier: widget.user,
      );

      if (result['success']) {
        print('✅ Devis créé et associé avec succès');
      }

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Devis envoyé avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retour avec succès
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Erreur lors de l\'envoi du devis',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isGeneratingPdf = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showPdfPreview(File pdfFile) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('PDF généré'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Le PDF a été généré avec succès !',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Taille: ${(pdfFile.lengthSync() / 1024).toStringAsFixed(1)} KB',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Continuer'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await OpenFile.open(pdfFile.path);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors de l\'ouverture: $e'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              child: const Text('Voir le PDF'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un devis'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informations du signalement
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Signalement concerné',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.signalement.titre,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        widget.signalement.description,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),

              // Titre du devis
              TextFormField(
                controller: _titreController,
                decoration: const InputDecoration(
                  labelText: 'Titre du devis *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le titre est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description des travaux *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La description est requise';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Durée et Montant
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dureeController,
                      decoration: const InputDecoration(
                        labelText: 'Durée (jours) *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.schedule),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La durée est requise';
                        }
                        if (int.tryParse(value.trim()) == null) {
                          return 'Veuillez entrer un nombre valide';
                        }
                        if (int.parse(value.trim()) <= 0) {
                          return 'La durée doit être positive';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _montantController,
                      decoration: const InputDecoration(
                        labelText: 'Montant (FCFA) *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le montant est requis';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Veuillez entrer un montant valide';
                        }
                        if (double.parse(value.trim()) <= 0) {
                          return 'Le montant doit être positif';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Commentaire
              TextFormField(
                controller: _commentaireController,
                decoration: const InputDecoration(
                  labelText: 'Commentaire (optionnel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.comment),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Photos
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Photos du devis *',
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E3A8A),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _showImageSourceDialog,
                            icon: const Icon(Icons.add_a_photo),
                            label: const Text('Ajouter'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ajoutez au moins une photo pour documenter les travaux',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 16),

                      if (_selectedPhotos.isNotEmpty) ...[
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: _selectedPhotos.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _selectedPhotos[index],
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removePhoto(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ] else ...[
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade300,
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.photo_library,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Aucune photo sélectionnée',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Bouton de soumission
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _generateAndSendPdf,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child:
                      _isLoading
                          ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isGeneratingPdf) ...[
                                const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text('Génération du PDF...'),
                              ] else ...[
                                const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text('Envoi en cours...'),
                              ],
                            ],
                          )
                          : const Text(
                            'Générer et envoyer le devis',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
