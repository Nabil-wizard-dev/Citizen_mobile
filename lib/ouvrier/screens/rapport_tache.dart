import 'package:flutter/material.dart';

class RapportTacheScreen extends StatefulWidget {
  final int tacheId;
  const RapportTacheScreen({required this.tacheId, super.key});

  @override
  State<RapportTacheScreen> createState() => _RapportTacheScreenState();
}

class _RapportTacheScreenState extends State<RapportTacheScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  final List<String> _photos = [];

  void _ajouterPhoto() async {
    // TODO: Ajouter la logique pour sélectionner une photo
    setState(() {
      _photos.add('photo_mock.png');
    });
  }

  void _envoyerRapport() async {
    setState(() => _isLoading = true);
    // TODO: Appeler le service pour envoyer le rapport
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rapport d\'intervention')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Décrivez ce qui a été fait',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _ajouterPhoto,
                  child: const Text('Ajouter une photo'),
                ),
                const SizedBox(width: 10),
                Text('${_photos.length} photo(s) ajoutée(s)'),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _envoyerRapport,
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Envoyer le rapport'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
