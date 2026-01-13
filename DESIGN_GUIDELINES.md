# UI/UX Design Guidelines

## Layout Patterns & User Interface Design

### 1. Dispatcher Dashboard Layout

#### Primary Layout Structure
```
┌─────────────────────────────────────────────────────────────┐
│ HEADER: Emergency Status Bar + User Info + Quick Actions    │
├─────────────────┬───────────────────────────────────────────┤
│ NAVIGATION      │ MAIN CONTENT AREA                          │
│ SIDEBAR         │                                           │
│ • Active        │ ┌─────────────────────────────────────┐   │
│   Incidents     │ │ MAP VIEW (60% height)              │   │
│ • Unit Status   │ │ • Real-time ambulance positions     │   │
│ • Queue         │ │ • Incident markers                  │   │
│ • Analytics     │ │ • Coverage zones                    │   │
│                 │ └─────────────────────────────────────┘   │
├─────────────────┼───────────────────────────────────────────┤
│                 │ ┌─────────────────────────────────────┐   │
│                 │ │ INCIDENT DETAILS PANEL (40% height) │   │
│                 │ │ • Current incident info             │   │
│                 │ │ • Quick dispatch actions            │   │
│                 │ │ • Status updates                    │   │
│                 │ └─────────────────────────────────────┘   │
└─────────────────┴───────────────────────────────────────────┘
```

#### Key Components
- **Emergency Status Bar**: Always visible critical alerts
- **Collapsible Navigation**: Space-efficient sidebar
- **Map-Centric Design**: Primary focus on geographical awareness
- **Contextual Panels**: Slide-in panels for detailed information
- **Quick Action Buttons**: Large, accessible emergency controls

### 2. Mobile App Layout (Crew Interface)

#### Ambulance Crew Interface
```
┌─────────────────────────────────────┐
│ STATUS HEADER (Always Visible)      │
│ 🚨 EN ROUTE TO: 123 Main St         │
├─────────────────────────────────────┤
│ MAIN ACTION AREA                    │
│ ┌─────────────────────────────────┐ │
│ │   ARRIVED AT SCENE             │ │
│ │   [LARGE GREEN BUTTON]         │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │   PATIENT LOADED               │ │
│ │   [LARGE BLUE BUTTON]          │ │
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│ NAVIGATION & QUICK ACTIONS          │
│ 🏥 Hospital  📍 Location  📞 Call   │
└─────────────────────────────────────┘
```

#### Key Mobile Principles
- **One-Handed Operation**: Thumb-friendly button placement
- **Large Touch Targets**: Minimum 48x48dp for emergency buttons
- **Status Always Visible**: Critical information never scrolls away
- **Offline Capability**: Graceful degradation when network is poor
- **Voice Commands**: Integration with device voice assistants

### 3. Responsive Breakpoints

#### Desktop (≥1200px)
- Full dashboard layout
- Multi-panel view
- Advanced analytics visible
- Keyboard shortcuts enabled

#### Tablet (768px - 1199px)
- Condensed sidebar navigation
- Stacked panels (map above details)
- Touch-optimized controls
- Simplified analytics

#### Mobile (≤767px)
- Single-column layout
- Bottom navigation
- Swipe gestures for navigation
- Essential information only

### 4. Navigation Patterns

#### Primary Navigation (Dispatcher)
```dart
// Bottom Tab Navigation for Mobile
enum DispatcherTabs {
  incidents('Active Incidents', Icons.emergency),
  units('Unit Status', Icons.local_shipping),
  map('Live Map', Icons.map),
  analytics('Analytics', Icons.analytics),
  profile('Profile', Icons.person);
}
```

#### Emergency Quick Actions
```dart
// Floating Action Button Menu
enum EmergencyActions {
  newIncident('New Incident', Icons.add, criticalRed),
  emergencyBroadcast('Emergency Broadcast', Icons.campaign, urgentOrange),
  massCasualty('Mass Casualty Protocol', Icons.warning, criticalRed);
}
```

