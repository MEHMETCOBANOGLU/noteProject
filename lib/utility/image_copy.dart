import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> copyImageToClipboard(
    BuildContext context, String imagePath) async {
  const platform = MethodChannel('clipboard_image');

  try {
    final file = File(imagePath);
    if (await file.exists()) {
      // Android native kodu ile clipboard'a resmi kopyala
      final result = await platform
          .invokeMethod('copyImageToClipboard', {'path': imagePath});
      print(result); // Başarı mesajı dönerse burada kontrol edilir

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resim panoya kopyalandı!')),
      );
    } else {
      print('File does not exist');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dosya mevcut değil!')),
      );
    }
  } catch (e) {
    print("Error copying image: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Resim kopyalanırken hata oluştu: $e')),
    );
  }
}
