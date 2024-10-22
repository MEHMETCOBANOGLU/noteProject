import 'package:flutter/material.dart';

class AppColors {
  // Ana Renkler (Yeşil ve uyumlu renkler)
  static const Color backgroundColor =
      Color.fromARGB(255, 232, 245, 233); // green[50]
  static const Color secondaryColor = Colors.green;
  static const Color accentColor = Colors.brown;

  // Arka Plan Renkleri
  static const Color opaqueBackgroundColor =
      Color.fromARGB(255, 251, 252, 250); // Çok açık yeşil arka plan

  static const Color cardBackgroundColor =
      Color(0xFFFFFFFF); // Kart arka planı beyaz
  static const Color darkBackgroundColor =
      Color(0xFF388E3C); // Koyu yeşil arka plan

  // Metin Renkleri
  static const Color textColorPrimary =
      Color(0xFF2E7D32); // Koyu yeşil metin rengi
  static const Color textColorSecondary =
      Color(0xFF616161); // Gri ikincil metin rengi
  static const Color textColorOnAccent =
      Color(0xFF212121); // Vurgulu renkler üzerindeki metin için koyu renk

  // Diğer Renkler (Yeşil ile uyumlu tamamlayıcı renkler)
  static const Color successColor = Color(0xFF4CAF50); // Başarı yeşili
  static const Color errorColor = Color(0xFFD32F2F); // Hata için kırmızı
  static const Color warningColor = Color(0xFFFF9800); // Uyarı için turuncu
  static const Color infoColor = Color(0xFF03A9F4);
}
