# Application Mobile Gestion de Communauté

Cette application mobile Flutter a été adaptée pour utiliser l'authentification JWT de votre backend Spring Boot au lieu de Firebase Auth.

## Modifications Apportées

### 1. Services d'Authentification

#### `lib/services/auth_service.dart`

- **Supprimé** : Toutes les dépendances Firebase Auth
- **Ajouté** : Authentification JWT complète
- **Fonctionnalités** :
  - Connexion avec email/mot de passe
  - Inscription avec tous les champs requis
  - Gestion des tokens JWT (sauvegarde/récupération)
  - Vérification de l'état de connexion
  - Déconnexion

#### `lib/services/api_service.dart`

- **Mis à jour** : Pour utiliser l'authentification JWT
- **Ajouté** : Méthode générique pour les requêtes authentifiées
- **Fonctionnalités** :
  - Headers d'autorisation automatiques
  - Gestion des erreurs d'authentification
  - Support pour toutes les méthodes HTTP

#### `lib/services/signalement_service.dart`

- **Créé** : Service complet pour les signalements
- **Fonctionnalités** :
  - CRUD complet des signalements
  - Upload de fichiers/images
  - Requêtes authentifiées automatiques
  - Gestion des erreurs
  - Filtrage par statut et type de service
  - Mise à jour des statuts et commentaires

### 2. Écrans d'Interface

#### `lib/screens/login.dart`

- **Mis à jour** : Pour utiliser AuthService au lieu de Firebase
- **Amélioré** : Validation des champs et gestion d'erreurs
- **Ajouté** : Messages d'erreur personnalisés

#### `lib/screens/signup.dart`

- **Mis à jour** : Suppression de Firebase Auth
- **Ajouté** : Validation complète des champs
- **Amélioré** : Gestion des erreurs et feedback utilisateur

#### `lib/screens/signalement.dart`

- **Complètement refactorisé** : Interface adaptée à l'API backend
- **Fonctionnalités** :
  - Formulaire complet avec validation
  - Géolocalisation automatique
  - Upload d'images optimisé
  - Sélection du type de service (SERVICE_HYGIENE, SERVICE_MUNICIPAL)
  - Choix de la priorité (1-3)
  - Interface utilisateur moderne

#### `lib/screens/signalement_list.dart`

- **Nouvel écran** : Liste des signalements avec filtres
- **Fonctionnalités** :
  - Affichage des signalements avec statuts colorés
  - Filtrage par statut
  - Pull-to-refresh
  - Gestion d'erreurs et états vides
  - Navigation vers création de signalement

#### `lib/screens/profile.dart`

- **Mis à jour** : Pour afficher les données utilisateur JWT
- **Ajouté** : Fonction de déconnexion
- **Amélioré** : Interface utilisateur

#### `lib/screens/home_screen.dart`

- **Mis à jour** : Navigation vers les signalements
- **Ajouté** : Affichage dynamique des signalements récents
- **Fonctionnalités** :
  - Section signalements récents avec données API
  - Navigation vers liste des signalements
  - Bouton flottant pour créer un signalement
  - Menu latéral avec historique des signalements

### 3. Configuration

#### `lib/main.dart`

- **Supprimé** : Initialisation Firebase
- **Mis à jour** : Vérification de l'état de connexion JWT
- **Ajouté** : Thème personnalisé

#### `pubspec.yaml`

- **Supprimé** : Dépendances Firebase
  - `firebase_core`
  - `firebase_auth`
  - `firebase`
- **Ajouté** : Dépendances nécessaires
  - `geolocator: ^10.1.0` - Pour la géolocalisation
- **Conservé** : Dépendances nécessaires pour JWT
  - `http`
  - `shared_preferences`

## Structure de l'Authentification

### Endpoints Backend Utilisés

- `POST /api/auth/login` - Connexion
- `POST /api/auth/register` - Inscription

### Format des Données

#### Login Request

```json
{
  "email": "user@example.com",
  "motDePasse": "password123"
}
```

#### Login Response

```json
{
  "token": "jwt_token_here",
  "expiresIn": 3600000
}
```

