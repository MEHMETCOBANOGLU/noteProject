import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:Tablify/const/colors.dart';
import 'package:Tablify/data/database.dart';
import 'package:Tablify/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SQLite Veritabanını Başlatıyoruz
  final SQLiteDatasource db = SQLiteDatasource();
  await db.init(); // Veritabanını başlatıyoruz

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: ThemeData(
        appBarTheme: const AppBarTheme(color: AppColors.backgroundColor),
        primaryColor: AppColors.backgroundColor,
        hintColor: AppColors.accentColor,
        scaffoldBackgroundColor: AppColors.opaqueBackgroundColor,
        textTheme: const TextTheme(
            // bodyLarge: TextStyle(color: AppColors.textColorPrimary),
            // bodyMedium: TextStyle(color: AppColors.textColorSecondary),
            ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: AppColors.accentColor,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.accentColor),
          ),
        ),
        textSelectionTheme:
            const TextSelectionThemeData(cursorColor: AppColors.accentColor),
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
      ),
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      home: const HomePage(),
    );
  }
}
