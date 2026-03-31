# ADMS — Project Status Report (Revision 2)

> **Ambulance Dispatch & Management System**  
> Full-stack Flutter / Firebase application  
> Report generated after second full codebase scan

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Technology Stack](#2-technology-stack)
3. [Architecture Overview](#3-architecture-overview)
4. [Feature Status by Role](#4-feature-status-by-role)
   - [Super Admin](#41-super-admin)
   - [Municipal Admin](#42-municipal-admin)
   - [Dispatcher](#43-dispatcher)
   - [Driver / Paramedic](#44-driver--paramedic)
   - [Citizen](#45-citizen)
   - [Hospital Staff](#46-hospital-staff)
5. [Core Services & Infrastructure](#5-core-services--infrastructure)
6. [Global App Layer (main.dart)](#6-global-app-layer-maindart)
7. [Routing](#7-routing)
8. [Test Coverage](#8-test-coverage)
9. [What Changed Since Revision 1](#9-what-changed-since-revision-1)
10. [Remaining Gaps & Incomplete Work](#10-remaining-gaps--incomplete-work)
11. [Recommendations (Priority Order)](#11-recommendations-priority-order)
12. [Overall Completion Estimate](#12-overall-completion-estimate)

---

## 1. Executive Summary

The ADMS codebase has advanced significantly since the first scan. **13 previously missing or incomplete features have been implemented** — including the ePCR form, fleet maintenance UI, live citizen incident tracking, idle session timeout, dark mode persistence, offline banner, FCM token wiring, and real GPS in the citizen emergency request. Overall project completion is estimated at **~78–80%**, up from ~65% in Revision 1.

The application is structurally solid with clean role isolation, real Firebase RTDB streaming throughout, and a well-organized feature-folder architecture. The primary remaining work is a mix of UI wiring (connecting implemented services to buttons), a few stubbed interaction handlers, and the entirely absent Cloud Functions layer.

---

## 2. Technology Stack

| Layer | Technology | Version |
|---|---|---|
| UI Framework | Flutter | SDK `^3.9.0` |
| Language | Dart | null-safe |
| State Management | Riverpod 2.x | `^2.6.1` |
| Routing | GoRouter | `^17.x` |
| Auth | Firebase Auth | latest |
| Database | Firebase RTDB | latest |
| Push Notifications | Firebase Messaging (FCM) | latest |
| Analytics | Firebase Analytics | latest |
| Maps | flutter_map + latlong2 | `^7.0.2` |
| Charts | fl_chart | `^0.69.0` |
| PDF Export | pdf + printing | `^3.11.1` / `^5.13.4` |
| CSV Export | csv | `^6.0.0` |
| Theme Persistence | shared_preferences | `^2.3.4` |
| Deep Linking / Phone | url_launcher | `^6.3.1` |
| File System | path_provider | `^2.1.5` |
| App Info | package_info_plus | `^8.1.3` |
| Animations | flutter_animate | latest |
| Testing | flutter_test + integration_test | SDK bundled / dev dep |

---

## 3. Architecture Overview

```
lib/
├── main.dart                    # App bootstrap — ConsumerStatefulWidget
├── firebase_options.dart        # Firebase project config
├── core/
│   ├── models/                  # 10+ Dart model classes (all null-safe)
│   ├── services/                # 19 service files (all Riverpod providers)
│   ├── router/                  # GoRouter with role-based redirect guards
│   ├── theme/                   # AppColors, AppTheme, AppTextStyles
│   └── shared/                  # AppTextField, AppButton, reusable widgets
└── features/
    ├── auth/                    # Login, Register, ForgotPassword, VerifyEmail,
    │                            #   PendingApproval, StaffLogin, Welcome screens
    ├── super_admin/             # Dashboard, Users, Municipalities, Settings, Reports
    ├── municipal_admin/         # Dashboard, Maintenance
    ├── dispatcher/              # Dashboard (dispatch map, incident queue, units)
    ├── driver/                  # Dashboard, EpcrFormScreen
    ├── citizen/                 # Dashboard, CitizenLoginScreen, IncidentTrackingScreen
    └── hospital/                # Dashboard
```

**State management pattern:** All Firebase streams are wrapped in Riverpod `StreamProvider` or `FutureProvider`. Mutations go through `StateNotifier` subclasses. Services are injected via `Provider` with `.autoDispose` where appropriate.

---

## 4. Feature Status by Role

### 4.1 Super Admin

| Feature | Status | Notes |
|---|---|---|
| Dashboard — KPI cards (municipalities, users, incidents, units) | ✅ Complete | Live RTDB streams |
| Dashboard — Recent incidents list | ✅ Complete | Streams from all municipalities |
| Municipality management (CRUD) | ✅ Complete | Full create/edit/delete |
| User management (list, approve, suspend, role filter) | ✅ Complete | |
| System settings (session timeout, map provider, alert thresholds) | ✅ Complete | Writes to RTDB |
| Reports — KPI cards, bar chart, pie chart, response-time chart | ✅ Complete | 30/90-day filter |
| Reports — PDF export button | ❌ Missing | `ExportService` exists, not wired |
| Reports — CSV export button | ❌ Missing | `ExportService` exists, not wired |
| Audit log viewer | ❌ Missing | `AuditService` exists, no screen |

---

### 4.2 Municipal Admin

| Feature | Status | Notes |
|---|---|---|
| Dashboard — KPI cards (incidents, units, dispatchers, hospitals) | ✅ Complete | |
| Dashboard — Incidents tab (list + status change) | ✅ Complete | |
| Dashboard — Units tab (status, assignment) | ✅ Complete | |
| Dashboard — Dispatchers tab | ✅ Complete | |
| Dashboard — Hospitals tab | ✅ Complete | |
| Dashboard — Drivers tab | ✅ Complete | |
| Dashboard — Statistics tab (charts) | ✅ Complete | |
| Maintenance management (schedule, start, complete, cancel) | ✅ Complete | 3-tab UI: Upcoming / All / Completed |
| Maintenance — overdue detection (red border) | ✅ Complete | |
| Export from municipal admin | ❌ Missing | No export buttons in dashboard |

---

### 4.3 Dispatcher

| Feature | Status | Notes |
|---|---|---|
| Dispatch map (flutter_map, unit markers, incident pins) | ✅ Complete | Live GPS from RTDB |
| Incident queue with severity coloring | ✅ Complete | |
| Assign unit to incident | ✅ Complete | |
| Unit status panel | ✅ Complete | |
| Notification-triggered re-center | ✅ Complete | |
| FCM alert on new incident | ✅ Complete | |

---

### 4.4 Driver / Paramedic

| Feature | Status | Notes |
|---|---|---|
| Dashboard — Active assignment card with incident detail | ✅ Complete | |
| Status workflow (Available → EnRoute → OnScene → Transporting → Resolved) | ✅ Complete | |
| Location tracking — auto-start when assigned, auto-stop when unassigned | ✅ Complete | `_syncLocationTracking()` added |
| Quick Actions — Patient Report → EpcrFormScreen | ✅ Complete | Requires active incident |
| ePCR form — 5-step stepper (Patient, Clinical, Vitals, Interventions, Handover) | ✅ Complete | Calls PCR service sequentially |
| Quick Actions — Navigate button | ❌ Stub | `onTap: () {}` |
| Quick Actions — Details button | ❌ Stub | `onTap: () {}` |
| Hospital selection during "Transporting" status | ❌ Stub | `// TODO: Show hospital selection dialog` |
| History tab — completed incidents list | ❌ Stub | `// TODO: Implement from Firebase` |
| Profile settings — Edit Profile, Notifications, Help | ❌ Stubs | All `onTap: () {}` |
| ePCR hospital picker — bound to hospital entity | ❌ Missing | Currently free-text field |

---

### 4.5 Citizen

| Feature | Status | Notes |
|---|---|---|
| Dedicated citizen login screen (`CitizenLoginScreen`) | ✅ Complete | Emergency gradient branding |
| Emergency request with real GPS coordinates | ✅ Complete | `locationService.getCurrentPosition()` |
| Emergency request — address field | 🟡 Partial | Still literal `'Location pending...'` (no reverse geocoding) |
| Request history list | ✅ Complete | Streams from Firebase |
| Incident tracking screen — live map + 7-step progress + ETA | ✅ Complete | flutter_map, unit GPS marker |
| Incident tracking — navigation from history list | ❌ Missing | Card has chevron but no `onTap` |
| Quick Services — Call 911 | ❌ Stub | `onTap: () {}` |
| Quick Services — Nearby Hospitals | ❌ Stub | `onTap: () {}` |
| Quick Services — First Aid Guide | ❌ Stub | `onTap: () {}` |
| Quick Services — Emergency Contacts | ❌ Stub | `onTap: () {}` |
| Profile — Emergency Contacts | ❌ Stub | `onTap: () {}` |
| Profile — Medical Information | ❌ Stub | `onTap: () {}` |
| Profile — Notifications | ❌ Stub | `onTap: () {}` |

---

### 4.6 Hospital Staff

| Feature | Status | Notes |
|---|---|---|
| Dashboard — KPI cards (incoming, capacity, avg response) | ✅ Complete | |
| Dashboard — Incoming patients list (filtered to this hospital) | ✅ Complete | |
| Dashboard — Accept / Reject incoming patient | ✅ Complete | |
| Sidebar — Transfer History | ❌ Non-functional | `onTap: () {}` |
| Sidebar — Bed Availability | ❌ Non-functional | `onTap: () {}` |
| Sidebar — Settings | ❌ Non-functional | `onTap: () {}` |
| ePCR viewer (read incoming patient care reports) | ❌ Missing | No screen exists |
| Notification badge count | ❌ Hardcoded | Always shows '0' |
| Sidebar navigation switching | ❌ Missing | `_selectedNavIndex` set but no content switch in wide layout |

---

## 5. Core Services & Infrastructure

| Service | Provider | Status | Notes |
|---|---|---|---|
| `AuthService` | `authStateProvider` | ✅ Complete | Firebase Auth + RTDB user sync |
| `UserService` | `userServiceProvider` | ✅ Complete | CRUD, `saveFcmToken()` |
| `IncidentService` | `incidentServiceProvider` | ✅ Complete | Create, update status, assign |
| `AmbulanceUnitService` | `unitServiceProvider` | ✅ Complete | CRUD, status updates |
| `DispatcherService` | `dispatcherServiceProvider` | ✅ Complete | |
| `HospitalService` | `hospitalServiceProvider` | ✅ Complete | |
| `MunicipalityService` | `municipalityServiceProvider` | ✅ Complete | |
| `MaintenanceService` | `maintenanceServiceProvider` | ✅ Complete | Schedule, start, complete, cancel |
| `PatientCareReportService` | `pcrServiceProvider` | ✅ Complete | Create, vitals, treatments, handover |
| `LocationService` | `locationServiceProvider` | ✅ Complete | GPS, distance, ETA calculation |
| `DriverLocationTracker` | `driverLocationTrackerProvider` | ✅ Complete | Publishes to RTDB every N seconds |
| `NotificationService` | `notificationServiceProvider` | ✅ Complete | FCM init, token, foreground display |
| `ConnectivityService` | `connectivityServiceProvider` | ✅ Complete | `isOnlineProvider` stream |
| `SystemConfigService` | `systemConfigProvider` | ✅ Complete | Reads/writes global config from RTDB |
| `AuditService` | `auditServiceProvider` | 🟡 Partial | Service complete, **zero call sites** |
| `ExportService` | `exportServiceProvider` | 🟡 Partial | PDF/CSV complete, **no UI entry points** |
| `IdleTimerService` | `idleTimerServiceProvider` | ✅ Complete | Wired globally in `main.dart` |
| `ThemeModeNotifier` | `themeModeProvider` | ✅ Complete | Persists via SharedPreferences |
| `ResponseTimeAnalyticsService` | `responseTimeProvider` | ✅ Complete | |

---

## 6. Global App Layer (main.dart)

`main.dart` is now a `ConsumerStatefulWidget` with the following global wiring:

| Capability | Status | Implementation |
|---|---|---|
| FCM initialization | ✅ | `_initNotifications()` in `initState()` |
| FCM token persistence | ✅ | `_saveFcmToken()` → `userService.saveFcmToken()` + `onTokenRefresh` callback |
| Dark / light / system theme | ✅ | `themeMode: ref.watch(themeModeProvider)` |
| Idle session timeout | ✅ | `GestureDetector` wrapping whole app → `idleTimerServiceProvider.handleUserInteraction()` |
| Offline status banner | ✅ | `MaterialBanner` in `builder:` watching `isOnlineProvider` |
| Debug banner | ✅ | `debugShowCheckedModeBanner: kDebugMode` |
| Dark mode UI toggle | ❌ | Service wired, no toggle widget in any settings screen |

---

## 7. Routing

GoRouter with role-based redirect guards (`/super-admin/*` → only superAdmin, etc.).

| Route | Screen | Status |
|---|---|---|
| `/` | `WelcomeScreen` | ✅ |
| `/citizen/login` | `CitizenLoginScreen` | ✅ New |
| `/staff-login` | `StaffLoginScreen` | ✅ |
| `/login` | `LoginScreen` (role param) | ✅ |
| `/register` | `RegisterScreen` | ✅ |
| `/forgot-password` | `ForgotPasswordScreen` | ✅ |
| `/verify-email` | `VerifyEmailScreen` | ✅ |
| `/pending-approval` | `PendingApprovalScreen` | ✅ |
| `/super-admin` | `SuperAdminDashboard` | ✅ |
| `/super-admin/municipalities` | `MunicipalityManagementScreen` | ✅ |
| `/super-admin/users` | `UserManagementScreen` | ✅ |
| `/super-admin/settings` | `SystemSettingsScreen` | ✅ |
| `/super-admin/reports` | `ReportsScreen` | ✅ |
| `/municipal-admin` | `MunicipalAdminDashboard` | ✅ |
| `/dispatcher` | `DispatcherDashboard` | ✅ |
| `/driver` | `DriverDashboard` | ✅ |
| `/citizen` | `CitizenDashboard` | ✅ |
| `/citizen/track` | `IncidentTrackingScreen` | ✅ New |
| `/hospital` | `HospitalDashboard` | ✅ |

---

## 8. Test Coverage

### Model Tests (`test/models/`)

| Test File | Status |
|---|---|
| `ambulance_unit_test.dart` | ✅ |
| `hospital_test.dart` | ✅ |
| `incident_test.dart` | ✅ |
| `maintenance_record_test.dart` | ✅ New |
| `municipality_test.dart` | ✅ |
| `patient_care_report_test.dart` | ✅ New |
| `system_config_test.dart` | ✅ |
| `user_test.dart` | ✅ |

### Service Tests (`test/services/`)

| Test File | Status |
|---|---|
| `response_time_analytics_test.dart` | ✅ New |
| `system_config_notifier_test.dart` | ✅ New |

### Widget Tests (`test/widgets/`)

| Test File | Status |
|---|---|
| `dispatch_map_test.dart` | ✅ |
| `system_settings_screen_test.dart` | ✅ |
| `user_management_screen_test.dart` | ✅ |
| `widget_test.dart` | ✅ |

### Coverage Gaps

- No widget/screen tests for any of the 4 new screens (`MaintenanceScreen`, `EpcrFormScreen`, `IncidentTrackingScreen`, `CitizenLoginScreen`)
- No service tests for `AuditService`, `ExportService`, `IdleTimerService`, `ThemeModeNotifier`
- `integration_test` dev dependency added but **zero integration test files** created

---

## 9. What Changed Since Revision 1

The following items were marked as missing or incomplete in Revision 1 and have since been implemented:

| # | Item | Before | After |
|---|---|---|---|
| 1 | Citizen GPS in emergency dialog | `TODO` comment, always 0,0 | Real `locationService.getCurrentPosition()` with fallback |
| 2 | Driver location tracking | Never started automatically | `_syncLocationTracking()` auto-starts/stops based on assignment |
| 3 | FCM token persistence | Token obtained, never saved | `userService.saveFcmToken()` + `onTokenRefresh` callback in `main.dart` |
| 4 | Dark mode | Hardcoded `ThemeMode.light` | `ThemeModeNotifier` + SharedPreferences, globally wired |
| 5 | Offline status banner | Not present | `MaterialBanner` in `main.dart` `builder:` watching `isOnlineProvider` |
| 6 | Session idle timeout | Not present | `IdleTimerService` with `WidgetsBindingObserver`, globally wired |
| 7 | Audit log service | Planned only | `AuditService` + `AuditEntry` model + `auditLogProvider` stream (200 entries) |
| 8 | PDF / CSV export service | Planned only | `ExportService`: A4 PDF tables + RFC-compliant CSV for incidents and units |
| 9 | ePCR data entry UI (Driver) | Absent | `EpcrFormScreen` — 5-step Stepper wired to `PatientCareReportService` |
| 10 | Maintenance UI (Municipal Admin) | Absent | `MaintenanceScreen` — 3-tab (Upcoming/All/Completed), full CRUD wired |
| 11 | Citizen Live Incident Tracking | Absent | `IncidentTrackingScreen` — flutter_map, unit GPS marker, 7-step progress, ETA |
| 12 | Citizen-dedicated login screen | Absent | `CitizenLoginScreen` — emergency gradient branding, role-validated login |
| 13 | New test coverage | 6 test files | 4 new test files added (2 model + 2 service) |

### New Dependencies Added

```yaml
pdf: ^3.11.1
printing: ^5.13.4
csv: ^6.0.0
shared_preferences: ^2.3.4
url_launcher: ^6.3.1
path_provider: ^2.1.5
package_info_plus: ^8.1.3
integration_test: (dev)
```

---

## 10. Remaining Gaps & Incomplete Work

### 🟡 Partially Done — Service Exists, UI Not Connected

| Gap | Location | Details |
|---|---|---|
| Audit log — no call sites | All screens | `AuditService.log()` is never called anywhere. Logs will always be empty. |
| Export — no UI entry points | Reports screen, admin dashboards | `ExportService.printIncidentsPdf()` / `incidentsToCsv()` never called |
| Dark mode toggle widget | Settings screens (all roles) | `themeModeProvider` works but no toggle switch in any UI |
| Citizen tracking navigation | `citizen_dashboard.dart` line 391 | History `ListTile` has chevron arrow but no `onTap` → route to `/citizen/track` |
| Citizen address (reverse geocoding) | `citizen_dashboard.dart` | Address field still hardcoded to `'Location pending...'` |

### 🟡 Screen Shells / TODO Stubs

| Gap | Location | Code Evidence |
|---|---|---|
| Driver history tab | `driver_dashboard.dart` line 556 | `// TODO: Implement completed incidents history from Firebase` |
| Driver hospital selection | `driver_dashboard.dart` line 317 | `// TODO: Show hospital selection dialog` |
| Driver Quick Actions — Navigate | `driver_dashboard.dart` line 596 | `onTap: () {}` |
| Driver Quick Actions — Details | `driver_dashboard.dart` line 603 | `onTap: () {}` |
| Driver profile settings | `driver_dashboard.dart` lines 603–610 | All `onTap: () {}` |
| Hospital sidebar navigation | `hospital_dashboard.dart` line 209 | `onTap: () {}` for all nav items |
| Citizen Quick Services (4 tiles) | `citizen_dashboard.dart` lines 168, 446, 453, 460 | All `onTap: () {}` |
| Citizen profile items | `citizen_dashboard.dart` lines 446–460 | Emergency Contacts, Medical Info, Notifications all stubs |
| ePCR hospital picker | `epcr_form_screen.dart` | Free-text field, not bound to hospital entity |
| Notification badge (Hospital) | `hospital_dashboard.dart` | Badge always shows `'0'` |

### ❌ Not Implemented at All

| Gap | Priority |
|---|---|
| Firebase Cloud Functions | High — needed for atomic dispatch, notifications on status changes, cleanup jobs |
| Firebase Security Rules | High — currently open/default rules risk data exposure |
| Hospital sub-screens (Transfer History, Bed Availability) | High |
| ePCR viewer in Hospital Dashboard | High |
| Integration tests | Medium |
| Screen-level widget tests for new screens | Medium |
| Profile edit screens (Driver, Hospital, Dispatcher) | Medium |
| Push notification message handlers (foreground / background tap handling) | Medium |
| Reverse geocoding for citizen address | Low |

---

## 11. Recommendations (Priority Order)

### Priority 1 — Security (Do Before Any Deployment)

1. **Write Firebase Security Rules** — Current rules allow unauthenticated writes to all RTDB paths. Implement role-scoped read/write rules matching the app's role model. This is a critical security gap.
2. **Add Firebase App Check** — Prevent unauthorized clients from hitting the database.

### Priority 2 — Closing Wiring Gaps (High UX Impact)

3. **Wire audit log call sites** — Add `auditService.log()` in `IncidentService`, `UserService`, and `MaintenanceService` at every significant state change. The service is ready; it just needs to be called.
4. **Wire export buttons in ReportsScreen** — Add two `ElevatedButton`s calling `exportService.printIncidentsPdf(incidents)` and `exportService.incidentsToCsv(incidents)`. All the logic exists.
5. **Wire IncidentTrackingScreen navigation** — In `citizen_dashboard.dart`, add `onTap` to the history `ListTile` that calls `context.push(AppRoutes.citizenIncidentTracking, queryParameters: {'municipalityId': ..., 'incidentId': ...})`.

### Priority 3 — Core Missing Features

6. **Hospital sidebar navigation** — Implement content switching for Transfer History, Bed Availability, and Settings tabs.
7. **Hospital ePCR viewer** — Add a screen to read incoming `PatientCareReport` records linked to the hospital.
8. **Driver hospital selection** — Replace `TODO` in `_handleStatusChange()` with a dialog listing hospitals in the municipality via `hospitalServiceProvider`.
9. **Driver history tab** — Stream completed incidents where `assignedUnitId == unit.id` from RTDB.
10. **Citizen Quick Services** — Implement `url_launcher` for Call 911 (`tel:911`), use `locationService` + Google Places / Overpass API for Nearby Hospitals.

### Priority 4 — Polish & Infrastructure

11. **Dark mode toggle UI** — Add a `SwitchListTile` in each role's settings/profile screen calling `ref.read(themeModeProvider.notifier).toggle()`.
12. **Firebase Cloud Functions** — Write functions for: new-incident push to dispatcher, status-change push to citizen, idle unit alerting, dispatch lock (atomic assign).
13. **ePCR hospital picker** — Replace free-text with a `DropdownButtonFormField` powered by `ref.watch(municipalityHospitalsProvider(municipalityId))`.
14. **Reverse geocoding** — Use `geocoding` package or Google Places API to populate address string from GPS coordinates.
15. **Integration tests** — The `integration_test` dev dependency is already added. Write at least one end-to-end flow per role (login → primary action → logout).

---

## 12. Overall Completion Estimate

| Role / Area | Rev 1 | Rev 2 |
|---|---|---|
| Auth flows | 95% | 95% |
| Super Admin | 80% | 85% |
| Municipal Admin | 75% | 92% |
| Dispatcher | 90% | 92% |
| Driver / Paramedic | 55% | 72% |
| Citizen | 50% | 68% |
| Hospital Staff | 55% | 58% |
| Core Services | 70% | 88% |
| Global App Layer | 55% | 93% |
| Routing | 80% | 97% |
| Test Coverage | 55% | 65% |
| Security | 20% | 20% |
| Cloud Functions | 0% | 0% |
| **Overall** | **~65%** | **~78–80%** |

The biggest remaining delta is in Hospital Staff (missing 3 sub-screens + ePCR viewer), Cloud Functions (entirely absent), and Firebase Security Rules (untouched). Addressing the Priority 1 and Priority 2 items above, particularly security rules, export wiring, audit call sites, and citizen tracking navigation, would push completion past 85% with minimal effort since most of the service logic is already built.
