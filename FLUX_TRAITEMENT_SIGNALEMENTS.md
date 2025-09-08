# Flux de Traitement des Signalements - Implémentation Mobile

## 📋 Concept du Flux

### 1. Création du Signalement (Citoyen)

- Le citoyen crée un signalement via l'application mobile
- Le signalement est envoyé au backend avec photos et géolocalisation
- Statut initial : `EN_ATTENTE`

### 2. Assignment par l'Admin

- L'administrateur voit le signalement dans l'interface web
- Il assigne un ouvrier au signalement
- Le `trackingId` du signalement est ajouté à l'ouvrier (`signalementActuelId`)

### 3. Traitement par l'Ouvrier (Mobile)

- L'ouvrier voit ses signalements assignés dans l'app mobile
- Il clique sur un signalement pour le traiter
- Il rédige un document de traitement avec photos
- Il envoie le document à l'autorité locale

## 🏗️ Architecture Implémentée

### Pages Créées

#### 1. `TachesListScreen` (Liste des Signalements)

- **Fichier** : `lib/ouvrier/screens/taches_list.dart`
- **Fonction** : Affiche tous les signalements assignés à l'ouvrier
- **Fonctionnalités** :
  - Récupération des signalements via API
  - Affichage avec statuts colorés
  - Navigation vers le détail
  - Pull-to-refresh
  - Gestion des erreurs

#### 2. `SignalementDetailScreen` (Détail du Signalement)

- **Fichier** : `lib/ouvrier/screens/signalement_detail.dart`
- **Fonction** : Affiche les détails complets d'un signalement
- **Fonctionnalités** :
  - Informations complètes du signalement
  - Localisation
  - Statut avec indicateurs visuels
  - Bouton pour traiter le signalement

#### 3. `TraitementSignalementScreen` (Traitement)

- **Fichier** : `lib/ouvrier/screens/traitement_signalement.dart`
- **Fonction** : Interface pour traiter un signalement
- **Fonctionnalités** :
  - Formulaire de document de traitement
  - Capture de photos
  - Sélection du nouveau statut
  - Envoi à l'autorité locale

### Services Créés/Modifiés

#### 1. `SignalementService`

- **Méthode ajoutée** : `getSignalementsByOuvrier()`
- **Fonction** : Récupère les signalements assignés à un ouvrier
- **Endpoint** : `GET /api/signalements/allByOuvrier/{ouvrierId}`

#### 2. `TacheService`

- **Méthodes ajoutées** :
  - `createTraitementDocument()` : Crée un document de traitement
  - `updateSignalementStatus()` : Met à jour le statut du signalement
- **Endpoints** :
  - `POST /api/taches/add` : Créer une tâche
  - `PATCH /api/signalements/{id}/statut` : Mettre à jour le statut

## 🔄 Flux Technique

### 1. Récupération des Signalements

```dart
// Dans TachesListScreen
final result = await SignalementService.getSignalementsByOuvrier(trackingId);
if (result['success']) {
  _signalements = (result['data'] as List)
    .map((json) => Signalement.fromJson(json))
    .toList();
}
```

### 2. Navigation vers le Détail

```dart
// Dans TachesListScreen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => SignalementDetailScreen(
      signalement: signalement,
      user: widget.user,
    ),
  ),
);
```

### 3. Création du Document de Traitement

```dart
// Dans TraitementSignalementScreen
final success = await TacheService.createTraitementDocument(
  signalementId: widget.signalement.trackingId ?? '',
  titre: _titreController.text.trim(),
  description: _descriptionController.text.trim(),
  commentaire: _commentaireController.text.trim(),
  cout: _coutController.text.trim(),
  duree: _dureeController.text.trim(),
  statut: _selectedStatut,
  photos: _photos.isNotEmpty ? _photos : null,
);
```

### 4. Mise à Jour du Statut

