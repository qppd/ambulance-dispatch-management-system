# Color Scheme & Design Guidelines

## Primary Color Palette

### Emergency Status Colors (Traffic Light System)
```dart
// Critical/Emergency States
const Color criticalRed = Color(0xFFD32F2F);      // Red 700
const Color criticalRedLight = Color(0xFFEF5350); // Red 400
const Color criticalRedDark = Color(0xFFB71C1C);  // Red 900

// Urgent/High Priority States
const Color urgentOrange = Color(0xFFF57C00);     // Orange 700
const Color urgentOrangeLight = Color(0xFFFF9800); // Orange 500
const Color urgentOrangeDark = Color(0xFFE65100); // Orange 900

// Normal/Low Priority States
const Color normalGreen = Color(0xFF388E3C);      // Green 700
const Color normalGreenLight = Color(0xFF4CAF50); // Green 500
const Color normalGreenDark = Color(0xFF1B5E20);  // Green 900

// Information/Standby States
const Color infoBlue = Color(0xFF1976D2);         // Blue 700
const Color infoBlueLight = Color(0xFF2196F3);    // Blue 500
const Color infoBlueDark = Color(0xFF0D47A1);     // Blue 900
```

### Neutral & Background Colors
```dart
// Primary Backgrounds
const Color backgroundPrimary = Color(0xFFFFFFFF);   // White
const Color backgroundSecondary = Color(0xFFFAFAFA); // Gray 50
const Color backgroundTertiary = Color(0xFFF5F5F5);  // Gray 100

// Surface Colors
const Color surfacePrimary = Color(0xFFFFFFFF);     // White
const Color surfaceSecondary = Color(0xFFFFFFFF);   // White (elevated)
const Color surfaceTertiary = Color(0xFFF8F9FA);    // Gray 50

// Text Colors
const Color textPrimary = Color(0xFF212121);        // Gray 900
const Color textSecondary = Color(0xFF757575);      // Gray 600
const Color textTertiary = Color(0xFF9E9E9E);       // Gray 500
const Color textDisabled = Color(0xFFBDBDBD);       // Gray 400

// Border & Divider Colors
const Color borderLight = Color(0xFFE0E0E0);        // Gray 300
const Color borderMedium = Color(0xFFBDBDBD);       // Gray 400
const Color divider = Color(0xFFE0E0E0);            // Gray 300
```

### Unit Status Colors
```dart
// Ambulance Status Indicators
const Color unitAvailable = Color(0xFF4CAF50);      // Green 500
const Color unitEnRoute = Color(0xFF2196F3);        // Blue 500
const Color unitOnScene = Color(0xFFFF9800);        // Orange 500
const Color unitTransporting = Color(0xFF9C27B0);   // Purple 500
const Color unitAtHospital = Color(0xFF607D8B);     // Blue Gray 500
const Color unitUnavailable = Color(0xFF9E9E9E);    // Gray 500
```

## Design Principles

### 1. Emergency Status Hierarchy
- **Red**: Critical emergencies, immediate action required
- **Orange**: Urgent situations, prompt response needed
- **Green**: Normal operations, available resources
- **Blue**: Information, standby, or in-progress states

### 2. Accessibility Compliance
- **WCAG AA Standards**: 4.5:1 contrast ratio minimum
- **Color Blind Friendly**: Use shapes and patterns with colors
- **High Contrast Mode**: Support for users with visual impairments

### 3. Professional Healthcare Appearance
- Clean, clinical aesthetic
- Avoid overly bright or alarming colors in normal states
- Use color sparingly for emphasis, not decoration

### 4. Status Communication
- **Background Colors**: Subtle status indication
- **Text Colors**: High contrast for readability
- **Accent Colors**: Draw attention to critical actions
- **Icon Colors**: Consistent with status meanings

## Implementation Guidelines

### Flutter Theme Configuration
```dart
ThemeData emergencyTheme = ThemeData(
  primaryColor: infoBlue,
  primaryColorLight: infoBlueLight,
  primaryColorDark: infoBlueDark,

  colorScheme: ColorScheme(
    primary: infoBlue,
    primaryContainer: infoBlueLight,
    secondary: urgentOrange,
    secondaryContainer: urgentOrangeLight,
    surface: surfacePrimary,
    background: backgroundPrimary,
    error: criticalRed,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: textPrimary,
    onBackground: textPrimary,
    onError: Colors.white,
    brightness: Brightness.light,
  ),

  // Text Themes
  textTheme: TextTheme(
    headlineLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(color: textPrimary),
    bodyMedium: TextStyle(color: textSecondary),
  ),

  // Component Themes
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: infoBlue,
      foregroundColor: Colors.white,
    ),
  ),

  cardTheme: CardTheme(
    color: surfacePrimary,
    shadowColor: Colors.black.withOpacity(0.1),
    elevation: 2,
  ),
);
```

### Status-Specific Styling
```dart
// Emergency Status Button Styles
ButtonStyle criticalButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: criticalRed,
  foregroundColor: Colors.white,
  elevation: 4,
  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
);

ButtonStyle urgentButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: urgentOrange,
  foregroundColor: Colors.white,
  elevation: 3,
  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
);

ButtonStyle normalButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: normalGreen,
  foregroundColor: Colors.white,
  elevation: 2,
  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
);
```

## Color Usage Guidelines

### Do's ✅
- Use red for critical emergencies and alerts
- Use green for available/ready states
- Use blue for information and in-progress states
- Use orange/yellow for urgent but not critical situations
- Maintain high contrast ratios for text readability
- Test color combinations with color-blind users

### Don'ts ❌
- Don't use red for non-emergency situations
- Don't rely solely on color for critical information
- Don't use bright colors that could cause alarm in normal operations
- Don't use low contrast combinations
- Don't use more than 3-4 colors simultaneously on one screen

## Testing Recommendations

1. **Color Contrast Testing**: Use tools like WebAIM Contrast Checker
2. **Color Blind Simulation**: Test with color-blind friendly tools
3. **User Testing**: Validate with actual emergency responders
4. **Accessibility Audit**: WCAG compliance verification
5. **Cross-Platform Consistency**: Ensure colors render consistently across devices

## Emergency-Specific Considerations

- **Night Mode**: Consider dark theme for night shift workers
- **High Contrast Mode**: Support for visually impaired users
- **Color Coding Standards**: Align with emergency medical service conventions
- **Cultural Considerations**: Ensure colors have appropriate meanings in target regions
- **Battery Conservation**: Use appropriate colors for OLED displays