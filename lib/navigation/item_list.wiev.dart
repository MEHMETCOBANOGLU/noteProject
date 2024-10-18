import 'package:Tablify/data/database.dart';
import 'package:Tablify/utility/%C4%B0tem_edit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Tablify/aym/isimDilVeSecenek_duzenleyici.dart';
import 'dart:io';
import 'package:Tablify/model/items.dart';
import 'package:Tablify/pages/show_image_page.dart';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _picker = ImagePicker();
  final SQLiteDatasource _sqliteDatasource = SQLiteDatasource();

  late List<TextEditingController> _itemControllers;
  List<String?> _existingImagePaths = [];
  List<File?> _selectedImages = [];
  List<GlobalKey> _menuKeys = [];
  List<FocusNode> _focusNodes = [];
  late TextEditingController _subtitleController;
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _initializeLists();
  }

  @override
  void didUpdateWidget(covariant ListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.expandedValue.length !=
            widget.item.expandedValue.length ||
        oldWidget.item.expandedValue != widget.item.expandedValue) {
      _updateLists();
    }
  }

  void _initializeLists() {
    isLocalExpanded = widget.item.isExpanded;

    _titleController = TextEditingController(text: widget.item.headerValue);
    _subtitleController = TextEditingController(text: widget.item.subtitle);
    _itemControllers = widget.item.expandedValue
        .map((item) => TextEditingController(text: item))
        .toList();

    _existingImagePaths = List<String?>.generate(
        widget.item.expandedValue.length,
        (index) => widget.item.imageUrls != null &&
                widget.item.imageUrls!.length > index
            ? widget.item.imageUrls![index]
            : null);

    _selectedImages =
        List<File?>.generate(widget.item.expandedValue.length, (index) => null);

    _menuKeys = List.generate(_itemControllers.length, (index) => GlobalKey());

    _focusNodes =
        List.generate(_itemControllers.length, (index) => FocusNode());
  }

  void _updateLists() {
    // Update _itemControllers
    _itemControllers = widget.item.expandedValue
        .map((item) => TextEditingController(text: item))
        .toList();

    // Update _existingImagePaths
    _existingImagePaths = List<String?>.generate(
        widget.item.expandedValue.length,
        (index) => widget.item.imageUrls != null &&
                widget.item.imageUrls!.length > index
            ? widget.item.imageUrls![index]
            : null);

    // Update _selectedImages
    _selectedImages =
        List<File?>.generate(widget.item.expandedValue.length, (index) => null);

    // Synchronize _menuKeys
    if (_menuKeys.length < _itemControllers.length) {
      _menuKeys.addAll(List.generate(
          _itemControllers.length - _menuKeys.length, (index) => GlobalKey()));
    } else if (_menuKeys.length > _itemControllers.length) {
      _menuKeys = _menuKeys.sublist(0, _itemControllers.length);
    }

    // Synchronize _focusNodes
    if (_focusNodes.length < _itemControllers.length) {
      _focusNodes.addAll(List.generate(
          _itemControllers.length - _focusNodes.length,
          (index) => FocusNode()));
    } else if (_focusNodes.length > _itemControllers.length) {
      for (int i = widget.item.expandedValue.length;
          i < _focusNodes.length;
          i++) {
        _focusNodes[i].dispose();
      }
      _focusNodes = _focusNodes.sublist(0, _itemControllers.length);
    }

    setState(() {}); // Trigger a rebuild with updated lists
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }

    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }

    super.dispose();
  }

  // Metni panoya kopyalayan fonksiyon #kopyalamaa,textkopyalamaa
  Future<void> _copyText(String text) async {
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
    // _menuKeys listesini _itemControllers listesinin uzunluğuna göre senkronize et
    // Ensure all lists are synchronized with _itemControllers
    // (This might be redundant if handled in didUpdateWidget)
    if (_menuKeys.length < _itemControllers.length) {
      _menuKeys.addAll(List.generate(
          _itemControllers.length - _menuKeys.length, (index) => GlobalKey()));
    } else if (_menuKeys.length > _itemControllers.length) {
      _menuKeys = _menuKeys.sublist(0, _itemControllers.length);
    }

    bool isExpanded = widget.isGlobalExpanded || widget.isLocalExpanded;

    return ExpansionPanelList(
      expansionCallback: (int index, bool expanded) {
        setState(() {
          isLocalExpanded = !isExpanded;
          widget.onExpandedChanged(isLocalExpanded);
        });
      },
      children: [
        ExpansionPanel(
          hasIcon: false,
          canTapOnHeader: true,
          headerBuilder: (BuildContext context, bool expanded) {
            return Stack(
              children: [
                // Main header content
                Container(
                  color: Colors.green[50],
                  child: Row(
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
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.edit_note_rounded),
                        onPressed: () {
                          _navigateAndEditItem(context, widget.item);
                        },
                      ),
                      IconButton(
                        color: Colors.grey,
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                        ),
                        onPressed: () {
                          setState(() {
                            isLocalExpanded = !isExpanded;
                            widget.onExpandedChanged(isLocalExpanded);
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 1,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.item.expandedValue.length}',
                      style:
                          const TextStyle(fontSize: 12.0, color: Colors.white),
                    ),
                  ),
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

              return GestureDetector(
                // İsim, dil, seçenekler ve resim gibi bilgileri düzenleme sayfasına gönderme
                onTap: () {
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
                // Uzun basıldığında resmi ve texti panoya kopyalama
                onLongPress: () {
                  if (imageUrl != null && imageUrl.isNotEmpty) {
                    copyImageToClipboard(context, imageUrl);
                  }
                  _copyText(text);
                },
                // item edit penceresine yönlendirme
                onHorizontalDragStart: (DragStartDetails details) {
                  if (idx < _menuKeys.length) {
                    showCustomEditMenu(
                      context,
                      idx,
                      _menuKeys[idx],
                      text,
                      _picker,
                      _selectedImages,
                      _existingImagePaths,
                      imageUrl,
                      _itemControllers,
                      setState,
                      _menuKeys, // Pass _menuKeys
                      _focusNodes, // Pass _focusNodes
                      _sqliteDatasource, // Pass _sqliteDatasource
                      widget.item, // Pass widget.item
                      widget.onTableEdited, // Pass the callback directly
                      _titleController,
                      _subtitleController,
                    );
                  } else {
                    // Hata durumunda yapılacak işlemler
                    print('Invalid index for _menuKeys: $idx');
                  }
                },
                child: Column(
                  children: [
                    ListTile(
                      focusColor: Colors.green[50],
                      hoverColor: Colors.green[50],
                      splashColor: Colors.green[50],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 5.0,
                      ),
                      title: GestureDetector(
                        child: getColoredDisplayText(text),
                      ),
                      leading: imageUrl != null &&
                              imageUrl.isNotEmpty &&
                              File(imageUrl).existsSync()
                          ? GestureDetector(
                              onTap: () {
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
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3.0),
                                child: Image.file(
                                  File(imageUrl),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          : null,
                      visualDensity: VisualDensity.compact,
                      dense: true,
                    ),
                    if (widget.item.expandedValue.length > 1 &&
                        idx < widget.item.expandedValue.length - 1)
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Colors.grey[300],
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
