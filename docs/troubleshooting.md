# Troubleshooting

## Compilation & Build Issues

### `flutter pub get` fails

```bash
Error: Because every version of flutter_riverpod ...
```

**Cause:** Outdated or conflicting dependency versions.

**Fix:**

```bash
# Upgrade to latest compatible versions
flutter pub upgrade --major-versions
```

### `flutter analyze` shows Riverpod errors

```bash
The class 'StateNotifierProvider' isn't available...
The getter 'valueOrNull' isn't defined...
```

**Cause:** The codebase uses Riverpod 3.x, which removed `StateNotifierProvider` and renamed `valueOrNull` → `value`.

**Fix:**

| Old (Riverpod 2.x) | New (Riverpod 3.x) |
|-------------------|--------------------|
| `StateNotifierProvider` | `NotifierProvider` |
| `StateNotifier<T>` | `Notifier<T>` with `build()` |
| `super(initialState)` | `build()` returns initial state |
| `dispose()` | `ref.onDispose()` |
| `.valueOrNull` | `.value` |

### `flutter run` fails on Windows

**Cause:** The Flutter Dart SDK uses a `.bat` file that fails in WSL due to MSYS detection.

**Fix:** Use the native Windows Dart SDK directly:

```bash
# Instead of `dart pub get`, use:
/mnt/c/Users/<user>/flutter/bin/cache/dart-sdk/bin/dart.exe pub get
```

---

## Authentication Issues

### "Email not verified" screen on every login

**Cause:** The Firebase Auth user's `emailVerified` flag is `false`.

**Fix:**
- Check the user's email inbox for the verification link
- Resend verification from the pending screen
- For testing, mark the user as verified in Firebase Console → Authentication → Users

### "Pending approval" stuck

**Cause:** A Super Admin or Municipal Admin hasn't approved the account.

**Fix:**
- Log in as a Super Admin or Municipal Admin
- Navigate to **User Management**
- Find the pending user and tap **Approve**

### Login says "User is deactivated" or "not approved"

**Cause:** The user's `isActive` or `isApproved` flag is `false` in RTDB.

**Fix:**
- For deactivated: ask your admin to reactivate your account
- For unapproved: ask your admin to approve your registration

---

## Database & Sync Issues

### Data isn't appearing in real time

**Cause:** Firebase RTDB offline persistence may hold stale data, or the security rules are blocking the read.

**Fix:**

1. Check the browser/app console for permission denied errors
2. Verify the user's role in `users/{uid}/role` matches what the security rules expect
3. Deploy the correct `database.rules.json`:
   ```bash
   flutter deploy --only database
   ```

### Changes made in one client don't appear in another

**Cause:** Firebase RTDB offline mode — the writing client may be offline, queueing the write locally.

**Fix:**
- Wait for the client to reconnect (offline banner disappears)
- Check `FirebaseDatabase.instance.goOnline()` was called

### "Permission denied" errors in console

**Cause:** The Firebase RTDB security rules are rejecting the operation.

**Common fixes:**

| Issue | Rule Cause | Fix |
|-------|------------|-----|
| Citizen can't update incident | `dispatcher` role not in write rule | Update rules to include `municipalAdmin` (dispatcher was consolidated) |
| Driver can't read own incident | Missing citizen read rule | Driver should read via `watchIncidentsByDriver` which uses indexed query |
| Super Admin can't read all users | `users/.read` rule too restrictive | Check the rule uses `superAdmin` (not `super_admin`) |

---

## Cloud Functions Issues

### Functions deploy fails

```bash
Error: Failed to load function...
```

**Cause:** Missing dependencies or syntax error.

**Fix:**

```bash
cd functions
rm -rf node_modules
npm install
npm run lint
```

### Auto‑dispatch doesn't fire

**Cause:** `autoDispatchEnabled` is `false` in `/systemConfig`, or no available units have valid GPS coordinates.

**Check in order:**
1. Is `/systemConfig/autoDispatchEnabled` set to `true`?
2. Are there units with `status: "available"`?
3. Do those units have valid `latitude` and `longitude` values?
4. Check the Cloud Functions logs in Firebase Console

### Push notifications aren't arriving

1. Is `driver.fcmToken` stored in `/users/{driverUid}/fcmToken`?
2. Check Firebase Console → Cloud Messaging → Reports
3. Test with:
   ```bash
   curl -X POST -H "Authorization: key=YOUR_SERVER_KEY" \
     -H "Content-Type: application/json" \
     -d '{"to":"DEVICE_FCM_TOKEN","notification":{"title":"Test","body":"Hello"}}' \
     "https://fcm.googleapis.com/fcm/send"
   ```

---

## Map Issues

### Map tiles aren't loading

**Cause:** No network or incorrect tile configuration.

**Fix:**
- flutter_map with OpenStreetMap tiles works without an API key
- Check network connectivity (offline banner shows if detected)
- The map still functions — markers and vector data will render when tiles load

### GPS location isn't showing

**Cause:** Location permission denied or GPS disabled.

**Fix:**
- On Android/iOS: ensure `ACCESS_FINE_LOCATION` or `NSLocationWhenInUseUsageDescription` is in the manifest
- The app requests permission on first use
- Verify the device has GPS enabled

---

## Performance & Debugging

### App is slow on low‑end devices

**Cause:** Firebase RTDB streams re‑parse all data on every change.

**Suggested optimisations:**
- Reduce `setPersistenceCacheSizeBytes` from 10 MB if storage is limited
- Use `limitToLast()` on streams where history isn't needed
- The `watchActiveIncidents` stream already filters at parse time — consider adding a database query for the status filter

### Debug logs are noisy

**Cause:** `debugLogDiagnostics: true` in the GoRouter configuration.

**Fix:** Set `debugLogDiagnostics: false` in `app_router.dart` for production builds.

---

## Common Error Messages

| Error | Likely Cause | Fix |
|-------|-------------|-----|
| `[firebase_auth/...]` | Firebase Auth configuration | Check `firebase_options.dart` |
| `[firebase_database/permission_denied]` | Security rules | Deploy latest `database.rules.json` |
| `NoSuchMethodError: 'valueOrNull'` | Outdated Riverpod | Run `flutter pub upgrade --major-versions` |
| `type 'Null' is not a subtype of type ...` | Null field in RTDB | Check `fromJson()` handles nulls |
| `dispatcher` role errors | Old role reference | Change to `municipalAdmin` |