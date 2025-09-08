# Corrections du Problème de Récursion JSON

## Problème identifié

### Erreur de récursion infinie

**Erreur** : `Document nesting depth (1001) exceeds the maximum allowed (1000, from StreamWriteConstraints.getMaxNestingDepth())`

**Cause** : Références circulaires entre les entités JPA :

- `Ouvrier` → `List<Signalement>`
- `Signalement` → `Ouvrier`
- `AutoriteLocale` → `List<Signalement>`
- `Signalement` → `AutoriteLocale`

## Solutions appliquées

### 1. Annotations Jackson pour éviter la récursion

#### Dans `Ouvrier.java`

```java
@OneToMany(mappedBy = "ouvrier", cascade = CascadeType.ALL, orphanRemoval = true)
@JsonManagedReference
private List<Signalement> signalements = new ArrayList<>();
```

#### Dans `Signalement.java`

```java
@ManyToOne
@JoinColumn(name = "ouvrier_id")
@JsonBackReference
private Ouvrier ouvrier;

@ManyToOne
@JoinColumn(name = "Traiteur_id")
@JsonBackReference
private AutoriteLocale utilisateurTraiteur;
```

#### Dans `AutoriteLocale.java`

```java
@OneToMany(mappedBy = "utilisateurTraiteur", cascade = CascadeType.ALL, orphanRemoval = true)
@JsonManagedReference
private List<Signalement> signalements = new ArrayList<>();
```

### 2. DTOs simples pour les endpoints d'authentification

#### Modification de `AuthentificationServiceImpl.java`

```java
@Override
public Object getCurrentUser() {
    // Retourne un DTO simple au lieu de l'entité complète
    return createUserDTO(user);
}

private Object createUserDTO(Utilisateur user) {
    // Créer un Map simple avec les informations de base
    java.util.Map<String, Object> userDTO = new java.util.HashMap<>();
    userDTO.put("trackingId", user.getTrackingId());
    userDTO.put("nom", user.getNom());
    // ... autres champs
    return userDTO;
}
```

### 3. Configuration Jackson améliorée

#### Dans `ApplicationConfiguration.java`

```java
@Bean
public ObjectMapper objectMapper() {
    return Jackson2ObjectMapperBuilder.json()
            .featuresToDisable(SerializationFeature.FAIL_ON_EMPTY_BEANS)
            .modules(new JavaTimeModule())
            .build();
}
```

### 4. Gestion d'erreurs améliorée côté mobile

#### Dans `auth_service.dart`

```dart
try {
  final userData = json.decode(response.body);
  return userData;
} catch (e) {
  // Détection de réponses JSON tronquées
  if (response.body.contains('...')) {
    print('⚠️ Réponse JSON tronquée détectée, utilisation des données de base');
    return await getUserData();
  }
  return null;
}
```

## Explication des annotations Jackson

### @JsonManagedReference

- Utilisée sur le côté "parent" de la relation
- Indique que cette propriété doit être sérialisée normalement
- Exemple : `Ouvrier` avec sa liste de `Signalement`

### @JsonBackReference

- Utilisée sur le côté "enfant" de la relation
- Indique que cette propriété doit être ignorée lors de la sérialisation
- Évite la récursion infinie
- Exemple : `Signalement` avec sa référence vers `Ouvrier`

## Flux de sérialisation corrigé

### Avant (problématique)

```
Ouvrier → Signalement → Ouvrier → Signalement → ... (infini)
```

### Après (corrigé)

```
Ouvrier → Signalement (sans référence vers Ouvrier)
```

## Avantages des corrections

1. **Élimination de la récursion** : Plus d'erreur de profondeur JSON excessive
2. **Performance améliorée** : Réponses JSON plus légères
3. **Sécurité renforcée** : Évite l'exposition de données sensibles
4. **Maintenabilité** : Code plus clair et prévisible

## Tests recommandés

1. **Test de connexion ouvrier** : Vérifier que les infos ouvrier se chargent correctement
2. **Test de récupération de signalements** : Vérifier l'absence de récursion
3. **Test de performance** : Vérifier la taille des réponses JSON
4. **Test de robustesse** : Vérifier la gestion des erreurs JSON

## Monitoring

- Surveiller les logs pour détecter les réponses JSON tronquées
- Vérifier la taille des réponses dans les outils de développement
- Tester avec des données volumineuses pour s'assurer de la stabilité
