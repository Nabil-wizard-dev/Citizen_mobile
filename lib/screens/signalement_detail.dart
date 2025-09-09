import 'package:flutter/material.dart';
import '../models/signalement.dart';
import '../services/signalement_service.dart';

class SignalementDetailPage extends StatefulWidget {
  final String signalementId;
  final Map<String, dynamic>? signalementData;

  const SignalementDetailPage({
    required this.signalementId,
    this.signalementData,
    super.key,
  });

  @override
  State<SignalementDetailPage> createState() => _SignalementDetailPageState();
}

class _SignalementDetailPageState extends State<SignalementDetailPage> {
  Map<String, dynamic>? _signalement;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (widget.signalementData != null) {
      _signalement = widget.signalementData;
      _isLoading = false;
    } else {
      _loadSignalementDetail();
    }
  }

  Future<void> _loadSignalementDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await SignalementService.getSignalementById(
        widget.signalementId,
      );

      if (result['success']) {
        setState(() {
          _signalement = result['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Erreur lors du chargement';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    try {
      final statut = StatutSignalement.values.firstWhere(
        (e) => e.value == status,
        orElse: () => StatutSignalement.EN_ATTENTE,
      );
      return Color(int.parse(statut.color.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    try {
      final statut = StatutSignalement.values.firstWhere(
        (e) => e.value == status,
        orElse: () => StatutSignalement.EN_ATTENTE,
      );
      return statut.displayName;
    } catch (e) {
      return status;
    }
  }

  String _getTypeServiceText(String typeService) {
    try {
      final type = TypeService.values.firstWhere(
        (e) => e.value == typeService,
        orElse: () => TypeService.SERVICE_MUNICIPAL,
      );
      return type.displayName;
    } catch (e) {
      return typeService;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Date inconnue';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Date invalide';
    }
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du Signalement'),
        centerTitle: true,
        backgroundColor: const Color(0xff007BFF),
        foregroundColor: Colors.white,

      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xff007BFF)),
                ),
              )
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
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadSignalementDetail,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              )
              : _signalement == null
              ? const Center(child: Text('Signalement non trouvé'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 16),
                    _buildInfoCard(),
                    const SizedBox(height: 16),
                    _buildFilesCard(),
                    if (_signalement!['commentaireService'] != null) ...[
                      const SizedBox(height: 16),
                      _buildCommentCard(),
                    ],
                  ],
                ),
              ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _signalement!['titre'] ?? 'Sans titre',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      _signalement!['statut'] ?? 'EN_ATTENTE',
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(_signalement!['statut'] ?? 'EN_ATTENTE'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _signalement!['description'] ?? 'Aucune description',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations Générales',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Code/Adresse',
              _signalement!['code'] ?? 'Non spécifié',
            ),
            _buildInfoRow(
              'Type de Service',
              _getTypeServiceText(_signalement!['typeService'] ?? ''),
            ),
            _buildInfoRow(
              'Priorité',
              'Niveau ${_signalement!['priorite'] ?? 'Non définie'}',
              valueColor: _getPriorityColor(_signalement!['priorite'] ?? 1),
            ),
            _buildInfoRow(
              'Date de création',
              _formatDate(_signalement!['dateCreation']),
            ),
            _buildInfoRow(
              'prise en charge',
              'oui/non '
            ),
            _buildInfoRow(
                'suivie',
                'pourcentage '
            ),

          ],
        ),
      ),
    );
  }


  Widget _buildFilesCard() {
    final fichiersPaths = _signalement!['fichiersPaths'] as List<dynamic>?;

    if (fichiersPaths == null || fichiersPaths.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.attach_file, color: Color(0xff007BFF)),
                  const SizedBox(width: 8),
                  const Text(
                    'Fichiers',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Aucun fichier joint',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_file, color: Color(0xff007BFF)),
                const SizedBox(width: 8),
                const Text(
                  'Fichiers joints',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xff007BFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${fichiersPaths.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...fichiersPaths.asMap().entries.map((entry) {
              final index = entry.key;
              final path = entry.value as String;
              final fileName = path.split('/').last;
              final extension = fileName.split('.').last.toLowerCase();

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getFileIcon(extension),
                      color: _getFileColor(extension),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Fichier ${extension.toUpperCase()}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () {
                        // TODO: Ouvrir le fichier
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Ouverture du fichier non implémentée',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.comment, color: Color(0xff007BFF)),
                const SizedBox(width: 8),
                const Text(
                  'Commentaire du Service',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(
                _signalement!['commentaireService'],
                style: TextStyle(
                  color: Colors.blue[800],
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label :',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.black87,
                fontWeight:
                    valueColor != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Colors.green;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Colors.red;
      case 'pdf':
        return Colors.red[700]!;
      case 'mp3':
      case 'wav':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
