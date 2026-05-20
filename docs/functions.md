# Functions Reference

## Cloud Functions (`functions/`)

Five Firebase Cloud Functions (v2) provide server‑side logic. All are written in Node.js 20 and deployed via `firebase deploy --only functions`.

### 1. `onIncidentCreated`

| Property | Value |
|----------|-------|
| **Trigger** | `onValueCreated("/incidents/{municipalityId}/{incidentId}")` |
| **File** | `dispatch.js` |
| **Purpose** | Auto‑dispatch the nearest available ambulance unit to a new incident |

**Workflow:**

1. Validate incident data (coordinates must be valid lat/lng)
2. Read `/systemConfig` — skip if `autoDispatchEnabled` is `false`
3. Query `/units/{municipalityId}` for `status === "available"`
4. Compute Haversine distance from each unit to the incident location
5. Sort candidates by distance (nearest first)
6. Attempt atomic `claimUnitInTransaction()` for each candidate:
   - Reads the unit node inside a Firebase transaction
   - If unit is still `available`, sets `status → enRoute` and `currentIncidentId`
   - If unit was already taken by another concurrent incident, the transaction aborts
7. On success: update incident with `assignedUnitId`, `status → dispatched`, `dispatchedAt`
8. On failure (all units taken): write `autoDispatchError` field to the incident

**Key Design:**

```javascript
async function claimUnitInTransaction(municipalityId, unitId, incidentId) {
  const result = await unitRef.transaction((current) => {
    if (current === null) return;          // deleted
    if (current.status !== "available") return; // already taken
    current.status = "enRoute";
    current.currentIncidentId = incidentId;
    return current;
  });
}
```

Uses `haversineKm()` for distance, `isValidLatitude()` / `isValidLongitude()` for input validation.

### 2. `onIncidentStatusChanged`

| Property | Value |
|----------|-------|
| **Trigger** | `onValueWritten("/incidents/{municipalityId}/{incidentId}/status")` |
| **File** | `dispatch.js` |
| **Purpose** | Free the assigned unit when an incident is resolved |

**Workflow:**

1. Only acts on `newStatus === "resolved"`
2. Reads the full incident to get `assignedUnitId`
3. **Guard:** Checks that the unit's `currentIncidentId` still matches — prevents freeing a unit that was reassigned during a race condition
4. Frees the unit: `status → available`, `currentIncidentId → null`
5. Records `resolvedAt` timestamp on the incident

### 3. `onUnitDispatched`

| Property | Value |
|----------|-------|
| **Trigger** | `onValueWritten("/units/{municipalityId}/{unitId}/status")` |
| **File** | `notifications.js` |
| **Purpose** | Send FCM push notification to the assigned driver |

**Workflow:**

1. Only acts on `newStatus === "enRoute"`
2. Reads the unit to find `assignedDriverId`
3. Reads the driver's user record for `fcmToken`
4. If token exists, reads incident details for the notification body
5. Sends FCM message with:
   - Title: `"New Dispatch — Respond Now"`
   - Body: `"{callSign}: {description}"`
   - Data: `{type: "dispatch", unitId, municipalityId, incidentId}`
   - Android priority: `high`, channel: `dispatch_alerts`

### 4. `onUserRoleChanged`

| Property | Value |
|----------|-------|
| **Trigger** | `onValueWritten("/users/{uid}/role")` |
| **File** | `audit.js` |
| **Purpose** | Log role changes to the audit trail |

**Workflow:**

1. Compares `event.data.before.val()` with `event.data.after.val()`
2. No‑ops if the role hasn't changed
3. Writes an `AuditEntry` to `/auditLog/{pushId}`:
   - `type: "role_change"`, `uid`, `oldRole`, `newRole`, `timestamp`, `changedBy`

### 5. `cleanupExpiredInvites`

| Property | Value |
|----------|-------|
| **Trigger** | `onSchedule("every 24 hours")` |
| **File** | `invites.js` |
| **Purpose** | Delete unused invites older than 7 days |

**Workflow:**

1. Calculates cutoff time (7 days ago)
2. Reads all `/invites` nodes
3. Deletes any invite that is `used === false` and has `createdAt < cutoff`
4. Logs count of deleted invites

## Function Dependencies

```json
{
  "dependencies": {
    "firebase-admin": "^13.10.0",
    "firebase-functions": "^7.2.5"
  },
  "devDependencies": {
    "eslint": "^10.4.0"
  }
}
```

## Deployment

```bash
cd functions
npm install
npm run lint
firebase deploy --only functions
```

## Local Testing

```bash
firebase emulators:start --only functions
# Test with:
curl http://localhost:5001/<project>/us-central1/<functionName>
```