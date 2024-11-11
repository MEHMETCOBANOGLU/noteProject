import 'package:flutter/material.dart';

class AppTheme extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.light;

  ThemeData get theme => themeMode == ThemeMode.light ? lightTheme : darkTheme;

  void toggleTheme() {
    themeMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  static ThemeData get lightTheme => ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: Color.fromARGB(255, 251, 252, 250),
        appBarTheme:
            const AppBarTheme(color: Color.fromARGB(255, 232, 245, 233)),
        primaryColor: Color.fromARGB(255, 232, 245, 233),
        hintColor: Colors.brown,
        textTheme: const TextTheme(
            // bodyLarge: TextStyle(color: AppColors.textColorPrimary),
            // bodyMedium: TextStyle(color: AppColors.textColorSecondary),
            ),
        // colorScheme: ColorScheme.fromSwatch().copyWith(
        //   primary: Colors.brown,
        // ),
        inputDecorationTheme: const InputDecorationTheme(
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.brown),
          ),
        ),
        textSelectionTheme:
            const TextSelectionThemeData(cursorColor: Colors.brown),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          elevation: 2,
          showCloseIcon: true,
          closeIconColor: Colors.white,
          contentTextStyle: TextStyle(
            color: Colors.white, // Yazı rengi
          ),
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Colors.brown,
        ),
        // iconButtonTheme: IconButtonThemeData(
        //   style: IconButton.styleFrom(
        //     foregroundColor: const Color(0xFF42B4CA),
        //   ),
        // ),
      );

  static ThemeData get darkTheme => ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFF414A4C),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF97C3E9),
          secondary: Color(0xFF778899),
          surface: Color(0xFF414A4C),
          onSurface: Colors.white,
          error: Color(0xFF414A4C),
          tertiary: Color(0xFFB5C4C7),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: const Color(0xFF97C3E9),
          ),
        ),
      );
}