#### Contextual Navigation
- **Breadcrumb Navigation**: For nested incident details
- **Back Navigation**: Always available, never hidden
- **Deep Linking**: Direct links to specific incidents/units
- **Search Navigation**: Global search with filters

### 5. Component Design System

#### Emergency Status Cards
```dart
class EmergencyCard extends StatelessWidget {
  final IncidentPriority priority;
  final String title;
  final String location;
  final Duration age;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: priority == IncidentPriority.critical ? 8 : 2,
      color: _getBackgroundColor(priority),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Priority indicator
            Row(children: [
              Icon(_getPriorityIcon(priority), color: _getPriorityColor(priority)),
              SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
            ]),
            SizedBox(height: 8),
            // Location with map pin
            Row(children: [
              Icon(Icons.location_on, size: 16),
              SizedBox(width: 4),
              Text(location),
            ]),
            // Time since incident
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                '${age.inMinutes}m ago',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### Status Timeline Component
```dart
class StatusTimeline extends StatelessWidget {
  final List<StatusUpdate> updates;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: updates.length,
      itemBuilder: (context, index) {
        final update = updates[index];
        return TimelineTile(
          alignment: TimelineAlign.manual,
          lineXY: 0.1,
          isFirst: index == 0,
          isLast: index == updates.length - 1,
          indicatorStyle: IndicatorStyle(
            width: 20,
            color: _getStatusColor(update.status),
            iconStyle: IconStyle(
              color: Colors.white,
              iconData: _getStatusIcon(update.status),
            ),
          ),
          endChild: Container(
            margin: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(update.status.displayName,
                     style: TextStyle(fontWeight: FontWeight.bold)),
                Text(update.timestamp.toString(),
                     style: TextStyle(color: Colors.grey[600])),
                if (update.notes != null) Text(update.notes!),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

### 6. Animation & Micro-Interactions

#### Emergency Alert Animation
```dart
class EmergencyAlert extends StatefulWidget {
  @override
  _EmergencyAlertState createState() => _EmergencyAlertState();
}

class _EmergencyAlertState extends State<EmergencyAlert>
    with TickerProviderStateMixin {

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: criticalRed,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: criticalRed.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'CRITICAL EMERGENCY',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

#### Status Transition Animation
```dart
class StatusTransition extends StatelessWidget {
  final UnitStatus oldStatus;
  final UnitStatus newStatus;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(
        begin: _getStatusColor(oldStatus),
        end: _getStatusColor(newStatus),
      ),
      duration: Duration(milliseconds: 500),
      builder: (context, color, child) {
        return AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child: Container(
            key: ValueKey(newStatus),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              newStatus.displayName,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}
```

### 7. Information Architecture

#### Content Hierarchy
1. **Critical Information** (Largest, highest contrast)
   - Active emergency alerts
   - Unit status changes
   - Critical incident details

2. **Important Information** (Medium emphasis)
   - Incident queue
   - Unit locations
   - Response times

3. **Supporting Information** (Lower emphasis)
   - Historical data
   - Analytics
   - Administrative functions

#### Progressive Disclosure
- **Initial View**: Essential information only
- **On Demand**: Detailed information via expansion/click
- **Contextual**: Show relevant information based on current task
- **Layered**: Use modals, sidebars, and overlays for additional details

### 8. Error Prevention & Safety

#### Confirmation Patterns
```dart
// Critical Action Confirmation
Future<bool> confirmCriticalAction(
  BuildContext context,
  String title,
  String message,
) async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false, // Prevent accidental dismissal
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: criticalRed,
          ),
          child: Text('Confirm'),
        ),
      ],
    ),
  ) ?? false;
}
```

#### Undo Functionality
- **Recent Actions**: Quick undo for last 5 actions
- **Time Window**: 30-second undo window for critical changes
- **Visual Feedback**: Clear indication of reversible actions

### 9. Accessibility Features

#### Screen Reader Support
```dart
class AccessibleEmergencyButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IncidentPriority priority;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Emergency action: $label',
      hint: 'Double tap to ${label.toLowerCase()}',
      button: true,
      enabled: true,
      child: ElevatedButton(
        onPressed: () {
          // Haptic feedback for accessibility
          HapticFeedback.vibrate();
          onPressed();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _getPriorityColor(priority),
          minimumSize: Size(200, 60), // Large touch target
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
```

#### High Contrast Mode
- **Automatic Detection**: System preference detection
- **Manual Toggle**: User-controlled high contrast mode
- **Enhanced Borders**: Thicker borders in high contrast mode
- **Color Overrides**: High contrast color schemes

### 10. Performance Considerations

#### Loading States
```dart
class EmergencyDataLoader extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
    return child;
  }
}
```

#### Progressive Loading
- **Skeleton Screens**: Show layout structure while loading
- **Prioritized Content**: Load critical information first
- **Background Updates**: Refresh non-critical data in background
- **Offline Indicators**: Clear indication of offline capabilities

### 11. Emergency-Specific UX Patterns

#### Crisis Mode Interface
- **Simplified Layout**: Remove non-essential elements during crises
- **Priority Filtering**: Show only critical incidents
- **Mass Casualty Protocol**: Specialized interface for multi-victim incidents
- **Communication Shortcuts**: Quick access to emergency contacts

#### Fatigue Prevention
- **Break Reminders**: Automatic break suggestions for long shifts
- **Alert Rotation**: Different alert sounds to prevent desensitization
- **Visual Rest**: Dark mode options for night shifts
- **Ergonomic Layout**: Optimized for prolonged use

#### Multi-User Coordination
- **Role-Based Views**: Different interfaces for dispatchers, paramedics, administrators
- **Communication Threads**: Integrated chat for incident coordination
- **Handover Protocols**: Structured information transfer between shifts
- **Audit Trails**: Complete record of all user actions and decisions

### 12. Flutter Best Practices (Implementation Checklist)

Use this section as a “definition of done” for UI work. It translates Flutter/Dart best practices into team rules.

#### Performance & Rendering
- **Keep `build()` cheap**: Do not do parsing, I/O, or heavy computation inside `build()`.
- **Prefer `const` widgets**: Use `const` constructors wherever possible to reduce rebuild cost.
- **Split widgets aggressively**: Smaller widgets rebuild less; localize rebuilds to the smallest subtree.
- **Use lazy lists/grids**: Prefer `ListView.builder` / `GridView.builder` for long collections.
- **Avoid expensive effects**: Be careful with heavy opacity/clipping/blur (often triggers `saveLayer`).
- **Avoid intrinsic layout passes**: Minimize use of widgets that require intrinsic measurements.

#### State Management & Architecture
- **One chosen approach**: Use a single state management pattern across the app (document the conventions).
- **UI state vs domain state**: Keep ephemeral UI state local; keep shared app state in a dedicated layer.
- **Unidirectional data flow**: Events → state update → UI render (avoid hidden side effects in widgets).

#### Accessibility (Non-Negotiables)
- **Touch targets**: Minimum 48x48 logical pixels for tappable controls.
- **Contrast**: Text contrast at least 4.5:1 for normal text where feasible.
- **Screen reader support**: Provide semantics/labels for icons and custom controls.
- **Avoid surprise context switches**: Do not navigate/focus-jump while the user is typing.
- **Undo for destructive actions**: Provide confirm/undo paths for critical operations.

#### Motion & Feedback
- **Purposeful motion**: Animate only to clarify cause/effect or preserve context.
- **Respect reduced motion**: Provide a reduced-motion option and avoid mandatory long animations.
- **Keep transitions short**: Favor ~150–300ms for UI transitions; avoid slowing critical flows.

This UI/UX design system ensures that the Ambulance Dispatch Management System is not only functional but also intuitive, safe, and efficient for emergency medical operations.