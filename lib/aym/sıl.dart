/////
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proje1/const/colors.dart';
import 'package:proje1/data/database.dart';
import 'package:proje1/model/items.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../utility/image_copy.dart';

Future<void> handleTapOnText(BuildContext context, String text, int index,
    Item item, Function() onTableEdited) async {
  // Regex patternler
  final RegExp languagePattern = RegExp(r'\[Dil:(.*?)\]');
  final RegExp namePattern = RegExp(r'\[İsim:(.*?)\]');
  final RegExp optionsPattern = RegExp(r'\[Seçenekler:(.*?)\]');
  final RegExp imagePattern = RegExp(r'\[Resim:(.*?)\]');

  // Dil, İsim ve Seçenekleri yakala
  final RegExpMatch? languageMatch = languagePattern.firstMatch(text);
  final RegExpMatch? nameMatch = namePattern.firstMatch(text);
  final RegExpMatch? optionsMatch = optionsPattern.firstMatch(text);
  final RegExpMatch? imageMatch = imagePattern.firstMatch(text);

  // Elde edilen verileri al
  String currentDil = languageMatch?.group(1) ?? '';
  String currentName = nameMatch?.group(1) ?? '';
  String optionsString = optionsMatch?.group(1) ?? '';
  List<String> options =
      optionsString.isNotEmpty ? optionsString.split('|') : [];
  String currentOption = options.isNotEmpty ? options[0] : '';
  String? imageUrl = imageMatch?.group(1); // Resim URL'si, varsa

  // Eğer herhangi bir tag varsa, dialogu aç
  if (languageMatch != null ||
      nameMatch != null ||
      optionsMatch != null ||
      imageMatch != null) {
    await showAllTagsEditDialog(
      context,
      currentDil,
      currentName,
      currentOption,
      options,
      item,
      index,
      imageUrl, // Resim URL'sini dialoga gönder
    );
  }
}

