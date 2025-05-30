import 'package:flutter/material.dart';

class AppTheme {
  // 브랜드 색상
  static const Color primaryRed = Color(0xFFE53935);
  static const Color darkRed = Color(0xFFB71C1C);
  static const Color lightRed = Color(0xFFFF6659);
  
  // 상태별 색상
  static const Color fireColor = Color(0xFFFF6B6B);
  static const Color emergencyColor = Color(0xFF4ECDC4);
  static const Color rescueColor = Color(0xFF95E1D3);
  static const Color otherColor = Color(0xFFA8E6CF);
  static const Color successGreen = Color(0xFF43A047);
  static const Color warningOrange = Color(0xFFFB8C00);
  
  // 회색 스케일
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFEEEEEE);
  static const Color gray300 = Color(0xFFE0E0E0);
  static const Color gray400 = Color(0xFFBDBDBD);
  static const Color gray500 = Color(0xFF9E9E9E);
  static const Color gray600 = Color(0xFF757575);
  static const Color gray700 = Color(0xFF616161);
  static const Color gray800 = Color(0xFF424242);
  static const Color gray900 = Color(0xFF212121);
  
  // Material 3 테마
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    
    // 색상 스키마
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryRed,
      primary: primaryRed,
      secondary: fireColor,
      tertiary: emergencyColor,
      error: darkRed,
      background: gray50,
      surface: Colors.white,
      brightness: Brightness.light,
    ),
    
    // AppBar 테마
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: Colors.white,
      foregroundColor: gray900,
      titleTextStyle: TextStyle(
        color: gray900,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: gray900),
    ),
    
    // Card 테마
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: gray200, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    
    // ElevatedButton 테마
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        disabledBackgroundColor: gray300,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // OutlinedButton 테마
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(color: gray300, width: 1.5),
      ),
    ),
    
    // TextButton 테마
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    
    // Chip 테마
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      labelPadding: EdgeInsets.symmetric(horizontal: 8),
      side: BorderSide(color: gray300),
      backgroundColor: Colors.white,
      selectedColor: primaryRed.withOpacity(0.1),
    ),
    
    // Dialog 테마
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
    ),
    
    // BottomSheet 테마
    bottomSheetTheme: BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      elevation: 16,
      backgroundColor: Colors.white,
    ),
    
    // FloatingActionButton 테마
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      highlightElevation: 8,
      backgroundColor: primaryRed,
      foregroundColor: Colors.white,
    ),
    
    // SnackBar 테마
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 4,
      backgroundColor: gray800,
    ),
    
    // BottomNavigationBar 테마
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      elevation: 0,
      backgroundColor: Colors.white,
      selectedItemColor: primaryRed,
      unselectedItemColor: gray500,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
    
    // NavigationBar 테마 (Material 3)
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      height: 80,
      backgroundColor: Colors.white,
      indicatorColor: primaryRed.withOpacity(0.1),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    
    // ListTile 테마
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
    
    // InputDecoration 테마
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: gray100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: gray300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryRed, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: darkRed),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    
    // 페이지 전환 애니메이션
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
  
  // 재난 타입별 색상 가져오기
  static Color getEventTypeColor(String eventType) {
    switch (eventType) {
      case '화재':
        return fireColor;
      case '구급':
        return emergencyColor;
      case '구조':
        return rescueColor;
      default:
        return otherColor;
    }
  }
  
  // 재난 타입별 아이콘 가져오기
  static IconData getEventTypeIcon(String eventType) {
    switch (eventType) {
      case '화재':
        return Icons.local_fire_department;
      case '구급':
        return Icons.medical_services;
      case '구조':
        return Icons.support;
      default:
        return Icons.warning;
    }
  }
}
