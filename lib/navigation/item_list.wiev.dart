import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proje1/aym/isimVeDil_duzenleyici.dart';
import 'package:proje1/data/database.dart';
import 'dart:io';
import 'package:proje1/model/items.dart';
import 'package:proje1/pages/show_image_page.dart';
import '../aym/resim_kopyalama.dart';
import '../pages/edit_item_page.dart';
import 'package:image_picker/image_picker.dart';

import '../utility/image_copy.dart';

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
                    focusColor: Colors.green[50],
                    hoverColor: Colors.green[50],
                    splashColor: Colors.green[50],
                    horizontalTitleGap: 10,
                    minVerticalPadding: 10,
                    minLeadingWidth: 10,
                    minTileHeight: 10,
                    title: GestureDetector(
                        onLongPress: () {
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
                        child: Text(getDisplayText(text))),
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
                          : GestureDetector(
                              onLongPress: () {
                                selectAndCopyImageDialog(
                                  context,
                                );
                              },
                              child: Icon(Icons.image,
                                  size: 50, color: Colors.grey.shade400),
                            ),
                    ),
                    visualDensity: VisualDensity.compact,
                    dense: true,
                    onTap: () {
                      if (imageUrl != null && imageUrl.isNotEmpty) {
                        copyImageToClipboard(context, imageUrl);
                      }
                      _copyText(text);
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
              );
            }).toList(),
          ),
          isExpanded: isExpanded, // Global ya da yerel genişleme durumu
        ),
      ],
    );
  }
}
