import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proje1/aym/isimDilVeSecenek_duzenleyici.dart';
import 'dart:io';
import 'package:proje1/model/items.dart';
import 'package:proje1/pages/show_image_page.dart';
import '../aym/resim_kopyalama.dart';
import '../pages/edit_item_page.dart';

import '../utility/image_copy.dart';

class ListItem extends StatefulWidget {
  final Item item;
  final bool isGlobalExpanded;
  final bool isLocalExpanded;
  final Function(bool) onExpandedChanged;
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
  late bool isLocalExpanded;

  @override
  void initState() {
    super.initState();
    // Her öğenin kendi genişleme durumu başlangıçta item'dan geliyor
    isLocalExpanded = widget.item.isExpanded;
  }

  // Metni panoya kopyalayan fonksiyon #kopyalamaa,textkopyalamaa
  Future<void> _copyText(String text) async {
    final displayText = getDisplayText(text);
    Clipboard.setData(ClipboardData(text: displayText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Duration(seconds: 1),
        content: Text(
          text.length > 30
              ? '${displayText.substring(0, 30)}... panoya kopyalandı!'
              : '$displayText panoya kopyalandı!',
        ),
      ),
    );
  }

  // EditItemPage'e yönlendirme, dönüşte veri bekliyoruz. #_navigateAndEditItemm
  void _navigateAndEditItem(BuildContext context, Item item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditItemPage(item: item)),
    );

    // Geri dönen sonucu kontrol ediyoruz
    if (result == "saved") {
      widget.onTableEdited();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 1),
          content: Text('Tablo başarılı bir şekilde düzenlendi!'),
        ),
      );
    } else if (result == "deleted") {
      widget.onTableEdited();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 1),
          content: Text('Tablo başarılı bir şekilde silindi!'),
        ),
      );
    } else if (result == "pop") {
      widget.onTableEdited();
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isExpanded = widget.isGlobalExpanded || widget.isLocalExpanded;

    return ExpansionPanelList(
      expansionCallback: (int index, bool expanded) {
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
                    onLongPress: () async {
                      // tablodaki tüm itemleri panoya kopyalama #titlecopyy
                      List<String> texts =
                          widget.item.expandedValue.join('||').split('||');

                      for (String text in texts) {
                        final displayText = getDisplayText(text);
                        Clipboard.setData(ClipboardData(text: displayText));
                        await Future.delayed(const Duration(milliseconds: 500));
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            duration: Duration(seconds: 1),
                            content:
                                Text('Tablonun itemleri panoya kopyalandı!')),
                      );
                    },
                    onTap: () async {
                      setState(() {
                        isLocalExpanded = !isExpanded;
                        widget.onExpandedChanged(isLocalExpanded);
                      });
                    },
                  ),
                ),
                IconButton(
                  color: Colors.grey,
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.edit_note_rounded), //#editiconn,kalemm
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
              // Metin uzunluğu ve görsel durumuna göre padding ayarla
              double bottomPadding = (text.isEmpty || text.length < 20) &&
                      imageUrl == null
                  ? 10.0 // Eğer metin kısa veya boşsa, görsel varsa daha fazla padding ekliyoruz
                  : 1.0; // Aksi halde varsayılan padding
              return Padding(
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: Column(
                  children: [
                    ListTile(
                      focusColor: Colors.green[50],
                      hoverColor: Colors.green[50],
                      splashColor: Colors.green[50],
                      horizontalTitleGap: 10,
                      minVerticalPadding: 10,
                      minLeadingWidth: 10,
                      minTileHeight: 10,
                      title: GestureDetector(
                        onLongPress: () {
                          // Uzun basıldığında resmi ve texti panoya kopyalama #imagecopyy,textcopyy
                          if (imageUrl != null && imageUrl.isNotEmpty) {
                            copyImageToClipboard(context, imageUrl);
                          }
                          _copyText(text);
                        },
                        child: getColoredDisplayText(text), //#displaytextt
                      ),
                      leading: GestureDetector(
                        // Resmi görüntüleme sayfasına gonderme
                        onTap: imageUrl != null
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ShowImage(
                                      imagePaths: widget.item.imageUrls ?? [],
                                      item: widget.item,
                                      initialIndex: idx,
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
                            : GestureDetector(
                                onTap: () {
                                  // // Resim aym. resim seçip kopyalama #resimaymm,aymm
                                  // selectAndCopyImageDialog(
                                  //     context, widget.item.expandedValue[idx]
                                  //     );
                                },
                                child: Icon(Icons.image,
                                    size: 50, color: Colors.grey.shade400),
                              ),
                      ),
                      visualDensity: VisualDensity.compact,
                      dense: true,
                      onTap: () {
                        //İsim, dil, seçenekler ve resimgibi bilgileri düzenleme sayfasına gonderme #aymm,isimaymm,seçenekaymm,dilaymm
                        print(text);
                        print(idx);
                        handleTapOnText(
                          context,
                          text,
                          idx,
                          widget.item,
                          () {
                            setState(() {}); // onTableEdited çağrılıyor
                          },
                        );
                      },
                    ),
                    if (widget.item.expandedValue.length > 1 &&
                        idx < widget.item.expandedValue.length - 1)
                      Divider(
                        thickness: 2,
                        indent: 28,
                        endIndent: 28,
                        color: Colors.green[50],
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
          isExpanded: isExpanded,
        ),
      ],
    );
  }
}
