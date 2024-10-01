import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proje1/data/database.dart';
import 'dart:io';
import 'package:proje1/model/items.dart';
import 'package:proje1/pages/show_image_page.dart';
import '../pages/edit_item_page.dart';

class ListItem extends StatefulWidget {
  final Item item;
  final bool isGlobalExpanded; // Global genişletme durumu
  final bool isLocalExpanded; // Yerel genişletme durumu
  final Function(bool) onExpandedChanged; // Yerel genişletme durumu bildirimi
  final Function onTableEdited;
  const ListItem({
    required this.item,
    required this.isGlobalExpanded,
    required this.isLocalExpanded,
    required this.onExpandedChanged,
    super.key,
    required this.onTableEdited,
  });

  @override
  _ListItemState createState() => _ListItemState();
}

class _ListItemState extends State<ListItem> {
  late bool isLocalExpanded; // Her öğenin kendi genişletme durumu
  static const platform = MethodChannel('clipboard_image');
  final RegExp dilPattern = RegExp(r'\[Dil:(.*?)\]');

  @override
  void initState() {
    super.initState();
    // Her öğenin kendi genişleme durumu başlangıçta item'dan geliyor
    isLocalExpanded = widget.item.isExpanded;
  }

  // Metni panoya kopyalayan fonksiyon
  Future<void> _copyText(String text) async {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Metin panoya kopyalandı!')),
    );
  }

  // Resmi panoya kopyalayan fonksiyon (base64)
  Future<void> _copyImageAndText(String imagePath) async {
    try {
      // Check if the image path is valid
      final file = File(imagePath);
      if (await file.exists()) {
        final fileSize = await file.length();
        print('Dosya mevcut ve boyutu: $fileSize bytes');

        // Android native kodu ile clipboard'a resmi kopyala
        final result = await platform
            .invokeMethod('copyImageToClipboard', {'path': imagePath});
        print(result); // Başarı mesajı dönerse burada kontrol edilir

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Görsel panoya kopyalandı!')),
        );
      } else {
        print('Dosya mevcut değil');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dosya mevcut değil!')),
        );
      }
    } catch (e) {
      print("Resim kopyalama hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resim kopyalanırken hata oluştu: $e')),
      );
    }
  }

  void _navigateAndEditItem(BuildContext context, Item item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditItemPage(item: item)),
    );

    // Geri dönen sonucu kontrol ediyoruz
    if (result == "saved") {
      widget.onTableEdited(); // Düzenleme başarılıysa veriyi yenile
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text('Item successfully updated!'),
      //   ),
      // );
    } else if (result == "deleted") {
      widget.onTableEdited(); // Silme başarılıysa listeyi güncelle
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text('Item successfully deleted!'),
      //   ),
      // );
    }
  }

  void _handleTapOnText(String text) {
    final RegExpMatch? match = dilPattern.firstMatch(text);

    if (match != null) {
      // Mevcut dil bilgisini alıyoruz
      String currentDil = match.group(1) ?? "İngilizce";

      // Dialog'u açalım ve dil güncellemesini sağlayalım
      _showLanguageDialog(currentDil, (updatedDil) async {
        setState(() {
          // Metindeki dil bilgisini güncelleyerek metni tekrar oluşturuyoruz
          String updatedText = text.replaceAll(dilPattern, '[Dil:$updatedDil]');

          // expandedValue'yu güncelliyoruz
          int index = widget.item.expandedValue.indexOf(text);
          if (index != -1) {
            // Güncellenen değeri expandedValue içinde ilgili index'e yazıyoruz
            widget.item.expandedValue[index] = updatedText;
          }
        });

        // Notu veritabanında güncelle
        await SQLiteDatasource().updateNote(
          widget.item.id,
          widget.item.headerValue,
          widget.item.subtitle ?? '',
          widget.item.expandedValue,
          widget.item.imageUrls ?? [],
        );

        // UI'yi güncellemek için onTableEdited çağrılıyor
        widget.onTableEdited();
      });
    }
  }

  void _showLanguageDialog(String currentDil, Function(String) onUpdated) {
    TextEditingController dilController =
        TextEditingController(text: currentDil);

    showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder ile dialog içindeki durumu güncellemek için state yönetimi sağlıyoruz
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                  "Şu andan itibaren benim [Dil:${dilController.text}] öğretmenimsin."), // Dinamik dil
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Dil:"),
                  TextField(
                    controller: dilController,
                    decoration:
                        const InputDecoration(hintText: "Dil adı girin"),
                    onChanged: (value) {
                      // Kullanıcı TextField'a yeni bir şey yazdıkça başlığı güncelle
                      setState(() {
                        // Başlığı dinamik olarak güncellemek için dil bilgisini kullanıyoruz
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text("İptal"),
                  onPressed: () {
                    Navigator.of(context).pop(); // Dialog'u kapat
                  },
                ),
                ElevatedButton(
                  child: const Text("Tamam"),
                  onPressed: () {
                    // Dialog'dan gelen dil bilgisini geri döndürüyoruz
                    onUpdated(dilController.text);
                    Navigator.of(context).pop(); // Dialog'u kapat
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getDisplayText(String text) {
    // [Dil:...] şeklindeki kısmı yakalayıp sadece dil adını gösterelim
    return text.replaceAllMapped(dilPattern, (match) {
      return match.group(1) ?? 'Dil';
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isExpanded = widget.isGlobalExpanded || widget.isLocalExpanded;

    return ExpansionPanelList(
      expansionCallback: (int index, bool expanded) {
        print("Panel genişliyor: $expanded");
        setState(() {
          isLocalExpanded = !isExpanded;
          widget.onExpandedChanged(isLocalExpanded);
        });
      },
      expandedHeaderPadding: const EdgeInsets.only(
        left: 5,
        right: 5,
      ),
      children: [
        ExpansionPanel(
          hasIcon: true,
          canTapOnHeader: true,
          headerBuilder: (BuildContext context, bool expanded) {
            return Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: Text(
                      widget.item.headerValue,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: widget.item.subtitle == null ||
                            widget.item.subtitle == ""
                        ? null
                        : Text(widget.item.subtitle!),
                    visualDensity: VisualDensity.compact,
                    onTap: () {
                      setState(() {
                        isLocalExpanded = !isExpanded;
                        widget.onExpandedChanged(isLocalExpanded);
                      });
                    },
                  ),
                ),
                IconButton(
                  color: Colors.grey,
                  padding: EdgeInsets.zero, // Remove padding around the icon
                  icon: const Icon(Icons.edit_note_rounded),
                  onPressed: () {
                    _navigateAndEditItem(context, widget.item);
                  },
                ),
              ],
            );
          },
          body: Column(
            children: widget.item.expandedValue.asMap().entries.map((entry) {
              int idx = entry.key;
              String text = entry.value;
              String? imageUrl = widget.item.imageUrls != null &&
                      widget.item.imageUrls!.length > idx &&
                      widget.item.imageUrls![idx].isNotEmpty
                  ? widget.item.imageUrls![idx]
                  : null;

              return Column(
                children: [
                  ListTile(
                    horizontalTitleGap: 10,
                    minVerticalPadding: 10,
                    minLeadingWidth: 10,
                    minTileHeight: 10,
                    title: GestureDetector(
                        onLongPress: () {
                          _handleTapOnText(
                              text); // Metin uzun basılırsa [Dil] kısmını kontrol et ve dialog aç
                          print(text);
                        },
                        child: Text(_getDisplayText(text))),
                    leading: GestureDetector(
                      onTap: imageUrl != null
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ShowImage(
                                    imagePaths: widget.item.imageUrls ?? [],
                                    // itemText: widget.item.expandedValue,
                                    item: widget.item,
                                    initialIndex:
                                        idx, // Burada indeksi belirtiyoruz
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: imageUrl != null &&
                              imageUrl.isNotEmpty &&
                              File(imageUrl).existsSync()
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(3.0),
                              child: Image.file(
                                File(imageUrl),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(Icons.image,
                              size: 50, color: Colors.grey.shade400),
                    ),
                    visualDensity: VisualDensity.compact,
                    dense: true,
                    onTap: () {
                      if (imageUrl != null && imageUrl.isNotEmpty) {
                        _copyImageAndText(imageUrl);
                      }
                      _copyText(text);
                    },
                  ),
                  if (widget.item.expandedValue.length > 1 &&
                      idx < widget.item.expandedValue.length - 1)
                    Divider(
                      thickness: 1,
                      indent: 28,
                      endIndent: 28,
                      color: Colors.grey[300],
                    ),
                ],
              );
            }).toList(),
          ),
          isExpanded: isExpanded, // Global ya da yerel genişleme durumu
        ),
      ],
    );
  }
}
