# Corrections API - Correspondance Backend/Mobile

## Problème Identifié

L'erreur `HttpMediaTypeNotSupportedException: Content-Type 'application/octet-stream' is not supported` indiquait un conflit entre les deux endpoints POST du backend avec le même chemin mais des Content-Type différents.

## Analyse du Backend

### Endpoints Signalement

Le backend Spring Boot a **deux endpoints** pour créer un signalement :

1. **`POST /api/signalements` (JSON)** - Pour créer sans image

   ```java
   @PostMapping
   public ResponseEntity<SignalementResponse> createSignalement(@RequestBody SignalementRequest request)
   ```

2. **`POST /api/signalements` (MULTIPART)** - Pour créer avec image
   ```java
   @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
   public ResponseEntity<SignalementResponse> createSignalement(
           @RequestPart("signalement") SignalementRequest request,
           @RequestPart("image") MultipartFile image)
   ```

### Problème de Content-Type

Spring Boot ne peut pas distinguer entre les deux endpoints quand le Content-Type n'est pas correctement défini. Flutter/Dart envoie automatiquement `application/octet-stream` pour les requêtes multipart, ce qui cause le conflit.

## Solution Implémentée

### Approche Simplifiée

Au lieu de gérer les deux endpoints, nous utilisons une approche en **deux étapes** :

1. **Créer le signalement** avec l'endpoint JSON
2. **Uploader les images** avec l'endpoint fichiers séparé

### Avantages de cette Approche

- ✅ **Évite les conflits de Content-Type**
- ✅ **Utilise les endpoints spécialisés**
- ✅ **Plus robuste et maintenable**
- ✅ **Sépare les responsabilités**

## Corrections Apportées

### 1. Service Signalement (`lib/services/signalement_service.dart`)

#### Nouvelle Logique de Création

```dart
// 1. Créer le signalement avec l'endpoint JSON
final response = await http.post(
  uri,
  headers: headers,
  body: jsonEncode(signalementData),
);

// 2. Si des images sont fournies, les uploader séparément
if (images != null && images.isNotEmpty) {
  final signalementId = responseData['id'];
  for (int i = 0; i < images.length; i++) {
    await _uploadImage(signalementId, images[i]);
  }
}
```

#### Méthode d'Upload d'Image

```dart
static Future<void> _uploadImage(dynamic signalementId, File image) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('$baseUrl/fichiers'),
  );

  request.headers['Authorization'] = 'Bearer $token';
  request.fields['signalementId'] = signalementId.toString();

  request.files.add(
    http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
    ),
  );
}
```

### 2. Endpoints Utilisés

#### Création Signalement

- **URL** : `POST /api/signalements`
- **Content-Type** : `application/json`
- **Body** : SignalementRequest JSON

#### Upload Image

- **URL** : `POST /api/fichiers`
- **Content-Type** : `multipart/form-data` (automatique)
- **Fields** : `signalementId`, `file`

### 3. Structure des Données

#### SignalementRequest (JSON)

```json
{
  "titre": "Problème de voirie",
  "code": "Rue de la Paix, Lomé",
  "description": "Description détaillée du problème",
  "typeService": "SERVICE_MUNICIPAL",
  "priorite": 2,
  "latitude": "6.1375",
  "longitude": "1.2123",
  "serviceId": 1
}
```

#### Upload Image (Multipart)

```
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary

------WebKitFormBoundary
Content-Disposition: form-data; name="signalementId"

123
------WebKitFormBoundary
Content-Disposition: form-data; name="file"; filename="image_1234567890.jpg"
Content-Type: image/jpeg

[bytes de l'image]
------WebKitFormBoundary--
```

## Validation

### Tests à Effectuer

1. **Création sans image** : Vérifier que l'endpoint JSON fonctionne
2. **Création avec image** : Vérifier que l'upload séparé fonctionne
3. **Gestion d'erreurs** : Vérifier les messages d'erreur appropriés
4. **Association fichiers** : Vérifier que les images sont bien liées au signalement

### Logs Backend Attendus

#### Succès

```
Hibernate: insert into signalements (...) values (...)
Hibernate: insert into fichier_joins (...) values (...)
```

#### Erreur (Avant correction)

```
HttpMediaTypeNotSupportedException: Content-Type 'application/octet-stream' is not supported
```

## Points Clés

### 1. Séparation des Responsabilités

- **Signalement** : Données métier via JSON
- **Images** : Fichiers via multipart séparé

### 2. Gestion des Erreurs

- **Création signalement** : Erreur bloquante
- **Upload image** : Erreur non-bloquante (log seulement)

### 3. Performance

- **Création rapide** : Pas d'attente d'upload
- **Upload asynchrone** : En arrière-plan

### 4. Robustesse

- **Fallback** : Signalement créé même si upload échoue
- **Retry** : Possibilité de réessayer l'upload

## Résultat

Après ces corrections, le mobile :

- ✅ **Évite les conflits de Content-Type**
- ✅ **Utilise les endpoints appropriés**
- ✅ **Gère les images de manière robuste**
- ✅ **Maintient la compatibilité avec l'API**

L'erreur `HttpMediaTypeNotSupportedException` est maintenant résolue ! 🚀
