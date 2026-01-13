# Ambulance Dispatch Management System

> A comprehensive Computer-Aided Dispatch (CAD) platform designed to streamline emergency medical response operations for Local Government Units (LGUs) and emergency medical services providers.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.38.6-02569B?logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Web%20%7C%20Android%20%7C%20iOS%20%7C%20Desktop-lightgrey)]()

---

## Table of Contents

- [Overview](#overview)
- [Problem Statement](#problem-statement)
- [Core Objectives](#core-objectives)
- [System Architecture](#system-architecture)
- [Key Features](#key-features)
  - [1. Computer-Aided Dispatch (CAD)](#1-computer-aided-dispatch-cad)
  - [2. Automated Call Prioritization](#2-automated-call-prioritization-triage)
  - [3. Incident Queuing](#3-incident-queuing)
  - [4. Unit Status Management](#4-unit-status-management)
  - [5. Vehicle Location Tracking](#5-vehicle-location-tracking)
  - [6. Proximity-Based Dispatching](#6-proximity-based-dispatching)
  - [7. Demand Pattern Forecasting](#7-demand-pattern-forecasting)
  - [8. Geospatial Heatmapping](#8-geospatial-heatmapping)
  - [9. System Status Management (SSM)](#9-system-status-management-ssm-suggestions)
  - [10. Maintenance Scheduling](#10-maintenance-scheduling)
  - [11. Mobile Application](#11-mobile-application-for-crew)
  - [12. Electronic Patient Care Reporting](#12-electronic-patient-care-reporting-epcr)
  - [13. One-Tap Status Updates](#13-one-tap-status-updates)
  - [14. Response Time Analytics](#14-response-time-analytics)
  - [15. KPI Dashboards](#15-kpi-dashboards)
  - [16. Post-Incident Logs](#16-post-incident-logs)
- [Technology Stack](#technology-stack)
- [Installation](#installation)
- [Project Structure](#project-structure)
- [Configuration](#configuration)
- [Usage Guide](#usage-guide)
- [API Documentation](#api-documentation)
- [Contributing](#contributing)
- [Roadmap](#roadmap)
- [License](#license)
- [Acknowledgments](#acknowledgments)
- [Contact](#contact)

---

## Overview

The Ambulance Dispatch Management System is a mission-critical application that transforms emergency medical response coordination through intelligent automation, real-time monitoring, and data-driven decision-making. Built with modern cross-platform technologies, this system serves as the nerve center for emergency medical operations, ensuring that every second counts when lives are at stake.

This platform bridges the gap between emergency callers, dispatch centers, ambulance crews, and healthcare facilities, creating a seamless flow of information that significantly reduces response times and improves patient outcomes.

---

## Problem Statement

Traditional emergency response systems often suffer from:

- **Manual Dispatching Delays**: Time-consuming radio communications and paper-based logging create bottlenecks during critical moments
- **Inefficient Resource Allocation**: Lack of real-time visibility into unit locations and availability leads to suboptimal dispatching decisions
- **Limited Situational Awareness**: Dispatchers operate with incomplete information about incident severity, unit status, and geographic factors
- **No Performance Metrics**: Absence of data-driven insights prevents continuous improvement and evidence-based decision-making
- **Communication Breakdowns**: Disconnected systems between dispatch, field crews, and hospitals result in information gaps
- **Reactive Operations**: Without predictive capabilities, emergency services are always playing catch-up during peak demand periods

---

## Core Objectives

This system was designed with four fundamental goals in mind:

### 1. Rapid Response Coordination
Minimize the time from emergency call receipt to unit dispatch through automated workflows, intelligent prioritization, and streamlined interfaces that eliminate manual data entry bottlenecks.

### 2. Optimal Resource Deployment
Ensure the right ambulance reaches the right patient at the right time by leveraging real-time location tracking, proximity-based algorithms, and unit capability matching.

### 3. Complete Operational Visibility
Provide dispatchers and administrators with comprehensive, real-time awareness of all system components including unit positions, status changes, incident queues, and resource availability.

### 4. Continuous Service Improvement
Enable evidence-based enhancement of emergency medical services through detailed analytics, performance metrics, demand forecasting, and post-incident analysis that reveal opportunities for optimization.

---

## System Architecture

The system follows a modern, scalable architecture designed for reliability and performance:

```
┌─────────────────────────────────────────────────────────────────┐
│                        Client Layer                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Web App    │  │  Mobile App  │  │ Desktop App  │          │
│  │ (Dispatch)   │  │  (Crew)      │  │ (Admin)      │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                            ↕
┌─────────────────────────────────────────────────────────────────┐
│                      API Gateway Layer                           │
│              REST API / WebSocket / GraphQL                      │
└─────────────────────────────────────────────────────────────────┘
                            ↕
┌─────────────────────────────────────────────────────────────────┐
│                    Application Layer                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  Dispatch    │  │  Analytics   │  │   Routing    │          │
│  │  Engine      │  │  Engine      │  │   Engine     │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                            ↕
┌─────────────────────────────────────────────────────────────────┐
│                       Data Layer                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  PostgreSQL  │  │    Redis     │  │  TimescaleDB │          │
│  │  (Primary)   │  │   (Cache)    │  │ (Time-Series)│          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                            ↕
┌─────────────────────────────────────────────────────────────────┐
│                   External Services                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  Google Maps │  │   Twilio     │  │   SMS Gateway│          │
│  │     API      │  │   (Calls)    │  │              │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

---

## Key Features

### 1. Computer-Aided Dispatch (CAD)

The heart of the system is a sophisticated dispatch console that serves as the command center for all emergency operations. When a call comes in, dispatchers work through a guided workflow that captures critical information efficiently:

**Caller Information Management**
- Automatic caller ID detection and lookup
- Caller history and previous incident records
- Quick contact information validation
- Callback number verification

**Incident Location Handling**
- Address autocomplete with geocoding verification
- Map-based location selection with pin placement
- Landmark and intersection-based location entry
- GPS coordinates from mobile callers
- Location accuracy indicators

**Emergency Classification**
- Medical emergency types (cardiac events, trauma, respiratory distress, etc.)
- Incident severity assessment
- Special situation flags (multiple casualties, hazmat, violent scene)
- Pre-arrival instructions triggered by classification

**Technical Implementation**
This component is built as a central CRUD (Create, Read, Update, Delete) system with real-time synchronization. All workflows originate here, making it the single source of truth for incident data. The interface is optimized for keyboard navigation and rapid data entry, with validation rules that prevent common errors while maintaining speed.

---

### 2. Automated Call Prioritization (Triage)

Not all emergencies are equal. The system automatically classifies incoming calls based on standardized medical dispatch protocols, ensuring that life-threatening situations receive immediate attention while less urgent cases are appropriately queued.

**Priority Levels**

- **Critical (Priority 1)**: Life-threatening conditions requiring immediate response
  - Cardiac arrest
  - Unconscious patient
  - Severe respiratory distress
  - Major trauma with uncontrolled bleeding
  - Stroke symptoms

- **Urgent (Priority 2)**: Serious conditions requiring prompt response
  - Chest pain (conscious)
  - Fractures with complications
  - Severe bleeding (controlled)
  - Allergic reactions

- **Non-Urgent (Priority 3)**: Stable conditions that can tolerate moderate delay
  - Minor injuries
  - Routine transfers
  - Non-emergency medical transport

**Technical Foundation**
The prioritization engine uses a rule-based decision tree aligned with Emergency Medical Dispatch (EMD) standards. Each question asked during call intake feeds into the classification algorithm, which evaluates symptoms, patient demographics, and environmental factors. The system provides real-time priority recommendations to dispatchers while allowing experienced operators to override when clinical judgment dictates.

Future enhancements may incorporate machine learning models trained on historical incident data to refine prioritization accuracy and identify patterns that human operators might miss.

---

### 3. Incident Queuing

During mass casualty incidents or periods of peak demand, the system ensures that no emergency call falls through the cracks. The intelligent queuing system manages multiple simultaneous incidents with fairness and efficiency.

**Queue Management Features**

- **Priority-Based Ordering**: Critical cases automatically move to the front of the queue
- **Wait Time Tracking**: Visual indicators show how long each incident has been pending
- **Queue Position Updates**: Callers can be informed of their position and estimated wait time
- **Auto-Escalation**: Cases that wait beyond threshold times are automatically escalated
- **Dispatcher Workload Balancing**: Incidents are distributed among available dispatchers

**Queue Visibility**
Dispatchers see a dynamic queue view with color-coding for priority levels, age of incidents, and resource constraints. Supervisors can monitor queue depth and initiate surge protocols when wait times exceed acceptable thresholds.

This operates conceptually like a message queue or task queue system, but with healthcare-specific logic that accounts for medical urgency rather than simple first-in-first-out processing.

---

### 4. Unit Status Management

Real-time awareness of every ambulance's operational status is crucial for effective dispatching. The system maintains a comprehensive state machine for each emergency vehicle.

**Unit States**

```
Available → En Route → On Scene → Transporting → At Hospital → Clearing → Available
```

**State Descriptions**

- **Available**: Unit is in service, staffed, and ready for dispatch
- **En Route**: Traveling to the scene of an incident
- **On Scene**: Arrived at incident location, patient care in progress
- **Transporting**: Patient loaded, traveling to hospital
- **At Hospital**: Arrived at medical facility, patient handover in progress
- **Clearing**: Completing paperwork, restocking, preparing to return to service
- **Out of Service**: Unit unavailable due to maintenance, end of shift, or other reasons

**Advanced Status Features**

- **Automatic State Transitions**: GPS triggers certain state changes (e.g., arrival at scene)
- **Status Duration Tracking**: Monitor how long units spend in each state
- **Status History**: Complete audit trail of all state changes
- **Crew Status**: Track individual crew member availability separately from vehicles
- **Equipment Status**: Monitor critical equipment (defibrillators, oxygen, medications)

The state machine logic is critical for dispatching algorithms. Only units in "Available" status can be considered for new incidents. Status transitions generate events that trigger notifications, update dashboards, and log to the audit trail.

---

### 5. Vehicle Location Tracking

GPS tracking transforms dispatching from guesswork into science. Every ambulance equipped with a mobile device or GPS tracker appears on the dispatch map in real-time.

**Tracking Capabilities**

- **Real-Time Position Updates**: Location refresh every 10-30 seconds (configurable)
- **Movement Detection**: System distinguishes between moving and stationary units
- **Heading and Speed**: Directional arrows show which way units are traveling
- **Location History**: Playback capability for post-incident analysis
- **Geofencing**: Alerts when units enter or exit defined areas
- **Coverage Visualization**: Heat map showing geographic coverage by available units

**Map Integration**
The system integrates with major mapping providers (Google Maps, OpenStreetMap, Mapbox) to display:
- Unit positions with custom icons indicating status
- Incident locations with priority markers
- Hospital locations
- Station boundaries
- Traffic conditions
- Route visualization for dispatched units

**Technical Implementation**
Mobile apps on ambulances send GPS coordinates to the backend via WebSocket connections for low-latency updates. The system handles connection interruptions gracefully, buffering location data and synchronizing when connectivity resumes. Location data is stored in a time-series database for historical analysis and playback.

Privacy and security considerations ensure that off-duty personnel are never tracked, and location data access is strictly controlled and audited.

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
- **Framework**: Flutter 3.38.6
- **State Management**: Provider / Riverpod
- **UI Components**: Material Design 3
- **Maps**: Google Maps Flutter Plugin / flutter_map (OpenStreetMap)
- **Charts**: fl_chart / syncfusion_flutter_charts
- **HTTP Client**: dio
- **WebSocket**: web_socket_channel
- **Local Storage**: sqflite / hive
- **Geolocation**: geolocator

### Backend
- **Runtime**: Node.js 20+ / Python 3.11+
- **Framework**: Express.js / FastAPI
- **API**: RESTful API + GraphQL (optional)
- **Real-time**: WebSocket / Socket.io
- **Authentication**: JWT + OAuth 2.0
- **Task Queue**: Bull / Celery

### Database
- **Primary Database**: PostgreSQL 15+ with PostGIS extension
- **Caching Layer**: Redis 7+
- **Time-Series Data**: TimescaleDB
- **Document Store**: MongoDB (for logs and unstructured data)

### Infrastructure
- **Containerization**: Docker
- **Orchestration**: Docker Compose / Kubernetes
- **CI/CD**: GitHub Actions
- **Monitoring**: Prometheus + Grafana
- **Logging**: ELK Stack (Elasticsearch, Logstash, Kibana)
- **Load Balancer**: Nginx

### External Services
- **Maps & Routing**: Google Maps API / OpenStreetMap / Mapbox
- **SMS Notifications**: Twilio / local SMS gateway
- **Voice Services**: Twilio / VoIP provider
- **Cloud Storage**: AWS S3 / Azure Blob Storage
- **Email**: SendGrid / AWS SES

### Development Tools
- **Version Control**: Git
- **Code Quality**: ESLint, Prettier, Dart Analyzer
- **Testing**: Jest, Flutter Test, pytest
- **Documentation**: Swagger/OpenAPI, Compodoc
- **Project Management**: GitHub Projects

---

## Installation

### Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK 3.38.6 or higher** - [Installation Guide](https://docs.flutter.dev/get-started/install)
- **Git 2.40+** - [Download Git](https://git-scm.com/downloads)
- **Visual Studio Code** or **Android Studio** (recommended IDEs)
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

2. **Edit `.env` file with your configuration**:
```
API_BASE_URL=https://your-api-endpoint.com
GOOGLE_MAPS_API_KEY=your_google_maps_key
WS_ENDPOINT=wss://your-websocket-endpoint.com
```

3. **Platform-specific configuration**:

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<meta-data
  android:name="com.google.android.geo.API_KEY"
  android:value="YOUR_GOOGLE_MAPS_KEY"/>
```

**iOS** (`ios/Runner/AppDelegate.swift`):
```swift
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_KEY")
```

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
├── diagrams/                      # System architecture and flow diagrams
├── source/
│   └── flutter/
│       └── adms/                  # Flutter application root
│           ├── android/           # Android-specific files
│           ├── ios/               # iOS-specific files
│           ├── lib/               # Dart source code
│           │   ├── main.dart      # Application entry point
│           │   ├── models/        # Data models
│           │   ├── services/      # Business logic & API clients
│           │   ├── providers/     # State management
│           │   ├── screens/       # UI screens
│           │   ├── widgets/       # Reusable UI components
│           │   └── utils/         # Helper functions
│           ├── linux/             # Linux-specific files
│           ├── macos/             # macOS-specific files
│           ├── web/               # Web-specific files
│           ├── windows/           # Windows-specific files
│           ├── test/              # Unit and widget tests
│           ├── pubspec.yaml       # Flutter dependencies
│           └── analysis_options.yaml
└── docs/                          # Additional documentation
```

---

## Configuration

### Environment Variables

Create a `.env` file in the project root:

```
# API Configuration
API_BASE_URL=https://api.example.com
API_TIMEOUT=30000

# WebSocket Configuration
WS_ENDPOINT=wss://ws.example.com
WS_RECONNECT_DELAY=5000

# Maps Configuration
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
MAP_DEFAULT_ZOOM=12
MAP_DEFAULT_CENTER_LAT=14.5995
MAP_DEFAULT_CENTER_LNG=120.9842

# Geolocation
LOCATION_UPDATE_INTERVAL=15000
LOCATION_ACCURACY=high

# Feature Flags
ENABLE_OFFLINE_MODE=true
ENABLE_EPCR=false
ENABLE_ANALYTICS=true

# Notifications
ENABLE_PUSH_NOTIFICATIONS=true
FCM_SERVER_KEY=your_firebase_key

# Logging
LOG_LEVEL=info
ENABLE_CRASH_REPORTING=true
```

### Application Settings

Modify `lib/config/app_config.dart` to customize:
- Response time thresholds
- Priority level definitions
- Status transition rules
- Unit types and capabilities
- Hospital list

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

## API Documentation

### Base URL
```
https://api.example.com/v1
```

### Authentication
All API requests require a JWT token in the Authorization header:
```
Authorization: Bearer <your_jwt_token>
```

### Endpoints

#### Incidents

**Create Incident**
```
POST /incidents
Content-Type: application/json

{
  "caller_name": "John Doe",
  "caller_phone": "+63123456789",
  "location": {
    "address": "123 Main St, Manila",
    "latitude": 14.5995,
    "longitude": 120.9842
  },
  "emergency_type": "cardiac_arrest",
  "notes": "Patient is unconscious"
}
```

**Get Active Incidents**
```
GET /incidents/active
```

**Update Incident**
```
PATCH /incidents/{incident_id}
Content-Type: application/json

{
  "status": "dispatched",
  "assigned_unit": "AMB-001"
}
```

#### Units

**Get Available Units**
```
GET /units/available
```

**Update Unit Status**
```
PATCH /units/{unit_id}/status
Content-Type: application/json

{
  "status": "en_route",
  "timestamp": "2026-01-13T10:30:00Z"
}
```

**Get Unit Location**
```
GET /units/{unit_id}/location
```

**Update Unit Location**
```
POST /units/{unit_id}/location
Content-Type: application/json

{
  "latitude": 14.5995,
  "longitude": 120.9842,
  "heading": 90,
  "speed": 45.5,
  "timestamp": "2026-01-13T10:30:00Z"
}
```

#### Analytics

**Get Response Time Metrics**
```
GET /analytics/response-times?start_date=2026-01-01&end_date=2026-01-31
```

**Get Demand Forecast**
```
GET /analytics/forecast?days=7
```

**Get Heatmap Data**
```
GET /analytics/heatmap?incident_type=all&period=30d
```

For complete API documentation, visit `/api/docs` (Swagger UI) when running the backend server.

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

### Core System Features (0% Complete)

**Computer-Aided Dispatch (CAD)**
- [ ] Incident intake and logging system
- [ ] Dispatcher dashboard interface
- [ ] Real-time incident management

**Unit Status Management**
- [ ] Ambulance state tracking (Available → En Route → On Scene → At Hospital)
- [ ] Real-time status updates
- [ ] Crew and equipment monitoring

**GPS Location Tracking**
- [ ] Real-time ambulance positioning
- [ ] Route visualization on maps
- [ ] Location history and playback

**Proximity-Based Dispatching**
- [ ] Nearest available unit calculation
- [ ] Route optimization
- [ ] Traffic-aware dispatching

**Mobile Application**
- [ ] Crew mobile app for status updates
- [ ] One-tap status changes
- [ ] Offline capability

**Call Prioritization & Queuing**
- [ ] Automated emergency classification
- [ ] Priority-based incident queuing
- [ ] Multi-incident management

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
- [ ] Service interval tracking
- [ ] Automated reminders
- [ ] Maintenance history

**Electronic Patient Care Reporting**
- [ ] Digital patient documentation
- [ ] Treatment logging
- [ ] Hospital handover records

**Response Time Analytics**
- [ ] Performance metrics calculation
- [ ] Bottleneck identification
- [ ] Trend analysis and reporting

**KPI Dashboards**
- [ ] Real-time performance monitoring
- [ ] Executive reporting
- [ ] Compliance tracking

**Post-Incident Logs**
- [ ] Complete audit trails
- [ ] Incident replay functionality
- [ ] Historical data analysis

### Future Enhancements (Not in Current Scope)
- Hospital system integration (HL7/FHIR)
- Advanced AI features
- Multi-agency coordination
- Public incident mapping
- Predictive maintenance algorithms

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

## Project Status

**Current Version**: 0.0.1-pre-alpha  
**Status**: Initial Setup  
**Last Updated**: January 13, 2026

This project is in its initial development phase. The Flutter project structure has been created and basic documentation is in place. All major features are planned for implementation starting from the core CAD system. Early contributors and collaborators are welcome to join the development process.

---

<div align="center">

**Built with ❤️ for emergency medical services providers**

*Making a difference, one dispatch at a time*

</div>