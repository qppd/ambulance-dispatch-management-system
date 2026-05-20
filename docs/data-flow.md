# Data Flow

## Incident Lifecycle

The core of ADMS is the **incident lifecycle** — a sequence of concrete status transitions from report to resolution.

```mermaid
stateDiagram-v2
    [*] --> pending: Citizen reports
    pending --> acknowledged: Dispatcher acknowledges
    acknowledged --> dispatched: Unit assigned
    dispatched --> enRoute: Driver en route
    enRoute --> onScene: Driver arrived
    onScene --> transporting: Transporting patient
    transporting --> atHospital: At hospital
    atHospital --> resolved: Completed
    resolved --> [*]
    dispatched --> cancelled: Cancel
    pending --> cancelled: Cancel
```

### Step‑by‑Step

#### 1. Citizen Reports Incident

```dart
// citizen_dashboard.dart
final incident = await ref.read(incidentServiceProvider).reportIncident(
  reporterUid: user.id,
  reporterName: user.fullName,
  reporterPhone: user.phoneNumber ?? '',
  municipalityId: selectedMunicipalityId,
  latitude: position.latitude,
  longitude: position.longitude,
  address: reverseGeocodedAddress,
  severity: IncidentSeverity.critical,
  description: 'Car accident on National Highway',
);
```

**RTDB writes:**
- `/incidents/{municipalityId}/{incidentId}` — full Incident object
- `/user_incidents/{reporterUid}/{incidentId}` — `true` (citizen index)
- `/incident_index/{incidentId}` — `municipalityId` (global lookup)

#### 2. Cloud Function Auto‑Dispatch (if enabled)

```mermaid
sequenceDiagram
    participant RTDB
    participant Fn as onIncidentCreated()
    participant Units as /units/{municipalityId}
    participant Incident as /incidents/{municipalityId}/{incidentId}

    RTDB-->>Fn: Triggered
    Fn->>RTDB: Read /systemConfig.autoDispatchEnabled
    Fn->>Units: Query status==available
    Units-->>Fn: Available units list
    Fn->>Fn: Haversine sort by distance
    loop Try each candidate
        Fn->>Units: claimUnitInTransaction()
        alt Unit still available
            Units-->>Fn: Claimed ✓
            Fn->>Incident: Write assignedUnitId, dispatched status
        else Unit already taken
            Units-->>Fn: Aborted ✗
            Fn->>Fn: Try next candidate
        end
    end
    alt No unit claimed
        Fn->>Incident: Write autoDispatchError
    end
```

#### 3. Dispatcher Views & Manages

Every active incident appears in real‑time on the Municipal Admin dashboard:

```dart
// dashboard_tab.dart
final incidentsAsync = ref.watch(municipalityIncidentsProvider(municipalityId));
```

Incidents are sorted by **severity priority** (critical first) then **newest first** (see `watchActiveIncidents`).

#### 4. Dispatcher Dispatches Unit (manual)

```dart
// dispatch map or incident detail
await ref.read(dispatchServiceProvider).dispatchUnit(
  municipalityId: muniId,
  incidentId: incId,
  unitId: bestUnit.id,
  unitCallSign: bestUnit.callSign,
  driverId: bestUnit.assignedDriverId!,
  driverName: bestUnit.assignedDriverName!,
  dispatcherUid: admin.id,
  dispatcherName: admin.fullName,
);
```

**Atomic multi‑path update:**
- `incidents/.../status → dispatched, assignedUnitId, dispatchedAt`
- `units/.../status → enRoute, currentIncidentId`

#### 5. Driver Receives Notification & Updates Status

Drivers progress through the lifecycle using the driver dashboard:

```dart
// mark en route
await dispatchService.markEnRoute(municipalityId: id, incidentId: incId, unitId: unitId);

// mark arrived on scene
await dispatchService.markArrivedAtScene(municipalityId: id, incidentId: incId, unitId: unitId);

// start transport
await dispatchService.startTransport(municipalityId: id, incidentId: incId, unitId: unitId);

// complete
await dispatchService.markTransportComplete(municipalityId: id, incidentId: incId, unitId: unitId);
```

Each method writes a **multi‑path update** that transitions both the incident and the unit, recording the precise timestamp.

#### 6. Cloud Function Frees Unit

When `status → resolved`, `onIncidentStatusChanged` fires:
- Checks the unit is still assigned to this incident (race condition guard)
- Sets `unit.status → available`, `unit.currentIncidentId → null`
- Records `resolvedAt` on the incident

## Connectivity & Offline Flow

```mermaid
flowchart LR
    subgraph Online
        A[App Start] --> B[Firebase RTDB]
        B --> C[Real-time sync]
    end
    subgraph Offline
        D[Connection Lost] --> E[Local cache<br/>10 MB disk persistence]
        E --> F[Queued writes]
        F --> G[Auto-sync on reconnect]
    end
    C --> D
    G --> B
```

The offline banner appears in `main.dart` via the `isOnlineProvider`, which wraps `connectivity_plus`. Firebase RTDB handles the data sync layer automatically — queued writes survive app restarts.

## Authentication Flow

```mermaid
sequenceDiagram
    participant User
    participant App
    participant FA as Firebase Auth
    participant RTDB

    User->>App: Enter email & password
    App->>FA: signInWithEmailAndPassword()
    FA-->>App: UserCredential
    App->>RTDB: Read /users/{uid}
    RTDB-->>App: User profile
    App->>App: AuthNotifier.build()
    Note over App: AuthState → AuthAuthenticated

    App->>App: Check isApproved
    alt Not approved
        App->>App: AuthState → AuthPendingApproval
        App->>User: Redirect to pending screen
    else Not verified
        App->>App: AuthState → AuthNotVerified
        App->>User: Redirect to verify email
    else Approved & verified
        App->>App: Router redirects to role home
        App->>App: Save FCM token
        App->>App: Subscribe to topics
        App->>App: Start idle timer
    end
```

## Data Model Relationships

```mermaid
erDiagram
    Municipality ||--o{ User : "contains"
    Municipality ||--o{ Incident : "contains"
    Municipality ||--o{ AmbulanceUnit : "contains"
    Municipality ||--o{ MaintenanceRecord : "contains"
    Municipality ||--o{ PatientCareReport : "contains"
    Incident ||--o| AmbulanceUnit : "assigned to"
    Incident ||--o| PatientCareReport : "has"
    AmbulanceUnit ||--o{ MaintenanceRecord : "has"
    User ||--o{ Incident : "reports"
    User ||--o| AmbulanceUnit : "drives"
```