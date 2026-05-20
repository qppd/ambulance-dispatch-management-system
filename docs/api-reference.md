# API Reference

ADMS uses Firebase SDKs directly — there is no custom REST API layer. All "API" calls are Dart method invocations through the Firebase Realtime Database and Authentication SDKs.

Below is the complete reference organised by service module.

---

## Authentication (Firebase Auth + `auth_service.dart`)

The `AuthNotifier` (Riverpod `Notifier`) wraps Firebase Auth and manages the application's `AuthState`.

### Auth States

| State | Description |
|-------|-------------|
| `AuthInitial` | App starting, checking stored session |
| `AuthLoading` | Authentication operation in progress |
| `AuthAuthenticated{user, accessToken}` | User is logged in, session active |
| `AuthUnauthenticated{message?}` | No active session |
| `AuthError{message, code?}` | Auth operation failed |
| `AuthPendingApproval{user}` | Account created but pending admin approval |
| `AuthNotVerified{email}` | Email verification required |

### Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `loginWithEmail(email, password)` | `String email, String password` | `Future<void>` | Authenticate with email/password |
| `registerWithEmail(…)` | `email, password, firstName, lastName, role, municipalityId?, phone?` | `Future<void>` | Create account + RTDB profile |
| `logout()` | — | `Future<void>` | Sign out, clear token, unsubscribe FCM |
| `sendPasswordReset(email)` | `String email` | `Future<void>` | Firebase password reset email |
| `approveUser(uid)` | `String uid` | `Future<void>` | Super Admin approves pending user |
| `clearError()` | — | `void` | Reset error state |

---

## Incident Service (`incident_service.dart`)

### Providers

| Provider | Type | Description |
|----------|------|-------------|
| `databaseRefProvider` | `Provider<DatabaseReference>` | Root RTDB reference |
| `incidentServiceProvider` | `Provider<IncidentService>` | Singleton service |
| `municipalityIncidentsProvider(municipalityId)` | `StreamProvider<List<Incident>>` | Active incidents for a municipality |
| `allMunicipalityIncidentsProvider(municipalityId)` | `StreamProvider<List<Incident>>` | All incidents (including resolved) |
| `incidentProvider({municipalityId, incidentId})` | `StreamProvider<Incident?>` | Single incident |
| `myIncidentsProvider` | `StreamProvider<List<Incident>>` | Incidents reported by current user |
| `driverIncidentsProvider` | `StreamProvider<List<Incident>>` | Incidents assigned to current driver |
| `allIncidentsSystemWideProvider` | `StreamProvider<List<Incident>>` | All incidents across all municipalities |

### Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `reportIncident(…)` | `reporterUid, reporterName, reporterPhone, municipalityId, latitude, longitude, address, severity, description?, patientName?, patientAge?, patientCondition?` | `Future<Incident>` | Citizen reports new emergency |
| `createAdminIncident(…)` | `dispatcherUid, dispatcherName, municipalityId, latitude, longitude, severity, incidentType, description, reporterName?, reporterPhone?, address?, landmark?, patientName?, patientAge?, patientCondition?` | `Future<Incident>` | Admin creates incident (911 call) — starts as `acknowledged` |
| `acknowledgeIncident(municipalityId, incidentId, dispatcherUid, dispatcherName)` | — | `Future<void>` | Dispatcher claims an incident |
| `dispatchUnit(municipalityId, incidentId, unitId, unitCallSign, driverId, driverName)` | — | `Future<void>` | Assign unit to incident |
| `updateStatus(municipalityId, incidentId, newStatus, destinationHospitalId?, destinationHospitalName?, notes?)` | — | `Future<void>` | Transition incident status (writes timestamp automatically) |
| `updatePatientInfo(municipalityId, incidentId, patientName?, patientAge?, patientCondition?)` | — | `Future<void>` | Update patient details |
| `cancelIncident(municipalityId, incidentId, reason?)` | — | `Future<void>` | Cancel an incident |

### Streams

| Stream | Description |
|--------|-------------|
| `watchActiveIncidents(municipalityId)` | Real‑time list of active (non‑resolved/cancelled) incidents, sorted by severity then newest |
| `watchAllIncidents(municipalityId)` | All incidents, newest first |
| `watchIncident(municipalityId, incidentId)` | Single incident |
| `watchIncidentsByReporter(reporterUid)` | Citizen's own incidents |
| `watchIncidentsByDriver(municipalityId, driverUid)` | Driver's active assignments |
| `watchAllIncidentsSystemWide()` | All incidents across every municipality |

---

## Dispatch Service (`dispatch_service.dart`)

### Providers

| Provider | Type | Description |
|----------|------|-------------|
| `dispatchServiceProvider` | `Provider<DispatchService>` | Singleton service |

### Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `acknowledgeIncident(municipalityId, incidentId, dispatcherUid, dispatcherName)` | — | `Future<void>` | Acknowledge and claim an incident |
| `dispatchUnit(municipalityId, incidentId, unitId, unitCallSign, driverId, driverName, dispatcherUid, dispatcherName)` | — | `Future<void>` | Atomic multi‑path dispatch (incident + unit) |
| `markEnRoute(municipalityId, incidentId, unitId)` | — | `Future<void>` | Driver reports en route |
| `markArrivedAtScene(municipalityId, incidentId, unitId)` | — | `Future<void>` | Driver arrived on scene |
| `startTransport(municipalityId, incidentId, unitId, receivingFacility?)` | — | `Future<void>` | Transporting patient |
| `markTransportComplete(municipalityId, incidentId, unitId)` | — | `Future<void>` | Resolve incident, free unit |
| `resolveIncident(municipalityId, incidentId, unitId, notes?)` | — | `Future<void>` | Resolve with optional notes |
| `cancelDispatch(municipalityId, incidentId, unitId?, reason?)` | — | `Future<void>` | Cancel incident, free unit if assigned |
| `updateUnitLocation(municipalityId, unitId, latitude, longitude)` | — | `Future<void>` | Update unit GPS in RTDB |
| `rankUnitsByProximity(availableUnits, incidentLat, incidentLng)` | → `List<DispatchSuggestion>` | Synchronous | Sort available units by haversine distance |
| `findNearestUnit(availableUnits, incidentLat, incidentLng)` | → `DispatchSuggestion?` | Synchronous | Get single nearest unit |
| `findNearestUnitOfType(availableUnits, incidentLat, incidentLng, requiredType)` | → `DispatchSuggestion?` | Synchronous | Get nearest unit of specific type |

### `DispatchSuggestion`

| Field | Type | Description |
|-------|------|-------------|
| `unit` | `AmbulanceUnit` | The recommended unit |
| `distanceKm` | `double` | Straight‑line distance |
| `estimatedArrivalMinutes` | `double` | ETA based on 50 km/h avg |
| `etaDisplay` | `String` | Human‑readable ETA |
| `distanceDisplay` | `String` | Human‑readable distance |

---

## Unit Service (`unit_service.dart`)

### Providers

| Provider | Type | Description |
|----------|------|-------------|
| `unitServiceProvider` | `Provider<UnitService>` | Singleton |
| `municipalityUnitsProvider(municipalityId)` | `StreamProvider<List<AmbulanceUnit>>` | All units in municipality |
| `availableUnitsProvider(municipalityId)` | `StreamProvider<List<AmbulanceUnit>>` | Only available units |
| `unitProvider({municipalityId, unitId})` | `StreamProvider<AmbulanceUnit?>` | Single unit |
| `myUnitProvider` | `StreamProvider<AmbulanceUnit?>` | Unit assigned to current driver |

### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `createUnit(id, municipalityId, callSign, plateNumber, type)` | `Future<AmbulanceUnit>` | Register new ambulance |
| `updateStatus(municipalityId, unitId, status)` | `Future<void>` | Change unit status |
| `updateLocation(municipalityId, unitId, latitude, longitude)` | `Future<void>` | Update GPS position |
| `assignDriver(municipalityId, unitId, driverUid, driverName)` | `Future<void>` | Assign driver to unit |
| `unassignDriver(municipalityId, unitId, driverUid)` | `Future<void>` | Remove driver from unit |
| `assignToIncident(municipalityId, unitId, incidentId)` | `Future<void>` | Set unit as en route to incident |
| `clearIncidentAssignment(municipalityId, unitId)` | `Future<void>` | Free unit from assignment |
| `setActive(municipalityId, unitId, isActive)` | `Future<void>` | Activate/deactivate unit |
| `deleteUnit(municipalityId, unitId)` | `Future<void>` | Remove unit (also cleans driver index) |

---

## User Service (`user_service.dart`)

### Providers

| Provider | Type | Description |
|----------|------|-------------|
| `userServiceProvider` | `Provider<UserService>` | Singleton |
| `allUsersProvider` | `StreamProvider<List<User>>` | All users (Super Admin only) |
| `usersByRoleProvider(role)` | `StreamProvider<List<User>>` | Filter by role |
| `municipalityUsersProvider(municipalityId)` | `StreamProvider<List<User>>` | Filter by municipality |
| `userByIdProvider(uid)` | `StreamProvider<User?>` | Single user |

### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `approveUser(uid)` | `Future<void>` | Approve pending account |
| `deactivateUser(uid)` | `Future<void>` | Soft‑delete user |
| `reactivateUser(uid)` | `Future<void>` | Restore deactivated user |
| `updateUserRole(uid, role)` | `Future<void>` | Change user role |
| `updateUserMunicipality(uid, municipalityId, municipalityName)` | `Future<void>` | Change municipality assignment |
| `updateProfile(uid, firstName?, lastName?, phoneNumber?)` | `Future<void>` | Update profile fields |
| `saveFcmToken(uid, token)` | `Future<void>` | Store FCM device token |

---

## Location Service (`location_service.dart`)

### Providers

