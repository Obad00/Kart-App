import 'package:firebase_core/firebase_core.dart';

/// Config Firebase pour la cible Web uniquement — Android/iOS lisent
/// automatiquement google-services.json / GoogleService-Info.plist au
/// build, mais le web n'a pas d'équivalent : ces valeurs doivent être
/// passées explicitement à `Firebase.initializeApp(options: ...)`
/// (voir PushNotificationService.init()).
///
/// ⚠️ [apiKey] et [appId] sont des PLACEHOLDERS à remplacer : le projet
/// Firebase "kart-e3274" n'a encore aucune app Web enregistrée (seulement
/// Android et iOS). Pour les obtenir :
/// 1. Console Firebase → ⚙️ Paramètres du projet → onglet "Général"
/// 2. Section "Vos applications" → bouton "Ajouter une application" → icône
///    Web (`</>`)
/// 3. Donne-lui un nom (ex. "KART Web") — pas besoin d'activer l'hébergement
///    Firebase, juste enregistrer l'app
/// 4. Copie `apiKey` et `appId` depuis l'objet `firebaseConfig` affiché
///
/// (messagingSenderId, projectId, storageBucket et authDomain sont déjà
/// corrects : ce sont des valeurs partagées par toutes les apps du projet,
/// reprises de android/app/google-services.json.)
const webFirebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyCtAp17SoDDEyYPQu_FTmyiNiahA8MjeoY',
  appId: '1:572176532309:web:ec640f9f654acd649725dc',
  messagingSenderId: '572176532309',
  projectId: 'kart-e3274',
  authDomain: 'kart-e3274.firebaseapp.com',
  storageBucket: 'kart-e3274.firebasestorage.app',
);

/// Clé VAPID ("Web Push certificates") — nécessaire pour que
/// `FirebaseMessaging.getToken()` fonctionne sur le web (pas requis sur
/// mobile, où le token est géré nativement par les Google/Apple push
/// services). À récupérer dans :
/// Console Firebase → ⚙️ Paramètres du projet → onglet "Cloud Messaging" →
/// section "Configuration Web" → "Générer une paire de clés" si aucune
/// n'existe encore.
const webVapidKey = 'BPi2jSsDA-fSYJAwjuwA4yRLTuNd4Pjlw0TfxpG2EVPPAglBJYVbghjnVgOzz-Vk90hivKb9fdDE8EYx6rQB9nI';