```dart
// Dans TraitementSignalementScreen
final statusSuccess = await TacheService.updateSignalementStatus(
  signalementId: widget.signalement.trackingId ?? '',
  newStatus: _selectedStatut,
  commentaire: _commentaireController.text.trim(),
);
```

## 📱 Interface Utilisateur

### Design System

- **Couleurs principales** : `#1E3A8A` (bleu foncé)
- **Couleurs secondaires** : `#3B82F6` (bleu clair)
- **Statuts colorés** :
  - `EN_ATTENTE` : Orange
  - `EN_COURS` : Bleu
  - `TRAITE` : Vert
  - `REJETE` : Rouge
  - `ARCHIVE` : Gris

### Composants UI

- **Cards** : Design moderne avec ombres et coins arrondis
- **Buttons** : Style cohérent avec gradients
- **Form Fields** : Validation et indicateurs visuels
- **Status Badges** : Indicateurs colorés pour les statuts
- **Photo Gallery** : Affichage des photos avec possibilité de suppression

## 🔧 Fonctionnalités Techniques

### Gestion des Photos

- **Capture** : Appareil photo intégré
- **Galerie** : Sélection depuis la galerie
- **Compression** : Qualité 80% pour optimiser la taille
- **Upload** : Envoi multipart vers le backend

### Validation des Formulaires

- **Champs requis** : Titre, description, coût, durée
- **Validation numérique** : Coût et durée
- **Feedback utilisateur** : Messages d'erreur contextuels

### Gestion d'État

- **Loading states** : Indicateurs de chargement
- **Error handling** : Gestion gracieuse des erreurs
- **Success feedback** : Confirmations de succès

## 🔒 Sécurité

### Authentification

- **JWT Token** : Authentification requise pour toutes les requêtes
- **Headers** : `Authorization: Bearer {token}`
- **Validation** : Vérification du token avant chaque requête

### Validation des Données

- **Côté client** : Validation des formulaires
- **Côté serveur** : Validation des données reçues
- **Sanitisation** : Nettoyage des entrées utilisateur

## 📊 Monitoring et Debug

### Logs

- **Requêtes API** : Status codes et réponses
- **Erreurs** : Stack traces et messages d'erreur
- **Performance** : Temps de réponse des requêtes

### Debug

- **Console logs** : Informations détaillées pour le développement
- **Error boundaries** : Capture des erreurs non gérées
- **Network inspection** : Vérification des requêtes HTTP

## 🚀 Déploiement

### Prérequis

- Backend Spring Boot fonctionnel
- Endpoints API disponibles
- Base de données configurée

### Configuration

- **URLs API** : Configurées dans les services
- **Timeout** : Gestion des timeouts réseau
- **Retry logic** : Logique de retry pour les requêtes échouées

## 🔄 Workflow Complet

1. **Ouvrier se connecte** → Vérification du token
2. **Chargement des signalements** → Appel API `/signalements/allByOuvrier/{id}`
3. **Affichage de la liste** → Interface avec statuts colorés
4. **Clic sur un signalement** → Navigation vers le détail
5. **Consultation des détails** → Informations complètes affichées
6. **Clic sur "Traiter"** → Navigation vers le formulaire de traitement
7. **Remplissage du formulaire** → Validation des champs
8. **Capture de photos** → Upload des images
9. **Soumission** → Création du document et mise à jour du statut
10. **Confirmation** → Retour à la liste avec statut mis à jour

## 📈 Améliorations Futures

### Fonctionnalités à Ajouter

- **Notifications push** : Alertes pour nouveaux signalements
- **Géolocalisation** : Navigation vers le lieu du signalement
- **Chat** : Communication avec l'autorité locale
- **Historique** : Suivi des modifications de statut
- **Rapports** : Génération de rapports PDF

### Optimisations

- **Cache** : Mise en cache des données
- **Offline mode** : Fonctionnement hors ligne
- **Sync** : Synchronisation des données
- **Performance** : Optimisation des requêtes
