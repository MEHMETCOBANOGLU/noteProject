import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utility/image_copy.dart';

// Resim kopyalama ve seçme aym #resimkopyalamavesecmee,aymm
Future<void> selectAndCopyImageDialog(BuildContext context) async {
  final ImagePicker picker = ImagePicker();
  XFile? selectedImage;

  return showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: const Center(
                child: const Text(
              'Resim Kopyalama',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: Colors.green),
            )),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                    'Kopyalanacak bir görsel bulunamadı. Bir resim seçip kopyalama işlemine devam edebilirsiniz.'),
                const SizedBox(height: 10),
                selectedImage == null
                    ? Container(
                        height: 150,
                        width: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                        ),
                        child: const Center(
                          child: Text('Resim seçilmedi'),
                        ),
                      )
                    : Container(
                        height: 150,
                        width: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Image.file(
                          File(selectedImage!.path),
                          fit: BoxFit.cover,
                        ),
                      ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[50],
                  ),
                  onPressed: () async {
                    final XFile? image =
                        await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setState(() {
                        selectedImage = image;
                      });
                    }
                  },
                  child: const Text('Resim Seç',
                      style: TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            actions: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    child: const Text(
                      'İptal',
                      style: TextStyle(color: Colors.black),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[50],
                    ),
                    child: const Text('Kopyala',
                        style: TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      if (selectedImage != null) {
                        // Resim kopyalama işlemi
                        await copyImageToClipboard(
                            context, selectedImage!.path);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              duration: Duration(seconds: 1),
                              content: Text('Resim panoya kopyalandı!')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              duration: Duration(seconds: 1),
                              content: Text('Resim seçilmedi.')),
                        );
                      }
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ],
          );
        },
      );
    },
  );
}
