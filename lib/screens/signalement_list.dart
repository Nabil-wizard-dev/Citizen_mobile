import 'package:flutter/material.dart';
import '../services/signalement_service.dart';
import '../models/signalement.dart';
import 'signalement.dart';
import 'signalement_detail.dart';

class SignalementListPage extends StatefulWidget {
  const SignalementListPage({super.key});

  @override
  State<SignalementListPage> createState() => _SignalementListPageState();
}

class _SignalementListPageState extends State<SignalementListPage> {
  List<dynamic> _signalements = [];
  bool _isLoading = true;
  String _selectedFilter = 'Tous';
  String _errorMessage = '';

  final List<String> _filters = [
    'Tous',
    'EN_ATTENTE',
    'EN_COURS',
    'TRAITE',
    'REJETE',
    'ARCHIVE',
  ];

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

    try {
      Map<String, dynamic> result;

      if (_selectedFilter == 'Tous') {
        print('Chargement de tous les signalements...');
        result = await SignalementService.getSignalements();
      } else {
        print('Chargement des signalements avec filtre: $_selectedFilter');
        result = await SignalementService.getSignalementsByStatut(
          _selectedFilter,
        );
      }

      print('Résultat du chargement: $result');

      if (result['success']) {
        print(
          'Nombre de signalements récupérés: ${result['data']?.length ?? 0}',
        );
        setState(() {
          _signalements = result['data'] ?? [];
          _isLoading = false;
        });
      } else {
        print('Erreur lors du chargement: ${result['message']}');
        setState(() {
          _errorMessage = result['message'] ?? 'Erreur lors du chargement';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Exception lors du chargement: $e');
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  void _onFilterChanged(String? newFilter) {
    if (newFilter != null && newFilter != _selectedFilter) {
      setState(() {
        _selectedFilter = newFilter;
      });
      _loadSignalements();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Signalements'),
        centerTitle: true,
        backgroundColor: const Color(0xff007BFF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSignalements,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres
          Container(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Filtrer par statut',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              value: _selectedFilter,
              items:
                  _filters
                      .map(
                        (filter) => DropdownMenuItem<String>(
                          value: filter,
                          child: Text(
                            filter == 'Tous'
                                ? 'Tous les signalements'
                                : _getStatusText(filter),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: _onFilterChanged,
            ),
          ),

          // Liste des signalements
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xff007BFF),
                        ),
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
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
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
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun signalement trouvé',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
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
                          final signalement = _signalements[index];
                          return _buildSignalementCard(signalement);
                        },
                      ),
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SignalementPage()),
          );
          if (result == true) {
            _loadSignalements();
          }
        },
        backgroundColor: const Color(0xff007BFF),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSignalementCard(Map<String, dynamic> signalement) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => SignalementDetailPage(
                    signalementId:
                        signalement['trackingId'] ?? signalement['id'] ?? '',
                    signalementData: signalement,
                  ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      signalement['titre'] ?? 'Sans titre',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        signalement['statut'] ?? 'EN_ATTENTE',
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(signalement['statut'] ?? 'EN_ATTENTE'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                signalement['description'] ?? 'Aucune description',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.category, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _getTypeServiceText(signalement['typeService'] ?? ''),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const Spacer(),
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    signalement['code'] ?? 'Adresse non spécifiée',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Créé le ${_formatDate(signalement['dateCreation'])}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const Spacer(),
                  if (signalement['priorite'] != null)
                    Row(
                      children: [
                        Icon(
                          Icons.priority_high,
                          size: 16,
                          color: _getPriorityColor(signalement['priorite']),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Priorité ${signalement['priorite']}',
                          style: TextStyle(
                            color: _getPriorityColor(signalement['priorite']),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Date inconnue';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
}
