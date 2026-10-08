# Local Firebase Dream Story worker

This is a **development-only** worker running on your PC. It polls Firestore, claims queued **story** jobs, generates one 512×512 scene, and uploads it to Firebase Storage. It does not yet implement multi-scene storyboarding, Dream Cast reference conditioning, credit charging, or movies.

## One-time Firebase setup

1. Open Firebase Console → Project settings → Service accounts → **Generate new private key**.
2. Store the downloaded JSON file outside the Git repository, e.g. `C:\\Users\\<you>\\firebase-secrets\\dream-logs-worker.json`.
3. **Never commit or share this file.** This credential has administrative access to Firebase.
4. Check Firebase Storage is enabled and its bucket is `dream-logs.firebasestorage.app`.

## PowerShell

From the Dream Logs project root, with your existing Python 3.11 `.venv` active:

```powershell
git pull
python -m pip install -r ai_backend/worker-requirements.txt
firebase deploy --only "firestore:rules,storage"
python ai_backend/firebase_worker.py --credentials "C:\\Users\\YOUR_WINDOWS_USERNAME\\firebase-secrets\\dream-logs-worker.json"
```

Keep the worker terminal open. In a **separate** VS Code terminal, run `flutter run` on your phone. Submit a **Dream Story** and watch the worker output. The app listens to the job document and displays the uploaded scene when completed.

This prototype generates from dream text only. Selecting Cast saves IDs for future consent-aware reference conditioning; **no Cast photos are read or used by the worker**. A local PC worker is not production infrastructure. Never run it with service-account credentials on a phone or in client-side Flutter.
