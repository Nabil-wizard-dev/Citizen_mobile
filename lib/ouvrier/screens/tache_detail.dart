import 'package:flutter/material.dart';
import '../models/tache.dart';

class TacheDetailScreen extends StatelessWidget {
  final Tache tache;
  const TacheDetailScreen({required this.tache, super.key});

  @override
  Widget build(BuildContext context) {
    final signalement = tache.signalement;
    return Scaffold(
      appBar: AppBar(title: const Text('Détail de la Tâche')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Titre: ${signalement?.titre ?? "-"}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Description: ${signalement?.description ?? "-"}'),
            const SizedBox(height: 8),
            Text('Statut: ${tache.isResolu ? "Résolue" : "En cours"}'),
            const SizedBox(height: 8),
            Text('Priorité: ${signalement?.priorite ?? "-"}'),
            const SizedBox(height: 8),
            Text(
              'Localisation: ${signalement?.latitude ?? "-"}, ${signalement?.longitude ?? "-"}',
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // TODO: Naviguer vers l'écran de traitement
              },
              child: const Text('Commencer le traitement'),
            ),
          ],
        ),
      ),
    );
  }
}
