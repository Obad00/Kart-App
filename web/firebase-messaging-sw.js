// Service worker requis par firebase_messaging (web) pour afficher les
// notifications reçues quand l'onglet est en arrière-plan ou fermé — au
// premier plan, c'est PushNotificationService._onForegroundMessage (Dart)
// qui gère l'affichage. Le plugin l'enregistre automatiquement (racine du
// site), pas besoin de l'appeler nous-mêmes depuis index.html.
//
// ⚠️ La config ci-dessous doit rester identique à celle de
// lib/firebase_options_web.dart (webFirebaseOptions) — si tu régénères la
// config Firebase Web, mets à jour les DEUX fichiers.
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCtAp17SoDDEyYPQu_FTmyiNiahA8MjeoY',
  appId: '1:572176532309:web:ec640f9f654acd649725dc',
  messagingSenderId: '572176532309',
  projectId: 'kart-e3274',
  authDomain: 'kart-e3274.firebaseapp.com',
  storageBucket: 'kart-e3274.firebasestorage.app',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const { title, body } = payload.notification || {};
  self.registration.showNotification(title || 'KART', {
    body: body || '',
    icon: '/icons/Icon-192.png',
  });
});