Future<void> showAllTagsEditDialog(
  BuildContext context,
  String currentDil,
  String currentName,
  String currentSelection,
  List<String> options,
  Item item,
  int index,
  String? imageUrl, // Resim URL'si, varsa null olabilir
) async {
  String text = item.expandedValue[index];
  TextEditingController dilController = TextEditingController(text: currentDil);
  TextEditingController isimController =
      TextEditingController(text: currentName);
  String selectedOption = currentSelection;
  final ImagePicker picker = ImagePicker();
  XFile? selectedImage;

  return showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Center(
              child: Text(
                "Etiket Düzenleme",
                style:
                    TextStyle(fontStyle: FontStyle.italic, color: Colors.green),
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      text,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 20),

                    // Dil güncelleme alanı
                    if (currentDil.isNotEmpty)
                      Column(
                        children: [
                          Text(
                            "Dili Güncelle:",
                            style: TextStyle(
                                fontSize: 16, color: Colors.green[400]),
                          ),
                          TextField(
                            controller: dilController,
                            decoration: InputDecoration(
                              hintText: dilController.text,
                              hintStyle: const TextStyle(color: Colors.black54),
                            ),
                            onChanged: (value) {
                              setState(() {
                                dilController.text = value;
                              });
                            },
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),

                    // İsim güncelleme alanı
                    if (currentName.isNotEmpty)
                      Column(
                        children: [
                          Text(
                            "İsmi Güncelle:",
                            style: TextStyle(
                                fontSize: 16, color: Colors.green[400]),
                          ),
                          TextField(
                            controller: isimController,
                            decoration: InputDecoration(
                                hintText: isimController.text,
                                hintStyle:
                                    const TextStyle(color: Colors.black54)),
                            onChanged: (value) {
                              setState(() {
                                isimController.text = value;
                              });
                            },
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),

                    // Seçenekleri güncelleme alanı
                    if (options.isNotEmpty)
                      Column(
                        children: [
                          Text(
                            "Seçeneği Güncelle:",
                            style: TextStyle(
                                fontSize: 16, color: Colors.green[400]),
                          ),
                          const SizedBox(height: 10),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: Scrollbar(
                              trackVisibility: true,
                              thumbVisibility: true,
                              child: ListView.builder(
                                itemCount: options.length,
                                shrinkWrap: true,
                                itemBuilder: (context, index) {
                                  return RadioListTile<String>(
                                    activeColor: Colors.green,
                                    title: Text(options[index]),
                                    value: options[index],
                                    groupValue: selectedOption,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        selectedOption = newValue!;
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    // const SizedBox(height: 20),

                    // Eğer [Resim:] etiketi varsa, resmi göster ve düzenlemeye izin ver
                    if (imageUrl != null) ...[
                      // Divider(thickness: 1, color: Colors.green[100]),
                      Text(
                        "Resmi Güncelle:",
                        style:
                            TextStyle(fontSize: 16, color: Colors.green[400]),
                      ),
                      const SizedBox(height: 10),

                      // Mevcut resmi göster
                      Container(
                          height: 150,
                          width: 150,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                          ),
                          child: imageUrl!.isNotEmpty
                              ? Image.file(
                                  File(imageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : IconButton(
                                  onPressed: () async {
                                    final XFile? image = await picker.pickImage(
                                        source: ImageSource.gallery);
                                    if (image != null) {
                                      setState(() {
                                        selectedImage = image;
                                        imageUrl =
                                            image.path; // Resim yolunu güncelle
                                      });
                                    }
                                  },
                                  icon: Icon(Icons.file_download_outlined),
                                  iconSize: 100,
                                  color: Colors.grey)),

                      const SizedBox(height: 10),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[50],
                        ),
                        onPressed: () async {
                          final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery);
                          if (image != null) {
                            setState(() {
                              selectedImage = image;
                              imageUrl = image.path; // Resim yolunu güncelle
                            });
                          }
                        },
                        child: const Text('Resim Seç',
                            style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      "İptal",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[50],
                    ),
                    child: const Text(
                      "Kopyala",
                      style: TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      // Güncellenen metni oluştur
                      String updatedText = text;

                      if (currentDil.isNotEmpty) {
                        updatedText = updatedText.replaceFirst(
                            RegExp(r'\[Dil:(.*?)\]'),
                            '[Dil:${dilController.text}]');
                      }

                      if (currentName.isNotEmpty) {
                        updatedText = updatedText.replaceFirst(
                            RegExp(r'\[İsim:(.*?)\]'),
                            '[İsim:${isimController.text}]');
                      }

                      if (options.isNotEmpty) {
                        updatedText = updatedText.replaceFirst(
                            RegExp(r'\[Seçenekler:(.*?)\]'),
                            '[Seçenekler:$selectedOption]');
                      }

                      if (imageUrl != null) {
                        updatedText = updatedText.replaceFirst(
                            RegExp(r'\[Resim:(.*?)\]'), '[Resim:$imageUrl]');
                      }

                      // Metni ve varsa resmi kopyala
                      Clipboard.setData(
                          ClipboardData(text: getDisplayText(updatedText)));
                      if (imageUrl != null && imageUrl!.isNotEmpty) {
                        copyImageToClipboard(context, imageUrl!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              duration: Duration(seconds: 1),
                              content:
                                  Text('Metin ve resim panoya kopyalandı!')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              duration: Duration(seconds: 1),
                              content: Text('Metin panoya kopyalandı!')),
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

// Display text function: Displays only name, language, and option info// Display text function: Displays only name, language, and option info
String getDisplayText(String text) {
  final RegExp languagePattern = RegExp(r'\[Dil:(.*?)\]');
  final RegExp namePattern = RegExp(r'\[İsim:(.*?)\]');
  final RegExp optionsPattern = RegExp(r'\[Seçenekler:(.*?)\]');
  final RegExp imagePattern = RegExp(r'\[Resim:(.*?)\]');

  // Dil etiketini kaldır ve sadece içeriği bırak
  text = text.replaceAllMapped(languagePattern, (match) {
    return match.group(1) ?? '';
  });

  // İsim etiketini kaldır ve sadece içeriği bırak
  text = text.replaceAllMapped(namePattern, (match) {
    return match.group(1) ?? '';
  });

  // Seçenekler etiketini kaldır ve sadece seçilen değeri bırak
  text = text.replaceAllMapped(optionsPattern, (match) {
    String optionsString = match.group(1) ?? '';
    List<String> options = optionsString.split('|');
    return options.isNotEmpty ? options[0] : '';
  });

  // Resim etiketini kaldır (resim içeriğini görüntülemiyoruz)
  text = text.replaceAllMapped(imagePattern, (match) {
    return ''; // Resim tagini gösterme, boş bırak
  });

  return text;
}

// Display text function: Displays name, language, option info with color
Widget getColoredDisplayText(String text) {
  List<InlineSpan> textSpans = [];
  int currentIndex = 0;

  // Hem Dil, İsim, Seçenekler ve Resim patternlerini kapsayan regex
  final RegExp allPatterns = RegExp(
      r'\[Dil:(.*?)\]|\[İsim:(.*?)\]|\[Seçenekler:(.*?)\]|\[Resim:(.*?)\]');
  Iterable<RegExpMatch> matches = allPatterns.allMatches(text);

  for (final match in matches) {
    if (match.start > currentIndex) {
      textSpans.add(TextSpan(
        text: text.substring(currentIndex, match.start),
        style: const TextStyle(color: Colors.black),
      ));
    }

    // Dil patterni
    if (match.group(1) != null) {
      textSpans.add(
        TextSpan(
          text: match.group(1),
          style: TextStyle(
            color: Colors.brown,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
            decoration: TextDecoration.underline,
            decorationColor: Colors.brown[300],
            decorationStyle: TextDecorationStyle.dotted,
            decorationThickness: 2.0,
          ),
        ),
      );
    }
    // İsim patterni
    else if (match.group(2) != null) {
      textSpans.add(
        TextSpan(
          text: match.group(2),
          style: TextStyle(
            color: Colors.brown,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
            decoration: TextDecoration.underline,
            decorationColor: Colors.brown[300],
            decorationStyle: TextDecorationStyle.solid,
            decorationThickness: 2.0,
          ),
        ),
      );
    }
    // Seçenekler patterni
    else if (match.group(3) != null) {
      String optionsString = match.group(3)!;
      List<String> options = optionsString.split('|');
      String defaultOption = options.isNotEmpty ? options[0] : '';

      textSpans.add(
        TextSpan(
          text: defaultOption,
          style: TextStyle(
            color: Colors.brown,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.normal,
            decoration: TextDecoration.underline,
            decorationColor: Colors.brown[300],
            decorationStyle: TextDecorationStyle.double,
            decorationThickness: 1.5,
          ),
        ),
      );
    }

    // Resim patterni: Resim tagi görünmeyecek
    currentIndex = match.end;
  }

  if (currentIndex < text.length) {
    textSpans.add(TextSpan(
      text: text.substring(currentIndex),
      style: const TextStyle(color: Colors.black),
    ));
  }

  return RichText(
    text: TextSpan(children: textSpans),
  );
}
