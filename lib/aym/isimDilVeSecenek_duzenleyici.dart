/////
import 'package:flutter/material.dart';
import 'package:proje1/const/colors.dart';
import 'package:proje1/data/database.dart';
import 'package:proje1/model/items.dart';

// handleTapOnText fonksiyonu
Future<void> handleTapOnText(BuildContext context, String text, int index,
    Item item, Function() onTableEdited) async {
  final RegExp languagePattern = RegExp(r'\[Dil:(.*?)\]');
  final RegExp namePattern = RegExp(r'\[İsim:(.*?)\]');
  final RegExp optionsPattern = RegExp(r'\[Seçenekler:(.*?)\]');

  final RegExpMatch? languageMatch = languagePattern.firstMatch(text);
  final RegExpMatch? nameMatch = namePattern.firstMatch(text);
  final RegExpMatch? optionsMatch = optionsPattern.firstMatch(text);

  if (optionsMatch != null) {
    // "[Seçenekler:]" için işlev
    String optionsString = optionsMatch.group(1) ?? '';
    List<String> options = optionsString.split('|');
    String currentOption = options.isNotEmpty ? options[0] : '';

    await showOptionsEditDialog(
      context,
      currentOption,
      optionsString,
      (selectedOption) async {
        item.expandedValue[index] = text
            .replaceFirst(currentOption,
                'TEMP_PLACEHOLDER') // currentOption'ı geçici bir değerle değiştiriyoruz
            .replaceFirst(selectedOption,
                currentOption) // selectedOption'ı currentOption yerine koyuyoruz
            .replaceFirst('TEMP_PLACEHOLDER',
                selectedOption); // Geçici değeri (currentOption yerine koyduğumuz) selectedOption ile değiştiriyoruz

        // // Sadece currentOption güncellenecek, text değişmeyecek
        // item.expandedValue[index] = text.replaceFirst(
        //     currentOption, selectedOption); // Bu satırı değiştiriyoruz
        currentOption = selectedOption; // currentOption güncellensin

        // Veritabanını da aynı şekilde güncelleyebiliriz, ancak text değişmeyecek
        await SQLiteDatasource().updateNote(
          item.id,
          item.headerValue,
          item.subtitle ?? '',
          item.expandedValue,
          item.imageUrls ?? [],
        );

        onTableEdited();
      },
      item,
      index,
      options,
    );
  } else if (languageMatch != null || nameMatch != null) {
    // Dil ve İsim işlevi eski haliyle devam ediyor
    String currentDil = languageMatch?.group(1) ?? '';
    String currentName = nameMatch?.group(1) ?? '';

    await showNameLangEditDialog(
      context,
      currentDil,
      currentName,
      (updatedText) async {
        // Display text güncelleniyor
        item.expandedValue[index] = updatedText;

        await SQLiteDatasource().updateNote(
          item.id,
          item.headerValue,
          item.subtitle ?? '',
          item.expandedValue,
          item.imageUrls ?? [],
        );

        onTableEdited();
      },
      item,
      index,
    );
  }
}

Future<void> showOptionsEditDialog(
  BuildContext context,
  String currentSelection,
  String optionsString,
  Function(String) onUpdated,
  Item item,
  int index,
  List<String> options,
) async {
  String text = item.expandedValue[index];
  String selectedOption = currentSelection;
  final ScrollController _scrollController = ScrollController();

  return showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Center(
                child: Text(
              "Seçenek Düzenleme",
              style:
                  TextStyle(fontStyle: FontStyle.italic, color: Colors.green),
            )),
            content: SizedBox(
              width: double.maxFinite, // Dialog genişliğini maksimize ediyoruz
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Kaynak metin gösterimi
                    Text(
                      text,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Bir Seçenek Seçin:",
                      style: TextStyle(fontSize: 16, color: Colors.green),
                    ),
                    const SizedBox(height: 10),
                    // Seçenekler listesi
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
                              fillColor: WidgetStateProperty.all(Colors.green),
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
                      "Kaydet",
                      style: TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      // Seçilen seçenek ile display text'i güncelle
                      onUpdated(selectedOption);
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
  final RegExp optionsPattern = RegExp(r'\[Seçenekler:(.*?)\]');

  final RegExpMatch? languageMatch = languagePattern.firstMatch(text);
  final RegExpMatch? nameMatch = namePattern.firstMatch(text);
  final RegExpMatch? optionsMatch = optionsPattern.firstMatch(text);

  String displayText = text;

  // [Dil:] patterni için display text'i günceller
  if (languageMatch != null) {
    displayText = displayText.replaceAllMapped(languagePattern, (match) {
      return match.group(1) ?? 'Dil';
    });
  }

  // [İsim:] patterni için display text'i günceller
  if (nameMatch != null) {
    displayText = displayText.replaceAllMapped(namePattern, (match) {
      return match.group(1) ?? 'İsim';
    });
  }

  // [Seçenekler:] patterni için display text'i günceller (varsayılan ilk seçenek)
  if (optionsMatch != null) {
    String optionsString = optionsMatch.group(1) ?? '';
    List<String> options = optionsString.split('|');
    String defaultOption = options.isNotEmpty ? options[0] : '';
    displayText = displayText.replaceFirst(optionsPattern, defaultOption);
    print(displayText);
  }

  return displayText;
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

//////