#### Register Request

```json
{
  "nom": "Doe",
  "prenom": "John",
  "cni": "123456789",
  "dateNaissance": "01/01/1990",
  "email": "john@example.com",
  "motDePasse": "password123",
  "numero": 123456789,
  "adresse": "123 Rue Example",
  "role": "CITOYEN"
}
```

## Structure des Signalements

### Endpoints Signalements

- `POST /api/signalements` - Création de signalement
- `GET /api/signalements` - Liste des signalements
- `GET /api/signalements/{id}` - Détails d'un signalement
- `PUT /api/signalements/{id}` - Mise à jour
- `DELETE /api/signalements/{id}` - Suppression
- `GET /api/signalements/statut/{statut}` - Filtrage par statut
- `PATCH /api/signalements/{id}/statut` - Mise à jour du statut
- `PATCH /api/signalements/{id}/commentaire` - Ajout de commentaire

### Format Signalement Request

```json
{
  "titre": "Problème de voirie",
  "code": "Rue de la Paix, Lomé",
  "description": "Description détaillée du problème",
  "typeService": "SERVICE_MUNICIPAL",
  "priorite": 2,
  "latitude": "6.1375",
  "longitude": "1.2123"
}
```

### Types de Service

- `SERVICE_HYGIENE` - Service d'Hygiène
- `SERVICE_MUNICIPAL` - Service Municipal

### Statuts de Signalement

- `EN_ATTENTE` - En attente
- `EN_COURS` - En cours de traitement
- `TRAITE` - Traité
- `REJETE` - Rejeté
- `ARCHIVE` - Archivé

### Gestion des Tokens

- **Stockage** : SharedPreferences
- **Format** : Bearer Token dans les headers
- **Expiration** : Gérée par le backend
- **Renouvellement** : À implémenter si nécessaire

## Utilisation

### 1. Installation

```bash
flutter pub get
```

### 2. Configuration de l'URL Backend

Modifiez l'URL du backend dans les services :

- `lib/services/auth_service.dart` (ligne 4)
- `lib/services/api_service.dart` (ligne 4)
- `lib/services/signalement_service.dart` (ligne 4)

### 3. Configuration des Permissions (Android)

Ajouter dans `android/app/src/main/AndroidManifest.xml` :

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### 4. Lancement

```bash
flutter run
```

## Fonctionnalités

### Authentification

- ✅ Connexion avec email/mot de passe
- ✅ Inscription avec validation complète
- ✅ Gestion des tokens JWT
- ✅ Déconnexion
- ✅ Vérification automatique de l'état de connexion

### Signalements

- ✅ Création de signalements avec géolocalisation
- ✅ Upload d'images
- ✅ Liste des signalements avec filtres
- ✅ Détails d'un signalement
- ✅ Mise à jour de statut
- ✅ Suppression
- ✅ Affichage des signalements récents sur l'accueil
- ✅ Navigation intuitive entre les écrans

### Profil Utilisateur

- ✅ Affichage des informations utilisateur
- ✅ Modification du profil (à implémenter)
- ✅ Paramètres de sécurité

### Interface Utilisateur

- ✅ Design moderne et responsive
- ✅ Navigation fluide
- ✅ Gestion d'erreurs et états de chargement
- ✅ Messages de feedback utilisateur
- ✅ Codes couleur pour les statuts

## Sécurité

### JWT

- Tokens stockés de manière sécurisée
- Headers d'autorisation automatiques
- Gestion des erreurs d'authentification

### Validation

- Validation côté client pour une meilleure UX
- Validation côté serveur pour la sécurité
- Messages d'erreur personnalisés

### Géolocalisation

- Permissions demandées de manière appropriée
- Gestion des cas d'erreur
- Fallback en cas de refus de permission

## Prochaines Étapes

1. **Implémenter le renouvellement de tokens**
2. **Ajouter la gestion des rôles utilisateur**
3. **Implémenter la modification du profil**
4. **Ajouter les notifications push**
5. **Optimiser les performances**

## Support

Pour toute question ou problème, consultez la documentation du backend Spring Boot ou contactez l'équipe de développement.
