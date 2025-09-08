# Adaptations de l'Application Mobile pour l'API Spring Boot Modifiée

## Résumé des Modifications

L'application mobile Flutter a été adaptée pour correspondre aux modifications apportées à l'API Spring Boot, notamment au niveau du contrôleur de signalements.

## Modifications Principales

### 1. Service de Signalement (`lib/services/signalement_service.dart`)

#### Endpoints Corrigés

- **GET** `/api/signalements/all` - Récupérer tous les signalements
- **GET** `/api/signalements/{id}` - Récupérer un signalement par ID
- **POST** `/api/signalements/add` - Créer un nouveau signalement
- **PUT** `/api/signalements/update/{id}` - Mettre à jour un signalement
- **DELETE** `/api/signalements/delete/{id}` - Supprimer un signalement
- **GET** `/api/signalements/statut/{statut}` - Filtrer par statut
- **GET** `/api/signalements/type/{typeService}` - Filtrer par type de service
- **GET** `/api/signalements/priorite/{priorite}` - Filtrer par priorité
- **GET** `/api/signalements/service/{serviceId}` - Filtrer par service
- **PATCH** `/api/signalements/{id}/statut` - Mettre à jour le statut
- **PATCH** `/api/signalements/{id}/commentaire` - Ajouter un commentaire

#### Nouveaux Champs Supportés

- `trackingId` - Identifiant unique du signalement
- `priorite` - Niveau de priorité (1-3)
- `ouvrierUuid` - UUID de l'ouvrier assigné
- `traiteurUuid` - UUID du traiteur
- `commentaireService` - Commentaire du service
- `fichiers` - Liste des UUIDs des fichiers attachés

#### Gestion de la Structure ApiResponse

Le service gère maintenant la structure `ApiResponse` retournée par l'API :

```json
{
  "success": true,
  "data": {...},
  "message": "..."
}
```

### 2. Modèle de Données (`lib/models/signalement.dart`)

#### Nouvelle Classe Signalement

```dart
class Signalement {
  final String? trackingId;
  final String titre;
  final String code;
  final String description;
  final String statut;
  final String typeService;
  final int serviceId;
  final String? utilisateurCreateur;
  final List<String>? fichiers;
  final String? commentaireService;
  final int? priorite;
  final String? latitude;
  final String? longitude;
  final String? ouvrierUuid;
  final String? traiteurUuid;
}
```

#### Enums Ajoutés

- `TypeService` : SERVICE_HYGIENE, SERVICE_MUNICIPAL
- `StatutSignalement` : EN_ATTENTE, EN_COURS, TRAITE, REJETE, ARCHIVE

### 3. Écran de Création (`lib/screens/signalement.dart`)

#### Paramètres Mis à Jour

- `adresse` → `code`
- `type` → `typeService`
- Ajout de `priorite` et `serviceId`

#### Appel API Modifié

```dart
final result = await SignalementService.createSignalement(
  titre: _titreController.text.trim(),
  description: _descriptionController.text.trim(),
  code: _codeController.text.trim(),
  typeService: _selectedTypeService!,
  latitude: _latitude!,
  longitude: _longitude!,
  priorite: 1, // Priorité par défaut
  serviceId: 1, // Service par défaut
  images: _imageFile != null ? [_imageFile!] : null,
);
```

### 4. Écran de Liste (`lib/screens/signalement_list.dart`)

#### Affichage des Nouveaux Champs

- Priorité avec code couleur
- Statut avec badges colorés
- Type de service avec icônes
- Code/adresse du signalement

## Fonctionnalités Ajoutées

### 1. Filtrage Avancé

- Par statut (EN_ATTENTE, EN_COURS, TRAITE, REJETE, ARCHIVE)
- Par type de service (SERVICE_HYGIENE, SERVICE_MUNICIPAL)
- Par priorité (1, 2, 3)
- Par service (ID du service)

### 2. Gestion des Commentaires

- Ajout de commentaires aux signalements
- Affichage des commentaires du service

### 3. Gestion des Fichiers

- Upload d'images lors de la création
- Association des fichiers aux signalements

### 4. Géolocalisation

- Récupération automatique de la position
- Stockage des coordonnées latitude/longitude

## Compatibilité

### Versions Supportées

- Flutter : 3.0+
- Dart : 2.17+
- http : ^1.1.0
- image_picker : ^1.0.0
- geolocator : ^10.0.0

### Configuration Requise

- Permissions de localisation
- Permissions d'accès à la caméra et galerie
- Connexion Internet pour l'API

## Tests Recommandés

1. **Création de Signalement**

   - Test avec et sans images
   - Test avec différents types de service
   - Test de géolocalisation

2. **Liste et Filtrage**

   - Test de tous les filtres
   - Test de rafraîchissement
   - Test avec données vides

3. **Gestion des Erreurs**
   - Test de connexion perdue
   - Test d'authentification expirée
   - Test de données invalides

## Notes Importantes

- L'URL de base de l'API est configurée dans `SignalementService.baseUrl`
- Les tokens JWT sont gérés automatiquement via `AuthService`
- Les erreurs sont affichées via des SnackBars
- La géolocalisation est requise pour la création de signalements
