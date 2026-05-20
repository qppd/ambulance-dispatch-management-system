# Overview

## Project Purpose

The **Ambulance Dispatch Management System (ADMS)** is a real‑time emergency response platform built for Local Government Units (LGUs) in the Philippines. It digitises the entire ambulance dispatch workflow — from the moment a citizen reports an emergency through to patient handover at a hospital.

## System Goals

1. **Reduce Response Times** — Enable dispatchers to find and assign the nearest available unit instantly. Auto‑dispatch uses Haversine distance calculations to suggest the closest unit.
2. **Real‑Time Visibility** — All stakeholders (citizens, dispatchers, drivers, admin) see live status of every incident and unit.
3. **Accountability & Audit** — Every status change, role change, and critical action is logged with timestamps and actor identity.
4. **Data‑Driven Improvement** — Response time analytics provide P90 metrics and compliance rates (8‑minute urban, 15‑minute rural targets).
5. **Offline Resilience** — Firebase RTDB persistence ensures queued writes survive disconnection and sync automatically on reconnection.

## Who It Serves

| Stakeholder | How They Use ADMS |
|-------------|-------------------|
| **Citizens** | Report emergencies via mobile app, track assigned unit arrival in real time |
| **Dispatchers / Municipal Admin** | Manage incoming incidents, dispatch units, monitor fleet status |
| **Ambulance Crew / Drivers** | Receive dispatch alerts, update mission status, complete ePCR |
| **Super Admin** | Configure system settings, manage municipalities, audit logs, analyse system‑wide metrics |
| **Hospital Staff** | Receive patient handover information (future integration) |

## Technology Stack

| Component | Technology |
|-----------|------------|
| **Frontend** | Flutter 3.x (Android, iOS, Web) |
| **State Management** | Riverpod 3.x (Notifier, StreamProvider, FutureProvider) |
| **Backend** | Firebase Realtime Database, Firebase Authentication |
| **Cloud Functions** | Firebase Cloud Functions v2 (Node 20) |
| **Maps** | flutter_map with OpenStreetMap tiles |
| **Notifications** | Firebase Cloud Messaging (topic‑based) |
| **Analytics** | Firebase Analytics, custom response time engine |
| **Export** | PDF (pdf/widgets), CSV (csv package) |
| **API Pattern** | Flutter SDK ⇄ Firebase SDK (no custom REST layer) |

## Key Design Decisions

- **Firebase RTDB over Firestore**: RTDB's real‑time subscription model maps directly to the incident lifecycle. Every status change pushes instantly to all connected clients without polling.
- **Single Codebase**: Flutter with platform‑adaptive widgets serves citizens (mobile), drivers (mobile), and admins (web) from one project.
- **Serverless Dispatch**: Cloud Functions handle auto‑dispatch atomically using Firebase transactions, preventing double‑assignment of units.
- **Offline‑First**: Firebase RTDB persistence is enabled at startup (10 MB cache), so field crews in low‑connectivity areas can still update incident status.
- **Role Consolidation**: The `dispatcher` role was merged into `municipalAdmin` — all dispatch capabilities are now available to municipal administrators, reducing role complexity.