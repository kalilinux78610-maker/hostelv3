importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-messaging.js");

firebase.initializeApp({
    apiKey: "AIzaSyBOpt3PhX--lKxlcQhI2npNgH20WRmUDUM",
    authDomain: "hostel-v3.firebaseapp.com",
    projectId: "hostel-v3",
    storageBucket: "hostel-v3.firebasestorage.app",
    messagingSenderId: "412251493918",
    appId: "1:412251493918:web:b59aadf29fa836d626c00f",
    measurementId: "G-LMDJ41NMJ9"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
    console.log('[firebase-messaging-sw.js] Received background message ', payload);
    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
        icon: '/icons/Icon-192.png'
    };

    self.registration.showNotification(notificationTitle, notificationOptions);
});
