import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:proje1/const/colors.dart';
import 'package:proje1/data/database.dart';
import 'package:proje1/pages/home_page.dart';

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
        appBarTheme: const AppBarTheme(color: AppColors.primaryColor),
        primaryColor: AppColors.primaryColor,
        hintColor: AppColors.accentColor,
        scaffoldBackgroundColor: AppColors.backgroundColor,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textColorPrimary),
          bodyMedium: TextStyle(color: AppColors.textColorSecondary),
        ),
      ),
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      home: const HomePage(),
    );
  }
}
