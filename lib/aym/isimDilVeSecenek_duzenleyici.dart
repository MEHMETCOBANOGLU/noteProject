import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:Tablify/model/items.dart';
import 'package:Tablify/utility/image_copy.dart';

//Metin kopyalama fonksiyonu #copyy
Future<void> _copyText(BuildContext context, String text) async {
  final displayText = getDisplayText(text);
  Clipboard.setData(ClipboardData(text: displayText));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 1),
      content: Text(
        text.length > 30
            ? '${displayText.substring(0, 30)}... panoya kopyalandı!'
            : '$displayText panoya kopyalandı!',
      ),
    ),
  );
}

//Aym RegExp kontrol fonksiyonu #regexpp
Future<void> handleTapOnText(BuildContext context, String text, int index,
    Item item, Function() onTableEdited) async {
// Bu RegExp, köşeli parantezler içinde etiketleri ve isteğe bağlı parametreleri tanımlamak için kullanılır.
// Örneğin: [Etiket:Parametre] şeklindeki yapıları bulur.
  final RegExp tagPattern =
      RegExp(r'\[([\p{L}\p{M}\p{N}_]+)(?::([^\]]*))?\]', unicode: true);

  final Iterable<RegExpMatch> matches = tagPattern.allMatches(text);

  // Etiketlerin listesini oluştur
  List<Map<String, dynamic>> tagList = [];

  for (var match in matches) {
    String variable = match.group(1) ?? '';
    String? value = match.group(2);
    tagList.add({
      'variable': variable,
      'value': value,
      'match': match,
    });
  }
  // eğer hiçbir etiket yoksa, metin panoya kopyala
  if (tagList.isEmpty) {
    if (item.imageUrls != null &&
        item.imageUrls!.isNotEmpty &&
        index < item.imageUrls!.length &&
        item.imageUrls![index].isNotEmpty) {
      copyImageToClipboard(context, item.imageUrls![index]);
    }
    _copyText(context, text);
  }

  final ImagePicker picker = ImagePicker();

  // Eğer sadece tek bir etiket varsa ve bu etiket `[IMG]` ise
  if (tagList.length == 1 &&
      tagList[0]['variable'] == 'IMG' &&
      matches.length == 1) {
    // Eğer `[IMG]` etiketi herhangi bir değer içermiyorsa
    if (tagList[0]['value'] == null) {
      // Doğrudan görsel seçme işlemini başlat
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        // Görseli panoya kopyala
        copyImageToClipboard(context, image.path);
        _copyText(context, text);
      }
      return;
    }
  }

  // Eğer etiketler varsa, diyaloğu aç
  if (tagList.isNotEmpty) {
    await showAllTagsEditDialog(
      context,
      tagList,
      item,
      index,
    );
  }
}

