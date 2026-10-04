# Firebase setup

Dream Logs is Firebase-ready, but project-specific Firebase files must be generated for the Firebase project you own.

## Services to enable

1. Authentication
   - Email/password
   - Apple
   - Google
2. Cloud Firestore
3. Firebase Storage
4. Firebase Cloud Messaging

## Flutter configuration

Install FlutterFire CLI and run:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This generates the platform-specific Firebase configuration for your own Firebase project.

## Planned Firestore structure

```text
users/{uid}
users/{uid}/personas/{personaId}
dreams/{dreamId}
friendships/{friendshipId}
follows/{followId}
dreamTags/{tagId}
notifications/{notificationId}
```

Do not commit service-account private keys or backend secrets.
