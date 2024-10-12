import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Android native kodu ile clipboard'a resmi kopyalama
Future<void> copyImageToClipboard(
    BuildContext context, String imagePath) async {
  const platform = MethodChannel('clipboard_image');

  try {
    final file = File(imagePath);
    print('Copying image at path: $imagePath');

    if (await file.exists()) {
      final result = await platform
          .invokeMethod('copyImageToClipboard', {'path': imagePath});
      print(result);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            duration: Duration(seconds: 1),
            content: Text('Resim panoya kopyalandı!')),
      );
    } else {
      print('File does not exist');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1),
            content: Text('Dosya mevcut değil!')),
      );
    }
  } catch (e) {
    print("Error copying image: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.red,
        duration: Duration(seconds: 1),
        content: Text('Resim kopyalanırken bir hata oluştu.'),
      ),
    );
  }
}
