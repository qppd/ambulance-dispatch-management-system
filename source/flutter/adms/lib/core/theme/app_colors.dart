import 'package:flutter/material.dart';

/// ADMS Color System
/// Modern, accessible color palette for emergency medical services
class AppColors {
  AppColors._();

  // ============================================
  // PRIMARY BRAND COLORS
  // ============================================
  
  /// Primary brand color - Deep blue for trust & professionalism
  static const Color primary = Color(0xFF1E3A5F);
  static const Color primaryLight = Color(0xFF2E5077);
  static const Color primaryDark = Color(0xFF152A45);
  
  /// Secondary accent - Teal for medical/health association
  static const Color secondary = Color(0xFF00A896);
  static const Color secondaryLight = Color(0xFF02C4B0);
  static const Color secondaryDark = Color(0xFF008C7D);

  // ============================================
  // EMERGENCY STATUS COLORS
  // ============================================
  
  /// Critical - Life threatening (Priority 1)
  static const Color critical = Color(0xFFDC2626);
  static const Color criticalLight = Color(0xFFFEE2E2);
  static const Color criticalDark = Color(0xFFB91C1C);
  
  /// Urgent - Serious condition (Priority 2)
  static const Color urgent = Color(0xFFF59E0B);
  static const Color urgentLight = Color(0xFFFEF3C7);
  static const Color urgentDark = Color(0xFFD97706);
  
  /// Normal - Non-urgent (Priority 3)
  static const Color normal = Color(0xFF10B981);
  static const Color normalLight = Color(0xFFD1FAE5);
  static const Color normalDark = Color(0xFF059669);

  // ============================================
  // UNIT STATUS COLORS
  // ============================================
  
  /// Available - Ready for dispatch
  static const Color available = Color(0xFF22C55E);
  
  /// En Route - Traveling to scene
  static const Color enRoute = Color(0xFF3B82F6);
  
  /// On Scene - At incident location
  static const Color onScene = Color(0xFFF97316);
  
  /// Transporting - Moving patient
  static const Color transporting = Color(0xFF8B5CF6);
  
  /// At Hospital - Patient handover
  static const Color atHospital = Color(0xFF06B6D4);
  
  /// Out of Service - Unavailable
  static const Color outOfService = Color(0xFF6B7280);

  // ============================================
  // NEUTRAL COLORS
  // ============================================
  
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  
  /// Background colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0F172A);
  
  /// Surface colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E293B);
  
  /// Card colors
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF334155);
  
  /// Border colors
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF475569);
  
  /// Text colors
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  /// Dark mode text
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);
  static const Color textMutedDark = Color(0xFF94A3B8);

  // ============================================
  // USER ROLE COLORS
  // ============================================
  
  /// Super Admin - Purple (power/control)
  static const Color superAdmin = Color(0xFF7C3AED);
  
  /// Municipal Admin - Blue (authority/trust)
  static const Color municipalAdmin = Color(0xFF2563EB);
  
  /// Dispatcher - Teal (communication/coordination)
  static const Color dispatcher = Color(0xFF0891B2);
  
  /// Driver/Crew - Orange (action/energy)
  static const Color driver = Color(0xFFEA580C);
  
  /// Citizen - Green (community/safety)
  static const Color citizen = Color(0xFF16A34A);
  
  /// Hospital Staff - Pink (care/medical)
  static const Color hospitalStaff = Color(0xFFDB2777);

  // ============================================
  // GRADIENTS
  // ============================================
  
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryLight],
  );
  
  static const LinearGradient emergencyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [critical, urgent],
  );
  
  static const LinearGradient authGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1E3A5F),
      Color(0xFF0F172A),
    ],
  );
}
