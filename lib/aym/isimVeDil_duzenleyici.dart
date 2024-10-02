import 'package:flutter/material.dart';
import 'package:proje1/data/database.dart';
import 'package:proje1/model/items.dart';

// handleTapOnText fonksiyonu
Future<void> handleTapOnText(BuildContext context, String text, int index,
    Item item, Function() onTableEdited) async {
  final RegExp languagePattern = RegExp(r'\[Dil:(.*?)\]');
  final RegExp namePattern = RegExp(r'\[İsim:(.*?)\]');

  final RegExpMatch? languageMatch = languagePattern.firstMatch(text);
  final RegExpMatch? nameMatch = namePattern.firstMatch(text);

  String currentDil = languageMatch?.group(1) ?? '';
  String currentName = nameMatch?.group(1) ?? '';
  if (languageMatch != null || nameMatch != null) {
    if (index != -1) {
      // Dialog'u açıyoruz ve dili ve ismi güncelliyoruz
      await showNameLangEditDialog(context, currentDil, currentName,
          (updatedText) async {
        // setState(() {
        item.expandedValue[index] = updatedText;
        // });

        // Veritabanı güncellemesi
        await SQLiteDatasource().updateNote(
          item.id,
          item.headerValue,
          item.subtitle ?? '',
          item.expandedValue,
          item.imageUrls ?? [],
        );

        onTableEdited(); // UI güncellemesi
      }, item, index);
    }
  } else {}
}

// Dialog fonksiyonu
Future<void> showNameLangEditDialog(
    BuildContext context,
    String currentDil,
    String currentName,
    Function(String) onUpdated,
    Item item,
    int index) async {
  String text = item.expandedValue[index];
  TextEditingController dilController = TextEditingController(text: currentDil);
  TextEditingController isimController =
      TextEditingController(text: currentName);

  return showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final RegExp languagePattern = RegExp(r'\[Dil:(.*?)\]');
          final RegExp namePattern = RegExp(r'\[İsim:(.*?)\]');

          final RegExpMatch? dilMatch = languagePattern.firstMatch(text);
          final RegExpMatch? isimMatch = namePattern.firstMatch(text);

          String beforeDil = '';
          String afterDil = '';
          String betweenDilAndIsim = '';
          String afterIsim = '';

          if (dilMatch != null) {
            beforeDil = text.substring(0, dilMatch.start);
            afterDil = text.substring(dilMatch.end);
          }

          if (isimMatch != null) {
            if (dilMatch != null && isimMatch.start > dilMatch.end) {
              betweenDilAndIsim =
                  afterDil.substring(0, isimMatch.start - dilMatch.end);
              afterIsim = afterDil.substring(isimMatch.end - dilMatch.end);
            } else {
              beforeDil = text.substring(0, isimMatch.start);
              afterIsim = text.substring(isimMatch.end);
            }
          }

          String updatedText = text;
          if (dilMatch != null && isimMatch != null) {
            // Hem dil hem isim varsa her ikisini de güncelliyoruz
            updatedText = text
                .replaceFirst(
                    '[Dil:${dilMatch.group(1)}]', '[Dil:${dilController.text}]')
                .replaceFirst('[İsim:${isimMatch.group(1)}]',
                    '[İsim:${isimController.text}]');
          } else if (dilMatch != null) {
            // Sadece dil varsa
            updatedText = "$beforeDil[Dil:${dilController.text}]$afterDil";
          } else if (isimMatch != null) {
            // Sadece isim varsa
            updatedText = "$beforeDil[İsim:${isimController.text}]$afterIsim";
          }

          return AlertDialog(
            title: const Center(
                child: Text(
              "Değişken Düzenleme",
              style:
                  TextStyle(fontStyle: FontStyle.italic, color: Colors.green),
            )),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(updatedText, style: TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                if (dilMatch != null)
                  Column(
                    children: [
                      Text("Dili Güncelle:",
                          style: TextStyle(
                              fontSize: 16, color: Colors.green[400])),
                      TextField(
                        controller: dilController,
                        decoration: const InputDecoration(
                            hintText: "Yeni dili giriniz"),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
                if (isimMatch != null)
                  Column(
                    children: [
                      Text("İsim Güncelle:",
                          style: TextStyle(
                              fontSize: 16, color: Colors.green[300])),
                      TextField(
                        controller: isimController,
                        decoration: const InputDecoration(
                            hintText: "Yeni ismi giriniz"),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ],
                  ),
              ],
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("İptal",
                        style: TextStyle(
                          color: Colors.black,
                        )),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[50],
                    ),
                    child: const Text(
                      "Kaydet",
                      style: TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      // [Dil:] ve [İsim:] kısımlarını güncelledikten sonra yeni metni birleştiriyoruz
                      String finalText = text;

                      if (dilMatch != null && isimMatch != null) {
                        // [Dil:] ve [İsim:] kısımlarını dilController.text ve isimController.text ile güncelliyoruz.
                        finalText = text
                            .replaceFirst('[Dil:${dilMatch.group(1)}]',
                                '[Dil:${dilController.text}]')
                            .replaceFirst('[İsim:${isimMatch.group(1)}]',
                                '[İsim:${isimController.text}]');
                      } else {
                        // Sadece [Dil:] varsa
                        if (dilMatch != null) {
                          finalText =
                              "$beforeDil[Dil:${dilController.text}]$afterDil";
                        }

                        // Sadece [İsim:] varsa
                        if (isimMatch != null) {
                          finalText =
                              "$beforeDil[İsim:${isimController.text}]$afterIsim";
                        }
                      }

                      // Güncellenmiş metni geri döndürüyoruz
                      onUpdated(finalText);
                      Navigator.of(context).pop(); // Dialog'u kapatıyoruz
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

// Display text function: Displays only name and language info
String getDisplayText(String text) {
  final RegExp languagePattern = RegExp(r'\[Dil:(.*?)\]');
  final RegExp namePattern = RegExp(r'\[İsim:(.*?)\]');

  final RegExpMatch? languageMatch = languagePattern.firstMatch(text);
  final RegExpMatch? nameMatch = namePattern.firstMatch(text);

  String displayText = text;

  if (languageMatch != null) {
    displayText = displayText.replaceAllMapped(languagePattern, (match) {
      return match.group(1) ?? 'Dil';
    });
  }

  if (nameMatch != null) {
    displayText = displayText.replaceAllMapped(namePattern, (match) {
      return match.group(1) ?? 'İsim';
    });
  }

  return displayText;
}
