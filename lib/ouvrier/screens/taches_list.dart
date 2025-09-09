import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/signalement.dart' as model;
import '../../services/signalement_service.dart';
import 'signalement_detail.dart';
import 'rapport_avancement_screen.dart';

class TachesListScreen extends StatefulWidget {
  final User user;
  const TachesListScreen({required this.user, super.key});

  @override
  State<TachesListScreen> createState() => _TachesListScreenState();
}

class _TachesListScreenState extends State<TachesListScreen> {
  List<model.Signalement> _signalements = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSignalements();
  }

  Future<void> _loadSignalements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final trackingId = widget.user.trackingId;
    print('🔍 Tentative de chargement des signalements pour l\'ouvrier');
    print('👤 Utilisateur: ${widget.user.nom} ${widget.user.prenom}');
    print('🆔 TrackingId: $trackingId');
    print('📧 Email: ${widget.user.email}');
    print('🎭 Rôle: ${widget.user.role}');

    if (trackingId == null || trackingId.isEmpty) {
      final errorMsg =
          'Erreur : Impossible de récupérer les signalements, trackingId manquant.';
      print('❌ $errorMsg');
      print('📊 Données utilisateur complètes: ${widget.user.toJson()}');
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
      return;
    }

    try {
      print('🌐 Appel de l\'API: /api/signalements/allByOuvrier/$trackingId');
      final result = await SignalementService.getSignalementsByOuvrier(
        trackingId,
      );
      print('📡 Réponse API: $result');

      final data = result['data'];
      final isApiSuccess =
          result['success'] == true ||
          (result['message'] == 'succes' &&
              data != null &&
              data is List &&
              data.isNotEmpty);

      if (isApiSuccess) {
        print(
          '✅ Signalements récupérés avec succès: ${data.length} signalements',
        );
        setState(() {
          _signalements =
              data
                  .map<model.Signalement>(
                    (json) => model.Signalement.fromJson(json),
                  )
                  .toList();
          _isLoading = false;
        });
      } else {
        final errorMsg = result['message'] ?? 'Erreur lors du chargement';
        print('❌ Échec de récupération: $errorMsg');
        setState(() {
          _errorMessage = errorMsg;
          _isLoading = false;
        });
      }
    } catch (e) {
      final errorMsg = 'Erreur lors du chargement: $e';
      print('❌ Exception: $errorMsg');
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    }
  }

  // Ajout de la fonction pour visualiser une photo en grand
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
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadSignalements,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              )
              : _signalements.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun signalement assigné',
                      style: TextStyle(color: Colors.grey[600], fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Les signalements qui vous seront assignés apparaîtront ici',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadSignalements,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _signalements.length,
                  itemBuilder: (context, index) {
                    return _buildSignalementCard(_signalements[index]);
                  },
                ),
              ),
    );
  }

  Widget _buildSignalementCard(model.Signalement signalement) {
    Color statusColor;
    IconData statusIcon;

    switch (signalement.statut) {
      case 'EN_ATTENTE':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'EN_COURS':
        statusColor = Colors.blue;
        statusIcon = Icons.play_circle;
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
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap:
            signalement.statut == 'EN_COURS'
                ? null
                : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => SignalementDetailScreen(
                            signalement: signalement,
                            user: widget.user,
                          ),
                    ),
                  );
                },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          signalement.titre,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          signalement.titre,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          signalement.statut.replaceAll('_', ' '),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                signalement.description,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.category, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 4),
                  Text(
                    signalement.typeService,
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (signalement.priorite != null) ...[
                    Icon(
                      Icons.priority_high,
                      size: 16,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Priorité ${signalement.priorite}',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.red[600]),
                  const SizedBox(width: 4),
                  Text(
                    signalement.latitude != null &&
                            signalement.longitude != null
                        ? '${signalement.latitude}, ${signalement.longitude}'
                        : 'Localisation non disponible',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Bouton "Active" pour les signalements activés, sinon "Toucher pour traiter"
              if (signalement.statut == 'EN_COURS')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => RapportAvancementScreen(
                                signalement: signalement,
                                user: widget.user,
                              ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.assignment_turned_in,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Toucher pour traiter',
                      style: TextStyle(
                        color: const Color(0xFF1E3A8A),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: const Color(0xFF1E3A8A),
                      size: 12,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