| Provider | Type | Description |
|----------|------|-------------|
| `locationServiceProvider` | `Provider<LocationService>` | Singleton |
| `positionStreamProvider` | `StreamProvider<Position>` | Real‑time GPS stream |
| `currentPositionProvider` | `FutureProvider<Position?>` | One‑shot position |
| `locationAvailableProvider` | `FutureProvider<bool>` | Permission check |
| `driverLocationTrackerProvider` | `Provider<DriverLocationTracker>` | Automatic location broadcaster |

### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `isLocationAvailable()` | `Future<bool>` | Check GPS + permissions |
| `requestPermission()` | `Future<bool>` | Request location permission |
| `getCurrentPosition()` | `Future<Position?>` | Get device location (high accuracy) |
| `watchPosition()` | `Stream<Position>` | Continuous GPS updates (10m filter) |
| `distanceBetween(startLat, startLng, endLat, endLng)` | `double` | Meters between two coordinates |
| `distanceInKm(startLat, startLng, endLat, endLng)` | `double` | Kilometres between two coordinates |
| `estimateTravelTimeMinutes(distanceKm, avgSpeedKmh = 50)` | `double` | ETA estimate (lights & sirens speed) |

### `DriverLocationTracker`

| Method | Description |
|--------|-------------|
| `startTracking(municipalityId, unitId)` | Begin broadcasting GPS to RTDB every ~10s |
| `stopTracking()` | Stop broadcasting |

---

## Notification Service (`notification_service.dart`)

### FCM Topic Structure

| Topic | Subscribers |
|-------|-------------|
| `municipality_{municipalityId}` | All users in municipality |
| `municipality_{municipalityId}_admin` | Municipal Admins |
| `municipality_{municipalityId}_drivers` | Drivers |
| `incident_{municipalityId}_{incidentId}` | Citizens tracking specific incident |
| `global_announcements` | Super & Municipal Admins |

### Methods

| Method | Description |
|--------|-------------|
| `initialize()` | Request permissions, get FCM token |
| `subscribeForUser(user)` | Subscribe to role‑based topics |
| `unsubscribeAll(user)` | Unsubscribe on logout |
| `subscribeToIncident(municipalityId, incidentId)` | Citizen incident tracking |
| `unsubscribeFromIncident(municipalityId, incidentId)` | Stop tracking |

---

## Export Service (`export_service.dart`)

| Method | Description |
|--------|-------------|
| `printIncidentsPdf(context, incidents, title)` | Generate & print incident PDF |
| `incidentsToCsv(incidents)` → `String` | Generate incident CSV |
| `printUnitsPdf(context, units, title)` | Generate & print unit PDF |
| `unitsToCsv(units)` → `String` | Generate unit CSV |
| `printMaintenancePdf(context, records, title)` | Generate & print maintenance PDF |

---

## Response Time Analytics (`response_time_analytics.dart`)

### Per‑Incident Metrics

| Method | Returns | Description |
|--------|---------|-------------|
| `callProcessingMinutes(incident)` | `double?` | Created → dispatched (min) |
| `travelTimeMinutes(incident)` | `double?` | Dispatched → on scene (min) |
| `onSceneTimeMinutes(incident)` | `double?` | On scene → transporting (min) |
| `transportTimeMinutes(incident)` | `double?` | Transporting → at hospital (min) |
| `hospitalTurnaroundMinutes(incident)` | `double?` | At hospital → resolved (min) |
| `totalResponseTimeMinutes(incident)` | `double?` | Created → at hospital (min) |
| `totalDurationMinutes(incident)` | `double?` | Created → resolved/cancelled (min) |

### Aggregate Metrics

`computeMetrics(incidents)` → `ResponseTimeMetrics`

| Field | Type | Description |
|-------|------|-------------|
| `totalResolvedIncidents` | `int` | Count |
| `avgCallProcessingMinutes` | `double?` | Average call processing |
| `avgTravelTimeMinutes` | `double?` | Average travel time |
| `avgOnSceneMinutes` | `double?` | Average on‑scene time |
| `avgTransportMinutes` | `double?` | Average transport time |
| `avgHospitalTurnaroundMinutes` | `double?` | Average hospital turnaround |
| `avgTotalResponseMinutes` | `double?` | Average total response |
| `p90TotalResponseMinutes` | `double?` | 90th percentile response time |
| `complianceRate8Min` | `double?` | % travel times ≤ 8 min |
| `complianceRate15Min` | `double?` | % travel times ≤ 15 min |

---

## Audit Service (`audit_service.dart`)

| Provider | Description |
|----------|-------------|
| `auditLogProvider` | `StreamProvider<List<AuditEntry>>` — Last 200 log entries |

### `AuditEntry`

| Field | Type |
|-------|------|
| `id` | `String` |
| `action` | `String` |
| `performedByUid` | `String` |
| `performedByName` | `String` |
| `targetId` | `String?` |
| `targetType` | `String?` |
| `details` | `Map<String, dynamic>?` |
| `timestamp` | `DateTime` |