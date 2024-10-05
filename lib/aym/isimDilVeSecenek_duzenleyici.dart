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
  // Regex patterns
  final RegExp languagePattern = RegExp(r'\[Dil:(.*?)\]');
  final RegExp namePattern = RegExp(r'\[İsim:(.*?)\]');
  final RegExp optionsPattern = RegExp(r'\[Seçenekler:(.*?)\]');

  // Capture matches
  final RegExpMatch? languageMatch = languagePattern.firstMatch(text);
  final RegExpMatch? nameMatch = namePattern.firstMatch(text);
  final RegExpMatch? optionsMatch = optionsPattern.firstMatch(text);

  // Extract language, name, and options data
  String currentDil = languageMatch?.group(1) ?? '';
  String currentName = nameMatch?.group(1) ?? '';
  String optionsString = optionsMatch?.group(1) ?? '';
  List<String> options =
      optionsString.isNotEmpty ? optionsString.split('|') : [];
  String currentOption = options.isNotEmpty ? options[0] : '';

  // Check if the item has an image (modify this logic as per your Item model)
  bool hasImage =
      item.imageUrls![index] != null && item.imageUrls![index].isNotEmpty;

  // Open the dialog only if one of the patterns exists
  if (languageMatch != null || nameMatch != null || optionsMatch != null) {
    await showAllTagsEditDialog(
      context,
      currentDil,
      currentName,
      currentOption,
      options,
      item,
      index,
      hasImage, // Pass the image status to the dialog
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
  bool hasImage, // New parameter to check if the image exists
) async {
  String text = item.expandedValue[index];
  TextEditingController dilController = TextEditingController(text: currentDil);
  TextEditingController isimController =
      TextEditingController(text: currentName);
  String selectedOption = currentSelection;
  final ScrollController _scrollController = ScrollController();
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
                    if (currentDil.isNotEmpty)
                      Column(
                        children: [
                          Text(
                            "Dili Güncelle:",
                            style: TextStyle(
                                fontSize: 16, color: Colors.green[400]),
                          ),
                          TextField(
                            // controller: dilController,
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
                    if (currentName.isNotEmpty)
                      Column(
                        children: [
                          Text(
                            "İsmi Güncelle:",
                            style: TextStyle(
                                fontSize: 16, color: Colors.green[400]),
                          ),
                          TextField(
                            // controller: isimController,
                            decoration: InputDecoration(
                                hintText: isimController.text,
                                hintStyle: TextStyle(color: Colors.black54)),
                            onChanged: (value) {
                              setState(() {
                                isimController.text = value;
                              });
                            },
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),
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
                              controller: _scrollController,
                              child: ListView.builder(
                                controller: _scrollController,
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
                    const SizedBox(height: 20),
                    if (!hasImage) ...[
                      Divider(thickness: 1, color: Colors.green[100]),
                      Text(
                        "Resimi Güncelle:",
                        style:
                            TextStyle(fontSize: 16, color: Colors.green[400]),
                      ),
                      const SizedBox(height: 10),
                      // Image selection only if no image exists
                      selectedImage == null
                          ? Container(
                              height: 150,
                              width: 150,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                              ),
                              child: Center(
                                child: IconButton(
                                  onPressed: () async {
                                    final XFile? image = await picker.pickImage(
                                        source: ImageSource.gallery);
                                    if (image != null) {
                                      setState(() {
                                        selectedImage = image;
                                      });
                                    }
                                  },
                                  icon: const Icon(
                                    size: 100,
                                    Icons.file_download_outlined,
                                    color: Colors.black54,
                                  ),
                                ),
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
                          final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery);
                          if (image != null) {
                            setState(() {
                              selectedImage = image;
                            });
                          }
                        },
                        child: const Text('Resim Seç',
                            style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold)),
                      ),
                    ] else ...[
                      // const Text('Resim zaten mevcut, düzenlenemez.',
                      //     style: TextStyle(color: Colors.red)),
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
                            '[Seçenekler:${selectedOption}]');
                      }

                      // Etiketleri temizleyip metni kopyala
                      String displayText = getDisplayText(updatedText);
                      Clipboard.setData(ClipboardData(text: displayText));

                      if (selectedImage != null) {
                        copyImageToClipboard(context, selectedImage!.path);
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
                              content: Text(
                                  'Metin panoya kopyalandı! Resim seçilmedi.')),
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

// Display text function: Displays only name and language info
String getDisplayText(String text) {
  final RegExp languagePattern = RegExp(r'\[Dil:(.*?)\]');
  final RegExp namePattern = RegExp(r'\[İsim:(.*?)\]');
  final RegExp optionsPattern = RegExp(r'\[Seçenekler:(.*?)\]');

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

  return text;
}

// Display text function: Displays name and language info with color
Widget getColoredDisplayText(String text) {
  List<InlineSpan> textSpans = [];
  int currentIndex = 0;

  // Hem Dil, İsim hem de Seçenekler patternlerini kapsayan regex
  final RegExp allPatterns =
      RegExp(r'\[Dil:(.*?)\]|\[İsim:(.*?)\]|\[Seçenekler:(.*?)\]');
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
