import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/signalement.dart';
import '../../models/user.dart';
import '../models/tache.dart' hide Signalement;
import '../services/tache_service.dart';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';
import 'creation_devis.dart';
import 'rapport_avancement_screen.dart';

class SignalementDetailScreen extends StatefulWidget {
  final Signalement signalement;
  final User user;

  const SignalementDetailScreen({
    Key? key,
    required this.signalement,
    required this.user,
  }) : super(key: key);

  @override
  _SignalementDetailScreenState createState() =>
      _SignalementDetailScreenState();
}

class _SignalementDetailScreenState extends State<SignalementDetailScreen> {
  Tache? _tache;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTache();
  }

  Future<void> _loadTache() async {
    try {
      // Essayer de récupérer la tâche associée au signalement
      if (widget.signalement.trackingId != null) {
        // Pour l'instant, on va créer une tâche factice
        // Dans une vraie implémentation, on récupérerait la tâche depuis l'API
        setState(() {
          _tache = Tache(
            id: 1,
            trackingId: widget.signalement.trackingId,
            dateDebut: DateTime.now(),
            dateFin: null,
            isActiver: true,
            isResolu: false,
            signalementTitre: widget.signalement.titre,
            signalementDescription: widget.signalement.description,
            signalementStatut: widget.signalement.statut,
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement de la tâche: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildPhotoGallery() {
    final fichiersPaths =
        widget.signalement.fichiersPaths
            ?.where(
              (path) =>
                  path.toLowerCase().endsWith('.jpg') ||
                  path.toLowerCase().endsWith('.jpeg') ||
                  path.toLowerCase().endsWith('.png'),
            )
            .toList();
    if (fichiersPaths == null || fichiersPaths.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'Aucune photo disponible pour ce signalement.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: fichiersPaths.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final localPath = fichiersPaths[index];
          final fileName = localPath.split(RegExp(r'[\\/]')).last;
          final url = 'http://localhost:8080/Media/images/$fileName';
          return GestureDetector(
            onTap: () => _showPhoto(context, url),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                url,
                width: 180,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      width: 180,
                      height: 180,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPhoto(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(imageUrl, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détail du Signalement'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPhotoGallery(),
                    const SizedBox(height: 16),
                    _buildHeaderCard(),
                    const SizedBox(height: 16),
                    _buildDetailsCard(),
                    const SizedBox(height: 16),
                    _buildLocationCard(),
                    const SizedBox(height: 16),
                    _buildStatusCard(),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.assignment,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.signalement.titre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Code: ${widget.signalement.code}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.signalement.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.category, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Type: ${widget.signalement.typeService}',
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (widget.signalement.priorite != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.priority_high,
                    color: Colors.orange[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Priorité: ${widget.signalement.priorite}',
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Icon(Icons.assignment, color: Colors.green[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Service ID: ${widget.signalement.serviceId}',
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    final lat = widget.signalement.latitude;
    final lng = widget.signalement.longitude;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Localisation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.red[600], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child:
                      lat != null && lng != null
                          ? GestureDetector(
                            onTap: () async {
                              final url =
                                  'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                              try {
                                await launchUrl(
                                  Uri.parse(url),
                                  mode: LaunchMode.externalApplication,
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Impossible d\'ouvrir la carte.',
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              'Voir sur Google Maps',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          )
                          : const Text(
                            'Localisation non disponible',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosCard() {
    final fichiersPaths = widget.signalement.fichiersPaths;
    if (fichiersPaths == null || fichiersPaths.isEmpty) {
      return const SizedBox();
    }
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Photos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: fichiersPaths.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final localPath = fichiersPaths[index];
                  final url = localPath.replaceFirst(
                    'D:/PPE/gestion_communaute_backend/Media/images/',
                    'http://localhost:8080/Media/images/',
                  );
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      url,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            color: Colors.grey[200],
                            width: 120,
                            height: 120,
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                          ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;

    switch (widget.signalement.statut.toUpperCase()) {
      case 'EN_ATTENTE':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'EN_COURS':
        statusColor = Colors.blue;
        statusIcon = Icons.work;
        break;
      case 'TRAITE':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'REJETE':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'ARCHIVE':
        statusColor = Colors.grey;
        statusIcon = Icons.archive;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(statusIcon, color: statusColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statut',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    widget.signalement.statut.replaceAll('_', ' '),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateDevisButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => CreationDevisScreen(
                    signalement: widget.signalement,
                    user: widget.user,
                  ),
            ),
          );

          if (result == true) {
            // Le devis a été créé avec succès
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Devis créé avec succès ! Il a été envoyé à l\'autorité locale.',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        icon: const Icon(Icons.description, color: Colors.white),
        label: const Text(
          'Créer un devis',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),

            // Bouton pour créer un devis (seulement si pas TRAITE, REJETE ou ARCHIVE)
            if (widget.signalement.statut != 'TRAITE' &&
                widget.signalement.statut != 'REJETE' &&
                widget.signalement.statut != 'ARCHIVE')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/create-devis',
                      arguments: widget.signalement,
                    );
                  },
                  icon: const Icon(Icons.description),
                  label: const Text('Créer un Devis'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

            // Espacement conditionnel
            if (widget.signalement.statut != 'TRAITE' &&
                widget.signalement.statut != 'REJETE' &&
                widget.signalement.statut != 'ARCHIVE')
              const SizedBox(height: 12),

            // Bouton pour finaliser l'affaire (seulement si EN_COURS)
            if (widget.signalement.statut == 'EN_COURS')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showFinalisationDialog(),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Finaliser l\'Affaire'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

            // Indicateurs de statut
            if (widget.signalement.statut == 'EN_ATTENTE')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'En attente d\'activation par l\'autorité',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (widget.signalement.statut == 'TRAITE')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Affaire finalisée avec succès',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (widget.signalement.statut == 'REJETE')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Signalement rejeté par l\'autorité',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (widget.signalement.statut == 'ARCHIVE')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                child: Row(
                  children: [
                    Icon(Icons.archive, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Signalement archivé',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showFinalisationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Finaliser l\'Affaire'),
          content: const Text(
            'Êtes-vous sûr de vouloir finaliser cette affaire ? '
            'Cette action indique que le travail est terminé et ne peut pas être annulée.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _finaliserSignalement();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Finaliser'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _finaliserSignalement() async {
    try {
      final success = await TacheService.finaliserSignalement(
        widget.signalement.trackingId ?? '',
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Affaire finalisée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        // Retourner à la page précédente
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la finalisation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
