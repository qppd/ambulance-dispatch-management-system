# 🚑 Ambulance Dispatch Management System (ADMS)

> A multi-role, real-time Computer-Aided Dispatch (CAD) platform built with Flutter and Firebase, designed to streamline emergency medical response operations for Local Government Units (LGUs) and emergency services providers.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-Dart_%5E3.9.0-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Realtime%20DB%20%7C%20Auth%20%7C%20FCM-FFCA28?logo=firebase)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-Web%20%7C%20Android%20%7C%20iOS%20%7C%20Desktop-lightgrey)]()
[![Riverpod](https://img.shields.io/badge/State-Riverpod%202.x-00BCD4)]()

---

## 📌 Project Status

**🔧 In Development — MVP Stage**

The core architecture, authentication system, data models, service layer, and primary dashboards are fully implemented and connected to live Firebase services. All Super Admin management screens (User Management, Reports & Analytics, System Settings) are now fully wired to Firebase. The Live Dispatch Map uses flutter_map with Mapbox tiles.

| Module | Status |
|---|---|
| Firebase Authentication (login, register, verify, approve) | ✅ Complete |
| Role-based routing & navigation guards | ✅ Complete |
| Incident lifecycle management (CRUD + status tracking) | ✅ Complete |
| Ambulance unit management (CRUD + real-time streams) | ✅ Complete |
| Dispatch workflow (full 7-step lifecycle) | ✅ Complete |
| Municipality management (CRUD — Super Admin) | ✅ Complete |
| Hospital management (CRUD + real-time streams) | ✅ Complete |
| FCM Push Notifications (topic-based subscriptions) | ✅ Complete |
| Dispatcher Dashboard (3-panel, real-time Firebase) | ✅ Complete |
| Driver Dashboard (mobile-optimized, real-time Firebase) | ✅ Complete |
| Citizen Dashboard (emergency request + history) | ✅ Complete |
| Hospital Dashboard (responsive, real-time Firebase) | ✅ Complete |
| Municipal Admin Dashboard (responsive + sidebar) | ✅ Complete |
| Super Admin Dashboard (municipality overview) | ✅ Complete |
| Auth screens (login, register, forgot password, verify, pending) | ✅ Complete |
| Live Dispatch Map (ambulance tracking on map) | ✅ Complete — flutter_map + Mapbox tiles, live incident pins & unit markers |
| User Management screen (Super Admin) | ✅ Complete — wired to Firebase, approve/deactivate/search/role-filter |
| Reports & Analytics screen (Super Admin) | ✅ Complete — real data aggregation, fl_chart bar/pie charts |
| System Settings screen (Super Admin) | ✅ Complete — persisted to Firebase RTDB `/systemConfig` |
| Model-level unit tests | ✅ Implemented (4 model test files) |
| Widget/integration tests | ✅ Expanded — SystemConfigNotifier unit tests, SystemSettings/UserManagement/DispatchMap widget tests |

---

## 📖 Overview

ADMS is a cross-platform Flutter application providing a unified, role-specific interface for every actor in the emergency medical response chain. Dispatchers manage an incident queue and dispatch ambulance units from a real-time web command center. Ambulance crew receive assignments and update mission status from a mobile dashboard. Citizens request emergency assistance and track response progress. Hospital staff monitor incoming patient transfers. Municipal admins oversee their fleet and operations. Super admins manage the entire platform across all municipalities.

All dashboards are powered by live **Firebase Realtime Database** streams — any status change made by one role is reflected instantly to all other connected parties with no polling or manual refresh.

---

## ✨ Implemented Features

### 🔐 Authentication & Account Lifecycle
- Email/password sign-in and registration via **Firebase Authentication** (not mocked)
- Email verification flow with dedicated screen and resend capability
- Account approval workflow — roles that require admin approval (e.g., dispatcher, driver) are held in a `pending` state and shown a dedicated waiting screen
- Deactivated account detection with automatic sign-out
- Password reset via email link
- Persistent session management via Firebase Auth state streams

### 👥 Role-Based Access Control
Six distinct user roles, each with isolated navigation and data access:

| Role | Platform | Responsibilities |
|---|---|---|
| `superAdmin` | Web | Full system access; manages all municipalities, users, settings, and reports |
| `municipalAdmin` | Web | Manages dispatchers, units, and operations for their municipality |
| `dispatcher` | Web/Desktop | Receives incidents, acknowledges, assigns units, monitors queue |
| `driver` (Ambulance Crew) | Mobile | Receives dispatch assignments, updates mission status |
| `citizen` | Mobile | Requests emergency assistance, tracks response status |
| `hospitalStaff` | Web/Mobile | Monitors incoming patient transfers and ER capacity |

### 🚨 Incident Management
- Citizens can request emergency assistance, creating an incident with severity (`critical`, `urgent`, `normal`)
- Full incident lifecycle tracked through 9 statuses:
  `pending → acknowledged → dispatched → enRoute → onScene → transporting → atHospital → resolved / cancelled`
- Real-time incident stream per municipality via RTDB
- Per-reporter incident history stream
- Per-driver incident history stream

### 🚑 Ambulance Unit Management
- Full CRUD for ambulance units scoped per municipality
- Four unit types: **ALS** (Advanced Life Support), **BLS** (Basic Life Support), **MICU** (Mobile ICU), **Rescue**
- Six unit statuses: `available`, `enRoute`, `onScene`, `transporting`, `atHospital`, `outOfService`
- Real-time unit status streams per municipality
- Driver-to-unit binding via `/driver_units/{driverUid}` RTDB node

### 📡 Dispatch Workflow
End-to-end orchestration handled by `DispatchService` with **atomic multi-path RTDB updates**:
1. Citizen reports → incident created (`pending`)
2. Dispatcher acknowledges → incident (`acknowledged`) — dispatcher assigned
3. Dispatcher selects unit → incident (`dispatched`) + unit (`enRoute`) + driver bound — atomic write
4. Driver arrives at scene → incident (`onScene`) + unit (`onScene`)
5. Driver begins transport → incident (`transporting`) + unit (`transporting`)
6. Driver arrives at hospital → incident (`atHospital`) + unit (`atHospital`)
7. Driver completes mission → incident (`resolved`) + unit (`available`)

### 🏥 Hospital Management
- CRUD for hospital records scoped per municipality
- Real-time stream of all hospitals and accepting-only hospitals
- Hospital Dashboard streams incoming patient transfer alerts
- Responsive layout (wide sidebar for desktop, bottom nav for mobile)

### 🏛️ Municipality Management (Super Admin)
- Full CRUD for municipality records via `MunicipalityManagementScreen`
- Activate / deactivate municipalities
- All incident, unit, and hospital data is scoped under municipality ID

### 🔔 Push Notifications (FCM)
Topic-based subscription model via Firebase Cloud Messaging:
- `municipality_{id}` — All alerts for a municipality
- `municipality_{id}_dispatchers` — Dispatcher-only alerts
- `municipality_{id}_drivers` — Driver assignments
- `municipality_{id}_hospital_{hospitalId}` — Hospital transfer alerts
- `incident_{municipalityId}_{incidentId}` — Per-incident status updates
- `global_announcements` — System-wide broadcast

### 🎨 UI & Theming
- Light/dark theme support via `AppTheme` (currently defaults to light)
- Animated UI transitions powered by `flutter_animate`
- Role-specific color coding per user type (`AppColors`)
- Custom typography via `google_fonts`
- Responsive layouts across all dashboards (breakpoint-aware)

---

## 🏗️ Architecture Overview

### Pattern
Feature-first **Clean Architecture** with a service layer and repository pattern.

### App Structure

```
lib/
├── core/                    # Cross-cutting concerns
│   ├── data/
│   │   └── repositories/    # Repository interfaces + Firebase implementations
│   ├── models/              # Immutable domain models (Equatable)
│   ├── router/              # GoRouter config + route guards
│   ├── services/            # Firebase-backed service providers (Riverpod)
│   └── theme/               # Colors, typography, AppTheme
├── features/                # Role-scoped UI features
│   ├── auth/                # Login, register, verify, forgot password, pending approval
│   ├── citizen/             # Citizen mobile dashboard
│   ├── dispatcher/          # Dispatcher command center dashboard
│   ├── driver/              # Driver/crew mobile dashboard
│   ├── hospital/            # Hospital staff dashboard
│   ├── municipal_admin/     # Municipal admin dashboard
│   └── super_admin/         # Super admin dashboard + management screens
├── shared/
│   └── widgets/             # Shared UI components
├── firebase_options.dart    # FlutterFire-generated Firebase config
└── main.dart                # App entry point
```

### Role-Based Navigation
`GoRouter` is configured with a `redirect` callback that reads the global `AuthState` via Riverpod and enforces the following rules:

- **Unauthenticated** → always redirected to `/` (Welcome screen)
- **Email not verified** → redirected to `/verify-email`
- **Pending approval** → redirected to `/pending-approval`
- **Authenticated** → redirected to their role's home route
- **Sub-route access** → role checked at route level (e.g., only `superAdmin` can access `/super-admin/*`)

### Service Layer
All Firebase interactions are encapsulated in dedicated Riverpod `Provider`s:

| Service | Responsibility |
|---|---|
| `AuthService` / `FirebaseAuthRepository` | Sign-in, register, sign-out, auth state stream |
| `IncidentService` | Incident CRUD, per-municipality / per-reporter / per-driver streams |
| `DispatchService` | Atomic dispatch workflow, unit assignment, status transitions |
| `UnitService` | Unit CRUD, real-time unit streams, driver-unit binding |
| `HospitalService` | Hospital CRUD, accepting-hospitals stream |
| `MunicipalityService` | Municipality CRUD, active municipality streams |
| `NotificationService` | FCM initialization, permission request, topic subscriptions |

### Firebase Realtime Database Structure
```
/users/{uid}/                          ← User profiles + roles
/incidents/{municipalityId}/{id}/      ← Incident records
/units/{municipalityId}/{id}/          ← Ambulance unit records
/municipalities/{id}/                  ← Municipality records
/hospitals/{municipalityId}/{id}/      ← Hospital records
/user_incidents/{reporterUid}/{id}/    ← Reporter → incident index
/driver_units/{driverUid}/             ← Driver → unit binding
```

### State Management
Riverpod `StateNotifierProvider` manages authentication state. All Firebase data is exposed as `StreamProvider` and `StreamProvider.family`, so dashboards rebuild reactively on any RTDB change. No manual `setState` calls are needed for data updates.

---

## 🛠️ Technology Stack

| Category | Technology | Version |
|---|---|---|
| UI Framework | Flutter | Dart SDK `^3.9.0` |
| Authentication | Firebase Auth | `^6.1.4` |
| Real-time Database | Firebase Realtime Database | `^12.1.3` |
| Push Notifications | Firebase Cloud Messaging | `^16.1.1` |
| Analytics | Firebase Analytics | `^12.1.2` |
| Firebase Core | firebase_core | `^4.4.0` |
| State Management | Flutter Riverpod | `^2.6.1` |
| Navigation/Routing | GoRouter | `^17.1.0` |
| UI Animations | flutter_animate | `^4.5.2` |
| Fonts | google_fonts | `^8.0.2` |
| Value Equality | equatable | `^2.0.7` |
| Internationalisation | intl | `^0.20.2` |
| Environment Config | flutter_dotenv | `^6.0.0` |
| Network Connectivity | connectivity_plus | `^7.0.0` |
| GPS / Location | geolocator | `^14.0.0` |
| UUID Generation | uuid | `^4.5.1` |
| Mocking (tests) | mockito | `^5.4.6` |
| Code Generation | build_runner | `^2.4.15` |

> All versions are extracted directly from `pubspec.yaml`. The live dispatch map uses `flutter_map` with Mapbox vector tiles. A Mapbox access token in `.env` (key `MAPBOX_ACCESS_TOKEN`) enables Mapbox rendering; without it the map falls back to OpenStreetMap Humanitarian tiles automatically.

---

## ⚙️ Installation & Setup

### Prerequisites

| Requirement | Version |
|---|---|
| Flutter SDK | Dart `^3.9.0` compatible |
| Dart SDK | `^3.9.0` |
| FlutterFire CLI | Latest |
| Firebase CLI | Latest |
| Git | Any recent version |

**Platform-specific requirements:**
- **Windows**: Visual Studio 2022 with Desktop development with C++
- **macOS**: Xcode 14+
- **Linux**: Required development libraries (see Flutter documentation)
- **Android**: Android SDK, Android Studio
- **iOS**: Xcode, CocoaPods (macOS only)

### 1. Clone the Repository

```bash
git clone https://github.com/qppd/ambulance-dispatch-management-system.git
cd ambulance-dispatch-management-system/source/flutter/adms
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

**a) Create a Firebase project** at [console.firebase.google.com](https://console.firebase.google.com)

**b) Enable the following services:**
- Authentication → Email/Password provider
- Realtime Database → Create database (choose region)
- Cloud Messaging (for push notifications)
- Analytics (optional)

**c) Install and run FlutterFire CLI:**

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This generates `lib/firebase_options.dart` with your project credentials. A template is provided at `lib/firebase_options_template.dart` for reference.

**d) Deploy Realtime Database security rules:**

```bash
firebase deploy --only database
```

The rules file is at `source/flutter/adms/database.rules.json`.

### 4. Environment Variables

Create a `.env` file in `source/flutter/adms/`:

```env
# Add any required environment keys here
# e.g., Google Maps API key (when map integration is added)
MAPS_API_KEY=your_google_maps_api_key_here
```

> ⚠️ **Do not commit `.env` to version control.**

### 5. Seed Initial Super Admin

Firebase has no built-in admin seeding. After registering via the app:
1. Open Firebase Console → Realtime Database → `/users/{uid}`
2. Set `"role": "superAdmin"`, `"isApproved": true`, `"isActive": true`

This user can then approve all subsequent registrations through the app.

---

## 🚀 Running the Application

### Platform Commands

```bash
# Web (recommended for dispatcher/admin roles)
flutter run -d chrome

# Android (recommended for driver/citizen roles)
flutter run -d android

# iOS (macOS only)
flutter run -d ios

# Windows Desktop
flutter run -d windows

# macOS Desktop
flutter run -d macos

# Linux Desktop
flutter run -d linux
```

### Production Builds

```bash
flutter build web --release
flutter build apk --release
flutter build appbundle --release
flutter build ios --release        # macOS only
flutter build windows --release
flutter build linux --release
flutter build macos --release
```

---

## 🔐 Environment Configuration

### Firebase Setup (Required)

| File | Purpose |
|---|---|
| `lib/firebase_options.dart` | Auto-generated by FlutterFire CLI — contains API keys and project identifiers |
| `lib/firebase_options_template.dart` | Reference template — do not use directly |
| `database.rules.json` | Firebase RTDB security rules — deploy with Firebase CLI |

### Google Services Files

| Platform | File | Location |
|---|---|---|
| Android | `google-services.json` | `android/app/` |
| iOS | `GoogleService-Info.plist` | `ios/Runner/` |

These files are generated during `flutterfire configure` and are **not committed** — they contain sensitive Firebase credentials.

### Required Firebase Services

| Firebase Service | Purpose |
|---|---|
| **Authentication** | Email/password sign-in, email verification, password reset |
| **Realtime Database** | All app data — incidents, units, users, municipalities, hospitals |
| **Cloud Messaging** | Push notifications for dispatch alerts and status updates |
| **Analytics** | Usage tracking (initialized in `main.dart`, optional) |

### Firebase RTDB Security Rules

The file `database.rules.json` contains role-based security rules:

| Role | Permissions |
|---|---|
| **superAdmin** | Read/write all nodes across all municipalities |
| **municipalAdmin** | Read/write within own municipality |
| **dispatcher** | Read/write incidents and units in own municipality |
| **driver** | Read own assignments, write own unit status/location |
| **citizen** | Report incidents, read own incidents |
| **hospitalStaff** | Read incoming patients, write own hospital capacity |

---

## 🧪 Testing

### Current Coverage

Tests focus at the **model layer** and now include **service-layer unit tests** and **widget tests** for key screens.

| Test File | Scope |
|---|---|
| `test/models/incident_test.dart` | `Incident` model, `IncidentStatus`, `IncidentSeverity` |
| `test/models/ambulance_unit_test.dart` | `AmbulanceUnit` model, `UnitStatus`, `UnitType` |
| `test/models/hospital_test.dart` | `Hospital` model |
| `test/models/municipality_test.dart` | `Municipality` model |
| `test/widget_test.dart` | App smoke-test (renders welcome screen) |
| `test/widgets/system_settings_screen_test.dart` | Widget tests — loading, sections, toggles, save |
| `test/widgets/user_management_screen_test.dart` | Widget tests — user list, search, role filter |
| `test/widgets/dispatch_map_test.dart` | Widget tests — `DispatchMapWidget` rendering |
| `test/services/system_config_notifier_test.dart` | Unit tests — `SystemConfigNotifier` + model round-trip |

### Running Tests

```bash
# Run all tests
flutter test

# Run a specific model test
flutter test test/models/incident_test.dart

# Run with coverage
flutter test --coverage
```

### Generating Mocks

```bash
dart run build_runner build
```

---

### 6. Proximity-Based Dispatching

When an emergency call comes in, the system immediately calculates which available unit can reach the scene fastest, removing human guesswork and reducing response times.

**Dispatch Algorithm Factors**

- **Geographic Distance**: Straight-line and road network distance calculations
- **Unit Availability**: Only considers units in "Available" status
- **Real-Time Traffic**: Incorporates current traffic conditions from mapping APIs
- **Unit Capabilities**: Matches advanced life support (ALS) vs basic life support (BLS) requirements
- **Crew Qualifications**: Considers paramedic vs EMT staffing when relevant
- **Hospital Proximity**: For transfers, factors distance to destination facility
- **Station Coverage**: Maintains minimum coverage in all geographic zones

**Dispatch Suggestions**
When a dispatcher opens a new incident, the system presents:
1. Recommended unit with estimated arrival time
2. Alternative units ranked by proximity and capability
3. Visual map showing all available units relative to incident location
4. Coverage impact analysis (which areas will be underserved if this unit is dispatched)

**Manual Override**
Experienced dispatchers retain full authority to override system recommendations based on factors the algorithm cannot assess, such as:
- Knowledge of specific crew strengths
- Ongoing situations that make certain units preferable
- Political or administrative considerations
- Crew safety concerns

The nearest-neighbor search algorithm uses spatial indexing for sub-second response times even with large fleets. Future versions may incorporate historical travel time data to improve arrival time predictions beyond simple distance and current traffic.

---

### 7. Demand Pattern Forecasting

Predictive analytics transform emergency services from reactive to proactive by anticipating demand before it occurs. The forecasting engine analyzes historical patterns to predict when and where emergencies are likely to happen.

**Temporal Pattern Analysis**

**Time of Day Patterns**
- Morning rush hour incidents
- Lunch time medical calls
- Evening alcohol-related emergencies
- Overnight cardiac events

**Day of Week Variations**
- Weekday industrial accidents
- Weekend recreational injuries
- Sunday morning transport requests
- Friday night trauma spikes

**Seasonal Trends**
- Summer heat-related emergencies
- Rainy season accidents
- Holiday period demand surges
- School year patterns affecting pediatric calls

**Special Event Forecasting**

The system maintains a calendar of known events that impact demand:

- **Community Events**: Fiestas, festivals, concerts, parades
- **Sports Events**: Major games, tournaments, marathons
- **Political Events**: Rallies, protests, official gatherings
- **Weather Events**: Forecasted storms, extreme heat warnings
- **Holiday Periods**: Christmas, New Year, Holy Week

**Forecast Applications**

- **Staffing Decisions**: Schedule additional units during predicted high-demand periods
- **Unit Positioning**: Pre-deploy ambulances near anticipated incident hotspots
- **Mutual Aid Planning**: Arrange backup coverage with neighboring jurisdictions
- **Resource Allocation**: Ensure adequate supplies and equipment before demand spikes

**Technical Approach**
The forecasting module performs time-series analysis on historical incident data, incorporating external factors like weather forecasts and event calendars. Statistical models detect patterns and generate probability distributions for expected call volumes. Machine learning models may eventually enhance prediction accuracy by identifying subtle correlations in the data.

Dashboard visualizations show administrators the forecasted demand curve for the next 24-72 hours, enabling proactive decision-making rather than reactive crisis management.

---

### 8. Geospatial Heatmapping

Understanding where emergencies occur geographically reveals critical insights for strategic planning. The heatmap visualization transforms incident data into actionable intelligence about geographic risk patterns.

**Heatmap Visualization**

The system generates color-coded overlays on the map showing incident density:

- **Red Zones**: High frequency of emergency calls
- **Orange Zones**: Moderate incident activity
- **Yellow Zones**: Below-average call volume
- **Blue/Green Zones**: Minimal emergency activity

**Heatmap Variations**

- **Overall Incident Density**: All emergency types combined
- **Type-Specific Heatmaps**: Cardiac events, trauma, respiratory emergencies shown separately
- **Time-Filtered Views**: Heatmaps for specific times of day or days of week
- **Seasonal Comparisons**: Compare current patterns to historical baselines

**Strategic Applications**

**Station Placement Planning**
Identify underserved geographic areas where new stations or sub-stations could improve coverage and reduce response times.

**Standby Positioning**
During low-demand periods, position available units at strategic locations within high-risk zones to minimize response distances.

**Community Outreach**
Target public health education and prevention programs in areas with high concentrations of preventable emergencies.

**Resource Allocation**
Distribute vehicles and equipment based on geographic demand patterns rather than equal distribution across all areas.

**Performance Analysis**
Overlay response time data with incident density to identify areas where geographic challenges (traffic, distance, terrain) create response time problems.

**Technical Foundation**
The heatmap engine processes geocoded incident data through kernel density estimation algorithms to create smooth, visually intuitive representations of incident concentration. Users can adjust time windows, incident types, and geographic zoom levels interactively, with real-time recalculation of density patterns.

---

### 9. System Status Management (SSM) Suggestions

The SSM module acts as a strategic advisor, generating recommendations for optimal unit positioning based on current system status, forecasted demand, and geographic considerations.

**Recommendation Types**

**Standby Position Suggestions**
"Unit 3 should stage near Plaza Central due to predicted high demand during tonight's festival."

**Coverage Gap Alerts**
"Northeast district currently has no available units. Consider repositioning Unit 7 from adjacent zone."

**Mutual Aid Coordination**
"Expected call volume exceeds capacity during upcoming marathon. Request standby unit from neighboring municipality."

**Maintenance Window Optimization**
"Schedule routine maintenance for Unit 5 during forecasted low-demand window tomorrow afternoon."

**SSM Decision Logic**

The recommendation engine considers:
1. Current geographic distribution of available units
2. Forecasted demand patterns (from module 7)
3. Historical incident patterns (from module 8 heatmaps)
4. Special events and known risk factors
5. Current queue depth and pending incidents
6. Mutual aid agreements and backup resources

**Proactive vs Reactive**
Traditional dispatch is purely reactive—wait for a call, send a unit. SSM shifts to proactive operations where units are strategically positioned before incidents occur, reducing the distance they must travel and improving response times without increasing fleet size.

**Implementation Example**
During a holiday celebration with crowds concentrated in the downtown area, SSM might recommend:
- Staging two units near the event perimeter
- Positioning one unit on the main highway route to the event
- Keeping one unit available at the station for non-event emergencies
- Alerting neighboring jurisdictions of potential need for mutual aid

These recommendations appear as actionable alerts on the dispatcher and supervisor dashboards, with one-click acknowledgment and implementation tracking.

---

### 10. Maintenance Scheduling

Ambulances that break down during emergencies fail the community. The maintenance scheduling module ensures vehicles remain reliable through systematic preventive care.

**Maintenance Tracking**

**Service Intervals**
- **Time-Based**: Maintenance due every 90 days, 6 months, annually
- **Mileage-Based**: Service required every 5,000, 10,000, or 25,000 kilometers
- **Equipment-Based**: Calibration schedules for medical devices
- **Inspection-Based**: Required safety inspections per regulations

**Reminder System**

Automated alerts notify fleet managers when:
- Maintenance is due within 7 days or 500 kilometers
- Service is overdue
- Vehicle approaching mileage milestone
- Equipment calibration expiring

**Maintenance History**
Complete service records for each vehicle:
- Dates of all maintenance performed
- Work orders and service descriptions
- Parts replaced
- Technician notes
- Cost tracking

**Scheduling Optimization**

The system suggests optimal maintenance windows by analyzing:
- Historical demand patterns (schedule during low-call-volume periods)
- Fleet capacity (ensure minimum coverage maintained)
- Unit utilization rates (prioritize high-mileage vehicles)
- Seasonal factors (perform major service before peak demand seasons)

**Out-of-Service Management**
When a unit enters maintenance:
- Automatic status change to "Out of Service"
- Removal from dispatch eligibility
- Coverage impact analysis
- Estimated return-to-service date tracking

**Technical Note**
This module does not predict mechanical failures or perform diagnostic analysis of vehicle systems. It is a reminder and scheduling tool designed to prevent breakdowns through adherence to manufacturer-recommended maintenance schedules. Future enhancements could integrate with vehicle telematics systems for predictive maintenance based on actual component wear.

---

### 11. Mobile Application (for Crew)

Ambulance crews need access to critical information in the field. The mobile application puts essential dispatch data, navigation, and communication tools in the hands of paramedics and EMTs.

**Core Mobile Features**

**Dispatch Detail View**
When a unit is dispatched, the mobile app immediately displays:
- Incident address and map location
- Caller information and callback number
- Nature of emergency and priority level
- Special notes (access codes, safety warnings, etc.)
- Driving directions to scene

**Integrated Navigation**
One-tap launch of turn-by-turn navigation to:
- Incident scene location
- Nearest appropriate hospital
- Return to station

**Patient Information**
Access to:
- Patient demographics (if repeat caller with history)
- Medical alert information (allergies, DNR status, etc.)
- Previous call history
- Special care requirements

**Communication Tools**
- Direct messaging with dispatch center
- Status update buttons
- Voice communication over cellular network
- Emergency assistance button

**Status Management**
Large, easy-to-tap buttons for status changes:
- "En Route" (acknowledge dispatch)
- "On Scene" (arrived at incident)
- "Transporting" (patient loaded)
- "At Hospital" (delivered patient)
- "Clearing" (completing paperwork)
- "Available" (ready for next call)

**Offline Capability**
The mobile app is designed with an offline-first architecture to handle areas with poor cellular coverage:
- Dispatch details cached locally when received
- Status updates queued and sent when connection resumes
- Maps available in offline mode
- Critical communications prioritized when bandwidth limited

**Platform Support**
The mobile application is built with Flutter, providing native-quality experiences on:
- Android tablets and phones
- iOS devices (iPad and iPhone)
- Rugged tablets designed for emergency services

**Security Considerations**
- Automatic screen lock when idle
- PIN or biometric authentication required
- Patient information encrypted at rest and in transit
- Remote wipe capability if device lost or stolen

---

### 12. Electronic Patient Care Reporting (ePCR)

Digital documentation of patient care is critical for clinical continuity, billing, and legal protection. The ePCR module captures comprehensive patient encounter data from scene to hospital.

**Current Status: Optional / In Planning**

This feature is currently under development due to workflow integration challenges. In the existing operational model, ambulance drivers complete paper forms at the hospital that require physical signatures from receiving medical staff. Transitioning to a fully digital ePCR system requires:
- Buy-in from receiving hospitals
- Integration with hospital information systems
- Training for both EMS crews and hospital staff
- Legal validation of electronic signatures

**Interim Capabilities**

The current implementation provides:

**Basic Patient Documentation**
- Patient demographics (name, age, gender)
- Chief complaint
- Basic vital signs (blood pressure, pulse, respiratory rate, oxygen saturation)
- Treatments administered
- Medications given

**Digital Handover Log**
A simplified digital record that crews can use to:
- Document key information for their own records
- Generate a summary for verbal handover
- Create a searchable incident history

**Hospital Acknowledgment**
Digital confirmation that:
- Patient was delivered to hospital
- Receiving facility and staff identified
- Time of transfer recorded

**Future ePCR Vision**

The complete ePCR system will eventually include:

- Comprehensive vital signs tracking with trend graphs
- Medication administration records with dosage calculations
- Treatment protocols and clinical decision support
- Photo documentation (injuries, scene conditions)
- Electronic signature capture from hospital staff
- Automatic transmission to hospital EHR systems
- Billing code generation from clinical documentation
- NEMSIS (National EMS Information System) compliance
- Quality assurance review workflows

**Implementation Approach**
The system is being developed incrementally, starting with basic digital data capture and gradually expanding functionality as operational workflows adapt and hospital integration becomes feasible.

---

### 13. One-Tap Status Updates

Simplifying communication between field crews and dispatchers reduces radio traffic, decreases errors, and accelerates information flow. The one-tap interface makes status reporting effortless.

**Status Update Buttons**

Large, color-coded buttons on the mobile app:

- 🟢 **Arrived** (On Scene)
- 🔵 **Patient Loaded** (Transporting)
- 🟡 **At Hospital** (Patient Transferred)
- ⚪ **Available** (Ready for Next Call)

**Automatic Actions**

Each status update triggers multiple backend actions:

**When "Arrived" is tapped:**
- Unit status updated to "On Scene"
- Timestamp recorded for response time calculation
- Dispatcher notified
- Caller can be updated via automated SMS
- Coverage analysis recalculated

**When "Patient Loaded" is tapped:**
- Unit status updated to "Transporting"
- Hospital can be notified of inbound patient
- Estimated arrival time calculated
- Closest backup units identified for coverage

**When "At Hospital" is tapped:**
- Unit status updated to "At Hospital"
- Patient handover time recorded
- Hospital turnaround time tracking started
- ePCR completion reminder triggered

**When "Available" is tapped:**
- Unit status updated to "Available"
- Unit added back to dispatch pool
- Coverage map updated
- SSM module recalculates positioning suggestions

**Benefits**

- **Reduced Radio Congestion**: Fewer voice transmissions needed
- **Faster Communication**: No waiting for radio channel availability
- **Improved Accuracy**: Eliminates transcription errors from voice communications
- **Automatic Documentation**: All timestamps captured automatically
- **Better Situational Awareness**: Dispatchers see status changes instantly on their screens

**Fallback Options**
Radio and phone communication remain available when:
- Mobile app is unavailable
- Device battery is dead
- Crews need to communicate information beyond simple status updates
- Emergency situations require immediate dispatcher contact

---

### 14. Response Time Analytics

Response time is the most critical performance metric in emergency medical services. This module captures, calculates, and analyzes every component of the response timeline.

**Response Time Components**

**Call Processing Time (Dispatch Time)**
- From: 911 call received
- To: Unit dispatched
- Target: < 60 seconds for critical emergencies

**Travel Time**
- From: Unit dispatched
- To: Unit arrived on scene
- Target: < 8 minutes for urban areas, < 15 minutes for rural areas

**On-Scene Time**
- From: Arrival at scene
- To: Departure with patient
- Analysis: Identifies training needs or scene safety issues

**Transport Time**
- From: Departure from scene
- To: Arrival at hospital
- Analysis: Used for hospital load balancing

**Hospital Turnaround Time**
- From: Arrival at hospital
- To: Unit available again
- Analysis: Identifies hospitals with excessive delays

**Total Response Time**
- From: 911 call received
- To: Patient delivered to hospital
- Target: Varies by jurisdiction and emergency type

**Analytics Capabilities**

**Performance Dashboards**
- Real-time average response times
- Compliance with national and local standards
- Trend analysis (improving or deteriorating)
- Comparison between units, shifts, and time periods

**Bottleneck Identification**
The system automatically flags:
- Units with consistently slow response times
- Geographic areas with poor performance
- Times of day when delays are common
- Specific time components causing delays

**Benchmark Comparisons**
Compare performance against:
- Jurisdictional targets
- Historical performance
- National standards
- Peer EMS systems

**Outlier Detection**
Statistical analysis identifies:
- Unusually long response times requiring investigation
- Exceptional performance worth recognizing
- Data anomalies that may indicate recording errors

**Improvement Tracking**
When process changes are implemented:
- Before and after comparisons
- Statistical significance testing
- ROI calculations for equipment or staffing investments

**Data Visualization**
- Line graphs showing trends over time
- Bar charts comparing units or time periods
- Geographic heat maps of response time performance
- Distribution histograms showing compliance percentages

**Technical Implementation**
All timestamps are captured automatically from system events (dispatch, GPS arrival detection, manual status updates) and stored in a time-series database optimized for temporal analytics. Calculations are performed in real-time for operational dashboards and in batch for detailed reports.

---

### 15. KPI Dashboards (for LGU Officials)

Local government officials and EMS administrators need high-level visibility into system performance without getting lost in operational details. The KPI dashboard provides at-a-glance insights for decision-makers.

**Real-Time Operational Metrics**

**Active Incident Count**
Current number of open incidents by priority level, updated every few seconds.

**Unit Availability**
- X units available / Y total units
- Percentage of fleet in service
- Visual indicator (green if > 70%, yellow if 40-70%, red if < 40%)

**Average Response Time**
Rolling average for last 24 hours, last 7 days, last 30 days with trend indicators.

**Queue Depth**
Number of incidents waiting for dispatch with average wait time.

**Daily Performance Summary**

**Today's Statistics**
- Total incidents handled
- Average response time
- Incidents by priority level
- Peak demand times
- Unit utilization rates

**Call Type Distribution**
Pie chart showing percentage breakdown:
- Medical emergencies (cardiac, respiratory, trauma, etc.)
- Accidents
- Transfers
- Other

**Geographic Coverage Map**
Color-coded map showing:
- Current unit positions
- Areas currently covered within 8-minute response threshold
- Coverage gaps

**Trend Analysis**

**Week-over-Week Comparison**
- Incident volume change
- Response time improvement or deterioration
- Resource utilization trends

**Month-over-Month Analysis**
- Seasonal patterns
- Staffing adequacy
- Equipment utilization

**Compliance Monitoring**

**Performance Standards**
- Percentage of calls meeting response time targets
- Compliance with accreditation standards
- Quality assurance metrics

**Dashboard Customization**

Different stakeholder views:

**Mayor/Executive Dashboard**
- High-level KPIs only
- Public-facing statistics
- Budget utilization
- Comparison to other municipalities

**EMS Director Dashboard**
- Operational details
- Crew performance
- Equipment status
- Training needs

**Shift Supervisor Dashboard**
- Real-time operations
- Unit-specific metrics
- Immediate resource needs

**Access Control**
Role-based permissions ensure:
- Sensitive patient information protected
- Crew performance data accessible only to supervisors
- Public-facing dashboards contain no identifying information
- Audit logs track all dashboard access

**Export and Reporting**
- One-click export to PDF for meetings
- Scheduled email delivery of daily/weekly reports
- CSV export for custom analysis
- Embeddable widgets for public websites

---

### 16. Post-Incident Logs (History / Audit Trail)

Every emergency incident generates a wealth of data that serves multiple critical functions long after the patient is delivered to the hospital. The audit trail module provides complete, immutable documentation of everything that occurred.

**Comprehensive Timeline**

For each incident, the system records:

**Call Intake Phase**
- Exact time call received
- Caller identification
- Call duration
- Questions asked and answers received
- Priority assigned
- Dispatcher who handled call

**Dispatch Phase**
- Time incident entered queue
- Queue wait time
- Unit selected
- Dispatch time
- Alternative units considered
- Dispatcher decision notes

**Response Phase**
- Unit acknowledgment time
- Route taken (GPS breadcrumb trail)
- Estimated vs actual travel time
- Traffic conditions encountered
- Any delays or deviations

**On-Scene Phase**
- Arrival time
- Scene safety assessment
- Patient contact time
- Treatments initiated
- On-scene duration
- Decision to transport

**Transport Phase**
- Patient loaded time
- Destination hospital
- Transport route
- Patient condition updates
- Transport duration

**Hospital Transfer Phase**
- Hospital arrival time
- Receiving physician/nurse
- Patient handover time
- Paperwork completion time
- Unit clear time

**Incident Resolution**
- Total incident duration
- Final outcome
- Follow-up actions required
- Quality assurance flags

**Audit Trail Applications**

**Performance Improvement**
- Identify specific steps where delays occurred
- Compare similar incidents to find best practices
- Train dispatchers and crews using real examples

**Legal Protection**
- Complete, contemporaneous documentation of all actions
- Proof of response times and treatment provided
- Defense against liability claims

**Quality Assurance**
- Review crew adherence to protocols
- Verify dispatcher decision-making
- Identify training needs

**Accreditation and Compliance**
- Demonstrate compliance with national standards
- Provide data for accreditation reviews
- Document continuous improvement efforts

**Operational Research**
- Study patterns across thousands of incidents
- Validate the effectiveness of policy changes
- Build evidence base for resource requests

**Incident Replay**

Supervisors can replay an incident as if watching a recording:
- Timeline slider shows progression through phases
- Map displays unit movements
- Status changes highlighted
- Communications displayed in sequence

**Data Integrity**

**Immutability**
Once recorded, timeline events cannot be deleted or modified. Corrections are appended as new entries with timestamps, preserving the original record.

**Audit Logging**
The system logs:
- Who viewed each incident record
- When records were accessed
- What searches were performed
- Any exports or reports generated

**Retention Policies**
- Operational data retained for 7 years minimum
- Legal holds prevent deletion of records under investigation
- Archival procedures for historical data
- HIPAA-compliant data protection

**Search and Retrieval**

Powerful search capabilities allow users to find incidents by:
- Date and time ranges
- Incident type or priority
- Geographic area
- Unit or crew involved
- Caller information
- Hospital destination
- Custom data fields

**Reporting from Historical Data**
- Generate custom reports for specific time periods
- Export data for external analysis
- Create visualizations of trends
- Benchmark performance over time

---

## Technology Stack

### Frontend
- **Framework**: Flutter 3.38.6 (Dart SDK ^3.9.0)
- **State Management**: Riverpod (flutter_riverpod ^2.6.1) — StateNotifier + StreamProvider pattern
- **Routing**: GoRouter ^15.1.2 with role-based redirects
- **UI Components**: Material Design 3 (custom AppTheme with AppColors, AppTypography)
- **Fonts**: Inter (body), Plus Jakarta Sans (headings), JetBrains Mono (code)
- **Maps**: Google Maps Flutter Plugin (planned)
- **Geolocation**: geolocator ^14.0.0
- **Utilities**: equatable ^2.0.7, uuid ^4.5.1, connectivity_plus ^6.1.4

### Backend (Firebase — Serverless)
- **Authentication**: Firebase Auth ^5.7.0 (email/password + email verification + password reset)
- **Database**: Firebase Realtime Database ^11.6.0 (real-time sync, multi-path atomic writes)
- **Push Notifications**: Firebase Cloud Messaging ^15.4.0 (topic-based subscriptions)
- **Analytics**: Firebase Analytics ^11.6.0
- **Core**: Firebase Core ^3.13.0
- **Security**: Firebase RTDB security rules (role-based access control)
- **Configuration**: flutter_dotenv ^5.2.1 for environment variables

### RTDB Schema (Key Nodes)

| Node | Path | Purpose |
|------|------|---------|
| Users | `/users/{uid}` | User profiles with role, municipality, approval status |
| Municipalities | `/municipalities/{id}` | LGU data with denormalized stats |
| Incidents | `/incidents/{municipalityId}/{id}` | Emergency incidents with full lifecycle timestamps |
| Units | `/units/{municipalityId}/{id}` | Ambulance units with GPS, status, driver assignment |
| Hospitals | `/hospitals/{municipalityId}/{id}` | Hospital capacity, specialties, patient acceptance |
| User Incidents | `/user_incidents/{uid}/{id}` | Per-citizen incident index |
| Driver Units | `/driver_units/{uid}` | Per-driver unit assignment lookup |

### Development & Testing
- **Testing**: flutter_test, mockito ^5.4.6
- **Code Quality**: Dart Analyzer (analysis_options.yaml)
- **Version Control**: Git
- **IDE**: VS Code / Android Studio

### External Services
- **Maps & Routing**: Google Maps API (planned)
- **GPS**: Device geolocator for real-time ambulance tracking

---

## Installation

### Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK 3.38.6 or higher** - [Installation Guide](https://docs.flutter.dev/get-started/install)
- **Git 2.40+** - [Download Git](https://git-scm.com/downloads)
- **Firebase CLI** - [Install Firebase CLI](https://firebase.google.com/docs/cli)
- **FlutterFire CLI** - Run `dart pub global activate flutterfire_cli`
- **Visual Studio Code** or **Android Studio** (recommended IDEs)
- **A Firebase project** — [Create one at Firebase Console](https://console.firebase.google.com)
- **Platform-specific requirements**:
  - **Windows**: Visual Studio 2022 with Desktop development with C++
  - **macOS**: Xcode 14+
  - **Linux**: Required development libraries (see Flutter documentation)
  - **Android**: Android SDK, Android Studio
  - **iOS**: Xcode, CocoaPods (macOS only)

### Clone the Repository

```bash
git clone https://github.com/qppd/ambulance-dispatch-management-system.git
cd ambulance-dispatch-management-system
```

### Firebase Project Setup

1. **Create a Firebase project** at [Firebase Console](https://console.firebase.google.com)

2. **Enable Firebase services**:
   - **Authentication** → Sign-in method → Enable **Email/Password**
   - **Realtime Database** → Create database → Choose region → Start in **locked mode**
   - **Cloud Messaging** → Enabled by default

3. **Configure FlutterFire** (generates `firebase_options.dart` automatically):
```bash
cd source/flutter/adms
flutterfire configure --project=your-firebase-project-id
```
This will generate `lib/firebase_options.dart` with your project credentials for all platforms.

> **Note**: A template file `lib/firebase_options_template.dart` is included for reference. Once you run `flutterfire configure`, it will generate the real `firebase_options.dart`. Update the import in `lib/main.dart` from `firebase_options_template.dart` to `firebase_options.dart`.

4. **Deploy RTDB security rules**:
```bash
firebase deploy --only database --project=your-firebase-project-id
```
This deploys the rules from `database.rules.json` which enforce role-based access control for all nodes.

### Flutter Project Setup

```bash
cd source/flutter/adms
flutter pub get
```

### Configuration

1. **Copy environment template**:
```bash
cp .env.example .env
```

2. **Edit `.env` file with your Firebase credentials**:
```
# Firebase Project
FIREBASE_PROJECT_ID=your-project-id

# Firebase Web Config
FIREBASE_WEB_API_KEY=your-web-api-key
FIREBASE_WEB_APP_ID=your-web-app-id
FIREBASE_WEB_MESSAGING_SENDER_ID=your-sender-id
FIREBASE_WEB_AUTH_DOMAIN=your-project.firebaseapp.com
FIREBASE_WEB_DATABASE_URL=https://your-project-default-rtdb.firebaseio.com
FIREBASE_WEB_STORAGE_BUCKET=your-project.appspot.com

# Firebase Android Config
FIREBASE_ANDROID_API_KEY=your-android-api-key
FIREBASE_ANDROID_APP_ID=your-android-app-id

# Firebase iOS Config
FIREBASE_IOS_API_KEY=your-ios-api-key
FIREBASE_IOS_APP_ID=your-ios-app-id
FIREBASE_IOS_BUNDLE_ID=com.example.adms

# Optional
GOOGLE_MAPS_API_KEY=your-google-maps-key
```

> **Important**: The `.env` file and `firebase_options.dart` are both listed in `.gitignore` to prevent credentials from being committed.

3. **Seed initial admin user** (manual step):
   - Register via the app with any email
   - In Firebase Console → Realtime Database, navigate to `/users/{uid}`
   - Set `"role": "superAdmin"`, `"isApproved": true`, `"isActive": true`
   - This user can then approve other registrations through the app

### Running the Application

**Web**:
```bash
flutter run -d chrome
```

**Android**:
```bash
flutter run -d android
```

**iOS** (macOS only):
```bash
flutter run -d ios
```

**Windows**:
```bash
flutter run -d windows
```

**Linux**:
```bash
flutter run -d linux
```

**macOS**:
```bash
flutter run -d macos
```

### Building for Production

**Web**:
```bash
flutter build web --release
```

**Android APK**:
```bash
flutter build apk --release
```

**Android App Bundle**:
```bash
flutter build appbundle --release
```

**iOS** (macOS only):
```bash
flutter build ios --release
```

**Windows**:
```bash
flutter build windows --release
```

**Linux**:
```bash
flutter build linux --release
```

**macOS**:
```bash
flutter build macos --release
```

---

## Project Structure

```
ambulance-dispatch-management-system/
├── .gitignore
├── LICENSE
├── README.md
├── DESIGN_GUIDELINES.md               # UI/UX design system specification
├── diagrams/                           # System architecture and flow diagrams
├── source/
│   └── flutter/
│       └── adms/                       # Flutter application root
│           ├── .env.example            # Firebase credentials template
│           ├── .gitignore              # Ignores firebase_options.dart, .env, etc.
│           ├── database.rules.json     # Firebase RTDB security rules
│           ├── pubspec.yaml            # Flutter dependencies
│           ├── analysis_options.yaml
│           ├── android/                # Android-specific files
│           ├── ios/                    # iOS-specific files
│           ├── web/                    # Web-specific files
│           ├── windows/                # Windows-specific files
│           ├── linux/                  # Linux-specific files
│           ├── macos/                  # macOS-specific files
│           ├── lib/
│           │   ├── main.dart                           # App entry point (Firebase init)
│           │   ├── firebase_options_template.dart       # Firebase config placeholder
│           │   ├── core/
│           │   │   ├── data/
│           │   │   │   └── repositories/
│           │   │   │       ├── repositories.dart       # Barrel file
│           │   │   │       ├── auth_repository.dart    # Abstract auth interface
│           │   │   │       └── firebase_auth_repository.dart  # Firebase Auth + RTDB impl
│           │   │   ├── models/
│           │   │   │   ├── models.dart                 # Barrel file
│           │   │   │   ├── user_role.dart              # UserRole enum (6 roles)
│           │   │   │   ├── user.dart                   # User model
│           │   │   │   ├── auth_state.dart             # AuthState (authenticated/unauthenticated/etc.)
│           │   │   │   ├── incident.dart               # Incident model + Severity/Status enums
│           │   │   │   ├── ambulance_unit.dart          # AmbulanceUnit + UnitStatus/UnitType enums
│           │   │   │   ├── hospital.dart               # Hospital model with capacity tracking
│           │   │   │   └── municipality.dart           # Municipality model with denormalized stats
│           │   │   ├── router/
│           │   │   │   └── app_router.dart             # GoRouter with role-based routing
│           │   │   ├── services/
│           │   │   │   ├── services.dart               # Barrel file
│           │   │   │   ├── auth_service.dart           # AuthNotifier + auth providers
│           │   │   │   ├── incident_service.dart       # Incident CRUD + real-time streams
│           │   │   │   ├── unit_service.dart           # Ambulance unit management
│           │   │   │   ├── hospital_service.dart       # Hospital capacity management
│           │   │   │   ├── dispatch_service.dart       # Dispatch workflow orchestration
│           │   │   │   ├── municipality_service.dart   # Municipality management
│           │   │   │   └── notification_service.dart   # FCM push notifications
│           │   │   └── theme/
│           │   │       ├── app_theme.dart              # Material 3 light/dark themes
│           │   │       ├── app_colors.dart             # Brand, emergency, unit, role colors
│           │   │       └── app_typography.dart          # Inter, Plus Jakarta Sans, JetBrains Mono
│           │   ├── features/
│           │   │   ├── auth/
│           │   │   │   └── screens/
│           │   │   │       ├── login_screen.dart
│           │   │   │       ├── register_screen.dart
│           │   │   │       ├── verify_email_screen.dart
│           │   │   │       └── forgot_password_screen.dart
│           │   │   ├── citizen/
│           │   │   │   └── screens/
│           │   │   │       └── citizen_dashboard.dart   # Emergency reporting + incident history
│           │   │   ├── dispatcher/
│           │   │   │   └── screens/
│           │   │   │       └── dispatcher_dashboard.dart # Command center with real-time dispatch
│           │   │   ├── driver/
│           │   │   │   └── screens/
│           │   │   │       └── driver_dashboard.dart    # Active assignment + status management
│           │   │   ├── hospital/
│           │   │   │   └── screens/
│           │   │   │       └── hospital_dashboard.dart  # Capacity + incoming patients
│           │   │   ├── municipal_admin/
│           │   │   │   └── screens/
│           │   │   │       └── municipal_admin_dashboard.dart # LGU overview + fleet management
│           │   │   └── super_admin/
│           │   │       └── screens/
│           │   │           └── super_admin_dashboard.dart # System-wide municipalities overview
│           │   └── shared/
│           │       └── widgets/                        # Reusable UI components
│           └── test/
│               ├── widget_test.dart
│               └── models/
│                   ├── incident_test.dart
│                   ├── ambulance_unit_test.dart
│                   ├── hospital_test.dart
│                   └── municipality_test.dart
```

---

## Configuration

### Firebase Credentials

Firebase credentials are managed through two mechanisms:

1. **`firebase_options.dart`** — Auto-generated by `flutterfire configure`. Contains platform-specific Firebase config (API keys, app IDs, project ID). This file is gitignored.

2. **`.env`** — Optional environment overrides. Copy from `.env.example` and fill in your values. This file is gitignored.

### Firebase RTDB Security Rules

The file `database.rules.json` contains role-based security rules for all RTDB nodes:

| Role | Permissions |
|------|-------------|
| **superAdmin** | Read/write all nodes across all municipalities |
| **municipalAdmin** | Read/write within own municipality |
| **dispatcher** | Read/write incidents and units in own municipality |
| **driver** | Read own assignments, write own unit status/location |
| **citizen** | Report incidents, read own incidents |
| **hospitalStaff** | Read incoming patients, write own hospital capacity |

Deploy rules with:
```bash
firebase deploy --only database --project=your-project-id
```

### User Roles

The system uses 6 roles defined in `lib/core/models/user_role.dart`:

| Role | Dashboard | Description |
|------|-----------|-------------|
| `superAdmin` | System-wide overview | Manages all municipalities, approves admins |
| `municipalAdmin` | Municipal operations | Manages fleet, hospitals, personnel for one LGU |
| `dispatcher` | Dispatch command center | Handles emergency calls, dispatches units |
| `driver` | Mobile crew interface | Receives assignments, updates status, GPS tracking |
| `citizen` | Emergency reporting | Reports emergencies, tracks own incidents |
| `hospitalStaff` | Hospital capacity | Manages bed availability, incoming patients |

### Application Settings

Key configuration values are defined in:
- `lib/core/theme/app_colors.dart` — Brand, emergency severity, unit status, and role colors
- `lib/core/theme/app_typography.dart` — Font families and text styles
- `lib/core/router/app_router.dart` — Route definitions and role-based redirect logic

---

## Usage Guide

### For Dispatchers

1. **Receiving a Call**
   - Click "New Incident" button
   - Enter caller information
   - Select incident location on map or enter address
   - Choose emergency type from dropdown
   - System automatically assigns priority

2. **Dispatching a Unit**
   - Review system recommendation for nearest available unit
   - Verify unit capability matches incident requirements
   - Click "Dispatch" to send unit
   - Monitor real-time position on map

3. **Managing Active Incidents**
   - View all active incidents in queue panel
   - Track unit status changes
   - Receive notifications for critical events
   - Monitor response times in real-time

### For Ambulance Crews

1. **Receiving Dispatch**
   - Mobile app notification alerts crew
   - Review incident details
   - Tap "Accept" to acknowledge
   - Use built-in navigation to reach scene

2. **Updating Status**
   - Large status buttons on main screen
   - Tap "Arrived" when on scene
   - Tap "Transporting" when patient loaded
   - Tap "At Hospital" when delivered
   - Tap "Available" when ready for next call

3. **Patient Documentation**
   - Access ePCR form during transport
   - Enter vitals and treatment
   - Complete forms before hospital arrival

### For Administrators

1. **Monitoring Performance**
   - Access KPI dashboard from admin panel
   - Review response time metrics
   - Check unit utilization rates
   - Analyze demand patterns

2. **Managing Fleet**
   - Update unit status (in service / out of service)
   - Schedule maintenance
   - Assign crews to vehicles
   - Configure unit capabilities

3. **Generating Reports**
   - Select date range for analysis
   - Choose metrics to include
   - Export to PDF or CSV
   - Schedule automated report delivery

---

## Data Architecture

### Firebase Realtime Database Paths

The system uses Firebase RTDB instead of a traditional REST API. All data access is through real-time streams via Riverpod `StreamProvider`s.

#### Incidents

**Create Incident** (via `IncidentService.reportIncident()`):
```
Path: /incidents/{municipalityId}/{incidentId}
Also writes: /user_incidents/{reporterId}/{incidentId} (index)
```

**Real-time Active Incidents** (via `municipalityIncidentsProvider`):
```
Path: /incidents/{municipalityId}
Query: orderByChild('status'), filtered client-side for active statuses
```

#### Units

**Watch Available Units** (via `availableUnitsProvider`):
```
Path: /units/{municipalityId}
Query: orderByChild('status'), equalTo('available')
```

**Update Unit Status** (via `UnitService.updateStatus()`):
```
Path: /units/{municipalityId}/{unitId}/status
Also updates: /units/{municipalityId}/{unitId}/lastStatusChangeAt
```

**Update GPS Location** (via `UnitService.updateLocation()`):
```
Path: /units/{municipalityId}/{unitId}
Updates: latitude, longitude, locationUpdatedAt
```

#### Dispatch Workflow

**Dispatch Unit to Incident** (via `DispatchService.dispatchUnit()`):
```
Atomic multi-path update:
  /incidents/{munId}/{incId}/status → "dispatched"
  /incidents/{munId}/{incId}/assignedUnitId → unitId
  /incidents/{munId}/{incId}/assignedDriverId → driverId
  /incidents/{munId}/{incId}/dispatchedAt → timestamp
  /units/{munId}/{unitId}/status → "enRoute"
  /units/{munId}/{unitId}/currentIncidentId → incId
```

#### Hospitals

**Update Capacity** (via `HospitalService.updateCapacity()`):
```
Path: /hospitals/{municipalityId}/{hospitalId}
Updates: totalBeds, availableBeds, emergencyCapacity, lastCapacityUpdateAt
```

#### Service Layer Reference

| Service | File | Key Providers |
|---------|------|---------------|
| Auth | `auth_service.dart` | `authStateProvider`, `currentUserProvider` |
| Incidents | `incident_service.dart` | `municipalityIncidentsProvider`, `myIncidentsProvider` |
| Units | `unit_service.dart` | `municipalityUnitsProvider`, `availableUnitsProvider`, `myUnitProvider` |
| Hospitals | `hospital_service.dart` | `municipalityHospitalsProvider`, `acceptingHospitalsProvider` |
| Dispatch | `dispatch_service.dart` | `dispatchServiceProvider` |
| Municipalities | `municipality_service.dart` | `allMunicipalitiesProvider`, `municipalityProvider` |
| Notifications | `notification_service.dart` | `notificationServiceProvider`, `foregroundMessagesProvider` |

---

## Contributing

We welcome contributions from the community! Whether you're fixing bugs, adding features, improving documentation, or suggesting enhancements, your help is appreciated.

### How to Contribute

1. **Fork the Repository**
   ```bash
   git clone https://github.com/qppd/ambulance-dispatch-management-system.git
   ```

2. **Create a Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make Your Changes**
   - Write clean, documented code
   - Follow existing code style and conventions
   - Add tests for new functionality
   - Update documentation as needed

4. **Test Your Changes**
   ```bash
   flutter test
   flutter analyze
   ```

5. **Commit Your Changes**
   ```bash
   git add .
   git commit -m "Add feature: your feature description"
   ```

6. **Push to Your Fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Submit a Pull Request**
   - Go to the original repository
   - Click "New Pull Request"
   - Describe your changes in detail
   - Reference any related issues

### Coding Standards

- **Dart**: Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- **Flutter**: Adhere to Flutter [style guide](https://docs.flutter.dev/development/tools/formatting)
- **Commits**: Use clear, descriptive commit messages
- **Testing**: Maintain or improve code coverage
- **Documentation**: Update README and inline comments

### Code Review Process

All submissions require review. We use GitHub pull requests for this purpose. Reviewers will check for:
- Code quality and style compliance
- Test coverage
- Documentation completeness
- Performance implications
- Security considerations

---

## Roadmap

Progress is tracked as a simple checklist. Keep the header percentage updated based on checked items.

### Engineering Foundations (50% Complete)
- [x] Choose a single state management approach and document conventions (Riverpod StateNotifier + StreamProvider)
- [x] Define app architecture (feature-first) and update folder structure accordingly
- [x] Implement a consistent error handling strategy (AuthResult pattern, Firebase error mapping, snackbar feedback)
- [ ] Adopt `flutter_lints` (recommended rules) and keep `flutter analyze` clean
- [ ] Standardize formatting (`dart format`) and pre-commit conventions
- [ ] Set up CI to run `flutter analyze` + `flutter test` on pull requests

### UI/UX Foundations (50% Complete)
- [x] Implement Material 3 theme tokens (colors, typography, shapes, elevations)
- [x] Build a responsive layout system (breakpoints + reusable adaptive widgets)
- [ ] Accessibility baseline: contrast ≥ 4.5:1, touch targets ≥ 48x48, screen reader labels
- [ ] Animation system: motion guidelines + reusable transitions (snackbars, dialogs, map markers)

### Firebase Integration (100% Complete)
- [x] Firebase Authentication (email/password + email verification + password reset)
- [x] Firebase RTDB schema design (users, municipalities, incidents, units, hospitals)
- [x] RTDB security rules with role-based access control
- [x] Real-time data services (IncidentService, UnitService, HospitalService, MunicipalityService)
- [x] Dispatch workflow orchestration with atomic multi-path writes
- [x] FCM notification service with topic-based subscriptions
- [x] Auth repository pattern (abstract + Firebase implementation)
- [x] Firebase credentials template + .gitignore protection
- [x] Firebase Analytics event tracking integration
- [x] Offline persistence and connectivity handling

### Core System Features (55% Complete)

**Computer-Aided Dispatch (CAD)**
- [x] Incident intake and logging system
- [x] Dispatcher dashboard interface
- [x] Real-time incident management

**Unit Status Management**
- [x] Ambulance state tracking (Available → En Route → On Scene → At Hospital)
- [x] Real-time status updates
- [ ] Crew and equipment monitoring

**GPS Location Tracking**
- [x] Real-time ambulance positioning
- [ ] Route visualization on maps
- [ ] Location history and playback

**Proximity-Based Dispatching**
- [x] Nearest available unit calculation
- [ ] Route optimization
- [ ] Traffic-aware dispatching

**Mobile Application**
- [x] Crew mobile app for status updates
- [x] One-tap status changes
- [x] Offline capability

**Call Prioritization & Queuing**
- [x] Automated emergency classification (severity-based)
- [x] Priority-based incident queuing
- [x] Multi-incident management

**Demand Forecasting**
- [ ] Historical pattern analysis
- [ ] Peak demand prediction
- [ ] Staffing recommendations

**Geospatial Heatmapping**
- [ ] Incident density visualization
- [ ] Geographic risk analysis
- [ ] Coverage optimization

**System Status Management**
- [ ] Strategic unit positioning
- [ ] Coverage gap alerts
- [ ] Proactive deployment recommendations

**Maintenance Scheduling**
- [x] Service interval tracking
- [x] Automated reminders
- [x] Maintenance history

**Electronic Patient Care Reporting**
- [x] Digital patient documentation
- [x] Treatment logging
- [x] Hospital handover records

**Response Time Analytics**
- [x] Performance metrics calculation
- [ ] Bottleneck identification
- [ ] Trend analysis and reporting

**KPI Dashboards**
- [x] Real-time performance monitoring (per-role dashboards)
- [ ] Executive reporting
- [ ] Compliance tracking

**Post-Incident Logs**
- [x] Complete audit trails (lifecycle timestamps on incidents)
- [ ] Incident replay functionality
- [ ] Historical data analysis

### Quality Gates (0% Complete)
- [ ] Performance checklist (avoid expensive work in `build()`, use `const`, lazy lists/grids, avoid unnecessary opacity/clipping)
- [ ] DevTools profiling checklist (jank, rebuilds, layout passes)
- [ ] Release checklist (accessibility checks + regression tests)

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2026 qppd

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## Acknowledgments

This project was inspired by the dedication of emergency medical service providers worldwide who work tirelessly to save lives every day. Special thanks to:

- Local Government Units (LGUs) in the Philippines for their input on real-world operational requirements
- Emergency Medical Technicians (EMTs) and Paramedics who provided invaluable feedback on field usability
- Dispatchers who shared insights into the challenges of coordinating emergency responses
- The Flutter community for creating an excellent cross-platform framework
- Open-source contributors whose libraries and tools made this project possible

---

## Contact

**Developer**: qppd  
**GitHub**: [@qppd](https://github.com/qppd)  
**Project Repository**: [ambulance-dispatch-management-system](https://github.com/qppd/ambulance-dispatch-management-system)

For questions, suggestions, or collaboration inquiries:
- Open an issue on GitHub
- Submit a pull request
- Check the [Discussions](https://github.com/qppd/ambulance-dispatch-management-system/discussions) section

---

<div align="center">

**Built with ❤️ for emergency medical services providers**

*Making a difference, one dispatch at a time*

</div>