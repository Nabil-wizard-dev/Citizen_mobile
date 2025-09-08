# Adaptations de l'Authentification pour l'API Spring Boot Modifiée

## Résumé des Modifications

L'authentification de l'application mobile Flutter a été adaptée pour correspondre aux modifications apportées à l'API Spring Boot, notamment au niveau des contrôleurs d'authentification.

## Modifications Principales

### 1. Service d'Authentification (`lib/services/auth_service.dart`)

#### Gestion de la Structure ApiResponse

Le service gère maintenant la structure `ApiResponse` retournée par l'API :

```json
{
  "success": true,
  "data": {...},
  "message": "..."
}
```

#### Connexion (Login)

- **Endpoint** : `POST /api/auth/login`
- **Corps de la requête** :
  ```json
  {
    "email": "user@example.com",
    "motDePasse": "password123"
  }
  ```
- **Réponse attendue** :
  ```json
  {
    "token": "jwt_token_here",
    "expiresIn": 3600
  }
  ```

#### Inscription (Register)

- **Endpoint** : `POST /api/auth/register`
- **Corps de la requête** :
  ```json
  {
    "nom": "Doe",
    "prenom": "John",
    "cni": "123456789",
    "dateNaissance": "01/01/1990",
    "email": "john.doe@example.com",
    "motDePasse": "password123",
    "numero": 12345678,
    "adresse": "123 Rue de la Paix, Lomé",
    "role": "CITOYEN"
  }
  ```

### 2. Modèle Utilisateur (`lib/models/user.dart`)

#### Nouvelle Classe User

```dart
class User {
  final String? trackingId;
  final String nom;
  final String prenom;
  final String cni;
  final String dateNaissance;
  final String email;
  final int numero;
  final String adresse;
  final String role;
}
```

#### Enums Ajoutés

- `UtilisateurRole` : ADMINISTRATEUR, AUTORITE_LOCALE, OUVRIER, CITOYEN, SERVICE_HYGIENE, SERVICE_MUNICIPAL

### 3. Écrans d'Authentification

#### Écran de Connexion (`lib/screens/login.dart`)

- ✅ **Validation des champs** : Email et mot de passe
- ✅ **Gestion des erreurs** : Affichage des messages d'erreur de l'API
- ✅ **Redirection** : Vers l'écran principal après connexion réussie
- ✅ **Sauvegarde du token** : Stockage automatique du JWT

#### Écran d'Inscription (`lib/screens/signup.dart`)

- ✅ **Tous les champs requis** : Nom, prénom, CNI, date de naissance, email, mot de passe, numéro, adresse
- ✅ **Validation complète** : Email, mot de passe, confirmation, numéro de téléphone
- ✅ **Sélecteur de date** : Pour la date de naissance
- ✅ **Rôle par défaut** : CITOYEN pour les nouveaux utilisateurs
- ✅ **Format du numéro** : Préfixe +228 automatique

## Fonctionnalités d'Authentification

### 1. Gestion des Tokens JWT

- **Sauvegarde automatique** : Le token est sauvegardé localement après connexion
- **Récupération automatique** : Le token est récupéré pour les requêtes authentifiées
- **Nettoyage** : Le token est supprimé lors de la déconnexion

### 2. Persistance des Données

- **SharedPreferences** : Stockage local des tokens et données utilisateur
- **Sécurité** : Données chiffrées localement
- **Persistance** : Les données persistent entre les sessions

### 3. Validation des Champs

- **Email** : Format email valide
- **Mot de passe** : Minimum 6 caractères
- **CNI** : Champ requis
- **Numéro de téléphone** : Format togolais (+228)
- **Date de naissance** : Sélecteur de date

## Rôles Utilisateur Supportés

### 1. CITOYEN (Par défaut)

- Accès aux fonctionnalités de base
- Création de signalements
- Consultation de ses signalements

### 2. ADMINISTRATEUR

- Accès complet à toutes les fonctionnalités
- Gestion des utilisateurs
- Gestion des signalements

### 3. AUTORITE_LOCALE

- Gestion des signalements locaux
- Attribution des tâches

### 4. OUVRIER

- Consultation des tâches assignées
- Mise à jour du statut des travaux

### 5. SERVICE_HYGIENE

- Gestion des signalements d'hygiène
- Traitement des demandes

### 6. SERVICE_MUNICIPAL

- Gestion des signalements municipaux
- Coordination des services

## Gestion des Erreurs

### 1. Erreurs de Connexion

- **Email invalide** : Validation du format
- **Mot de passe incorrect** : Message d'erreur de l'API
- **Compte inexistant** : Redirection vers l'inscription
- **Erreur réseau** : Message d'erreur générique

### 2. Erreurs d'Inscription

- **Email déjà utilisé** : Message d'erreur de l'API
- **CNI déjà enregistré** : Validation côté serveur
- **Données invalides** : Validation côté client et serveur
- **Erreur réseau** : Message d'erreur générique

## Sécurité

### 1. Validation Côté Client

- **Champs requis** : Validation avant envoi
- **Format des données** : Validation des formats
- **Confirmation** : Confirmation du mot de passe

### 2. Validation Côté Serveur

- **Authentification** : Vérification des credentials
- **Autorisation** : Vérification des rôles
- **Intégrité** : Validation des données

### 3. Stockage Sécurisé

- **Tokens JWT** : Stockage local sécurisé
- **Données utilisateur** : Chiffrement local
- **Nettoyage** : Suppression des données sensibles

## Tests Recommandés

### 1. Tests de Connexion

- ✅ Connexion avec credentials valides
- ✅ Connexion avec email invalide
- ✅ Connexion avec mot de passe incorrect
- ✅ Connexion sans connexion réseau

### 2. Tests d'Inscription

- ✅ Inscription avec données valides
- ✅ Inscription avec email déjà utilisé
- ✅ Inscription avec CNI déjà enregistré
- ✅ Inscription avec données invalides

### 3. Tests de Persistance

- ✅ Sauvegarde du token après connexion
- ✅ Récupération du token au redémarrage
- ✅ Nettoyage des données après déconnexion

## Configuration Requise

### 1. Permissions

- **Internet** : Accès à l'API
- **Stockage** : Sauvegarde des données locales

### 2. Dépendances

- **http** : Requêtes HTTP
- **shared_preferences** : Stockage local
- **flutter_secure_storage** : Stockage sécurisé (optionnel)

### 3. Variables d'Environnement

- **baseUrl** : URL de l'API d'authentification
- **timeout** : Timeout des requêtes

## Notes Importantes

- L'URL de base de l'API est configurée dans `AuthService.baseUrl`
- Les tokens JWT sont gérés automatiquement
- Les erreurs sont affichées via des SnackBars
- La validation est effectuée côté client et serveur
- Les données utilisateur sont persistées localement