//Etiket düzenleme ve kopyalama penceresi #etikett,aymm,etiketdüzenlemee
Future<void> showAllTagsEditDialog(
  BuildContext context,
  List<Map<String, dynamic>> tagList,
  Item item,
  int index,
) async {
  String text = item.expandedValue[index];
  Map<String, TextEditingController> controllers = {};
  late bool isTextStyle = true;
  String? imgPath;

  // Kontrolörleri başlat
  for (var tag in tagList) {
    String key = tag['variable'];
    String? value = tag['value'];

    if (key == 'Seçenekler' && value != null) {
      List<String> options = value.split('|');
      String selectedOption = options.isNotEmpty ? options.first : '';
      controllers[key] = TextEditingController(text: selectedOption);
    } else if (key == 'IMG') {
      controllers[key] = TextEditingController(text: value ?? '');
    } else {
      controllers[key] = TextEditingController(text: value ?? '');
    }
  }

  final ImagePicker picker = ImagePicker();
  XFile? selectedImage;

  return showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
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
            content: SingleChildScrollView(
              child: SizedBox(
                width: double.maxFinite,
                child: DefaultTabController(
                  length: 2,
                  initialIndex: isTextStyle ? 0 : 1,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TabBar(
                        indicatorColor: Colors.green,
                        labelColor: Colors.green,
                        unselectedLabelColor: Colors.grey,
                        onTap: (int index) {
                          setState(() {
                            isTextStyle = index == 0;
                          });
                        },
                        tabs: const [
                          Tab(text: 'Metin'),
                          Tab(text: 'Kaynak Metin'),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        height: 60,
                        child: TabBarView(
                          children: [
                            SingleChildScrollView(
                              child: getColoredDisplayText(text),
                            ),
                            SingleChildScrollView(
                              child: Text(
                                text,
                                style: const TextStyle(color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...tagList.map((tag) {
                        String key = tag['variable'];
                        String? value = tag['value'];

                        // 'Seçenekler' için özel işlem
                        if (key == 'Seçenekler') {
                          List<String> options =
                              value != null && value.isNotEmpty
                                  ? value.split('|')
                                  : [];
                          String selectedOption = controllers[key]?.text ?? '';

                          return Column(
                            children: [
                              Text(
                                "$key'i Güncelle:",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.green[400]),
                              ),
                              const SizedBox(height: 10),
                              if (options.isNotEmpty)
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxHeight: 200),
                                  child: Scrollbar(
                                    trackVisibility: true,
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
                                              controllers[key]?.text =
                                                  selectedOption;
                                            });
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                )
                              else
                                TextField(
                                  decoration: InputDecoration(
                                    hintText: controllers[key]?.text,
                                    hintStyle:
                                        const TextStyle(color: Colors.black54),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      controllers[key]?.text = value;
                                    });
                                  },
                                ),
                            ],
                          );
                        }
                        // 'IMG' için özel işlem
                        else if (key == 'IMG') {
                          String? imgValue = controllers[key]?.text;
                          // Dosyanın mevcut olup olmadığını kontrol edelim
                          bool fileExists =
                              imgValue != null && File(imgValue).existsSync();

                          return Column(
                            children: [
                              if (key == 'IMG' &&
                                  value != null &&
                                  value.isNotEmpty)
                                Text(
                                  // "$key'i Güncelle:",
                                  "Resim Değerini Güncelle:",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.green[400]),
                                ),
                              const SizedBox(height: 10),
                              if (key == 'IMG' &&
                                  value != null &&
                                  value.isNotEmpty)
                                TextField(
                                  decoration: InputDecoration(
                                    hintText: controllers[key]?.text,
                                    hintStyle:
                                        const TextStyle(color: Colors.black54),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      controllers[key]?.text = value;
                                    });
                                  },
                                ),
                              const SizedBox(height: 10),
                              Text(
                                // "$key'i Güncelle:",
                                "Resmi Güncelle:",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.green[400]),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                height: 150,
                                width: 150,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: imgPath != null && imgPath!.isNotEmpty
                                    ? Image.file(
                                        File(imgPath!),
                                        fit: BoxFit.cover,
                                      )
                                    : IconButton(
                                        onPressed: () async {
                                          final XFile? image =
                                              await picker.pickImage(
                                                  source: ImageSource.gallery);
                                          if (image != null) {
                                            setState(() {
                                              imgPath = image.path;
                                            });
                                          }
                                        },
                                        icon: const Icon(
                                            Icons.file_download_outlined),
                                        iconSize: 100,
                                        color: Colors.grey,
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
                                      imgPath = image.path;
                                    });
                                  }
                                },
                                child: const Text('Resim Seç',
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 10),
                            ],
                          );
                        }
                        // Diğer etiketler için
                        else {
                          return Column(
                            children: [
                              Text(
                                "$key'i Güncelle:",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.green[400]),
                              ),
                              TextField(
                                decoration: InputDecoration(
                                  hintText: controllers[key]?.text,
                                  hintStyle:
                                      const TextStyle(color: Colors.black54),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    controllers[key]?.text = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 10),
                            ],
                          );
                        }
                      }),
                    ],
                  ),
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
                      // Güncellenmiş metni oluştur
                      String updatedText = text;
                      int offset = 0;

                      for (var tag in tagList) {
                        String key = tag['variable'];
                        String? originalValue = tag['value'];
                        RegExpMatch match = tag['match'];

                        String updatedValue = controllers[key]?.text ?? '';

                        String newTag;
                        if (key == 'Seçenekler' && originalValue != null) {
                          newTag = '[$key:$updatedValue]';
                        } else if (originalValue != null) {
                          newTag = updatedValue.isNotEmpty
                              ? '[$key:$updatedValue]'
                              : '[$key]';
                        } else {
                          newTag = updatedValue.isNotEmpty
                              ? '[$key:$updatedValue]'
                              : '[$key]';
                        }

                        int start = match.start + offset;
                        int end = match.end + offset;

                        updatedText =
                            updatedText.replaceRange(start, end, newTag);

                        offset += newTag.length - (end - start);
                      }

                      // Metni ve varsa resmi kopyala
                      String displayText = getDisplayText(updatedText);

                      if (displayText.trim().isEmpty) {
                        displayText = "İçerik Bulunamadı";
                      }
                      _copyText(context, displayText);

                      if (imgPath != null && imgPath!.isNotEmpty) {
                        copyImageToClipboard(context, imgPath!);
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

//itemlere ait texlerin etiketsiz hallerini gösterir #displaytextt,metinn,textt
String getDisplayText(String text) {
  final RegExp tagPattern =
      RegExp(r'\[([\p{L}\p{M}\p{N}_]+)(?::([^\]]*))?\]', unicode: true);

  // Etiketleri değerleriyle değiştir
  text = text.replaceAllMapped(tagPattern, (match) {
    String variable = match.group(1) ?? '';
    String? value = match.group(2);

    // 'Seçenekler' için sadece seçili seçeneği göster
    if (variable == 'Seçenekler') {
      List<String> options = value!.split('|');
      return options.isNotEmpty ? options[0] : '';
    }

    // 'IMG' etiketi için
    if (variable == 'IMG') {
      return value ?? '';
    }

    return value ?? '';
  });

  return text;
}

// Etiket değerlerini renkli ve formatlı gösteren fonksiyon
Widget getColoredDisplayText(String text) {
  List<InlineSpan> textSpans = [];
  int currentIndex = 0;

  final RegExp tagPattern =
      RegExp(r'\[([\p{L}\p{M}\p{N}_]+)(?::([^\]]*))?\]', unicode: true);

  Iterable<RegExpMatch> matches = tagPattern.allMatches(text);

  for (final match in matches) {
    if (match.start > currentIndex) {
      textSpans.add(TextSpan(
        text: text.substring(currentIndex, match.start),
        style: const TextStyle(color: Colors.black),
      ));
    }

    String variable = match.group(1) ?? '';
    String? value = match.group(2);

    // Değişkenlere göre stil ayarları
    TextStyle style = TextStyle(
      color: Colors.brown,
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.italic,
      decoration: TextDecoration.underline,
      decorationColor: Colors.brown[300],
      decorationStyle: TextDecorationStyle.solid,
      decorationThickness: 2.0,
    );

    // 'Seçenekler' için özel stil
    if (variable == 'Seçenekler') {
      if (value != null) {
        style = TextStyle(
          color: Colors.brown,
          fontWeight: FontWeight.w500,
          fontStyle: FontStyle.normal,
          decoration: TextDecoration.underline,
          decorationColor: Colors.brown[300],
          decorationStyle: TextDecorationStyle.double,
          decorationThickness: 1.5,
        );

        List<String> options = value.split('|');
        String defaultOption = options.isNotEmpty ? options[0] : '';
        textSpans.add(
          TextSpan(
            text: defaultOption,
            style: style,
          ),
        );
      }
    }
    // 'IMG' etiketi için
    else if (variable == 'IMG') {
      if (value != null && value.isNotEmpty) {
        textSpans.add(
          TextSpan(
            text: value,
            style: style,
          ),
        );
      }
    }
    // Diğer etiketler için
    else {
      textSpans.add(
        TextSpan(
          text: value ?? '',
          style: style,
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

  // Eğer oluşan metin sadece [DİL] etiketi içeriyorsa varsayılan mesaj göster
  if ((textSpans.length == 1 && textSpans[0].toPlainText() == "[DİL]")) {
    textSpans.add(const TextSpan(
      text: "Resim İçeriği Bulunamadı",
      style: TextStyle(color: Colors.grey),
    ));
  }

  return RichText(
    text: TextSpan(children: textSpans),
  );
}
