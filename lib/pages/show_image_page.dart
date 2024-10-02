import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proje1/model/items.dart';

class ShowImage extends StatefulWidget {
  final List<String> imagePaths; // Tüm resim yolları
  final Item item;
  final int initialIndex; // Başlangıçta gösterilecek resmin indeksi

  const ShowImage({
    super.key,
    required this.imagePaths,
    required this.item,
    required this.initialIndex,
  });

  @override
  _ShowImageState createState() => _ShowImageState();
}

class _ShowImageState extends State<ShowImage> {
  late PageController _pageController;
  late int currentIndex;
  static const platform = MethodChannel('clipboard_image');

  @override
  void initState() {
    super.initState();
    currentIndex =
        widget.initialIndex; // Başlangıçta gösterilecek resim indeksi
    _pageController = PageController(initialPage: currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _copyText(String text) async {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Metin panoya kopyalandı!')),
    );
  }

  Future<void> _copyImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        final result = await platform
            .invokeMethod('copyImageToClipboard', {'path': imagePath});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Görsel panoya kopyalandı!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dosya mevcut değil!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resim kopyalanırken hata oluştu: $e')),
      );
    }
  }

  // Resim için özel menü
  void _showImageMenu(BuildContext context, int index, Offset offset) {
    showMenu(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx, // Left
        offset.dy, // Top
        offset.dx, // Right
        offset.dy, // Bottom
      ),
      items: [
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Resmi Kopyala'),
            onTap: () async {
              Navigator.pop(context);
              _copyImage(widget.imagePaths[index]);
            },
          ),
        ),
      ],
    );
  }

  // Metin için özel menü
  void _showTextMenu(BuildContext context, String? itemText, Offset offset) {
    if (itemText == null || itemText.isEmpty) return;

    showMenu(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx, // Left
        offset.dy, // Top
        offset.dx, // Right
        offset.dy, // Bottom
      ),
      items: [
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Metni Kopyala'),
            onTap: () async {
              Navigator.pop(context);
              _copyText(itemText);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // iconTheme: const IconThemeData(
        //   color: Colors.black,
        // ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
          // splashColor:
          //     Colors.green, // Tıklama sırasında görülen dalga efekti rengi
          highlightColor:
              Colors.green[50], // Tıklama sırasında açılacak dalga efekti rengi
          // color: Colors.black,
        ),
        title: Center(
            child: Text(
          widget.item.headerValue,
          style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic),
        )),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.imagePaths.length,
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                String imagePath = widget.imagePaths[index];
                String? itemText = widget.item.expandedValue.length > index
                    ? widget.item.expandedValue[index]
                    : null;

                return ListView(
                  children: [
                    // Resim Gösterimi
                    imagePath.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Container(
                                decoration: const BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 10,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: GestureDetector(
                                  onLongPressStart: (details) => _showImageMenu(
                                    context,
                                    index,
                                    details.globalPosition,
                                  ),
                                  child: Image.file(
                                    File(imagePath),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Center(child: const Icon(Icons.image, size: 400)),

                    // Resme ait metin
                    GestureDetector(
                      onLongPressStart: (details) => _showTextMenu(
                        context,
                        itemText,
                        details.globalPosition,
                      ),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        padding: const EdgeInsets.all(10),
                        width: double.infinity,
                        alignment: Alignment.topLeft,
                        child: itemText != null
                            ? Text(
                                itemText,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            : const Text(
                                'Metin bulunamadı',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Noktalar ve ok işaretleri bölümü, en alta alındı
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.imagePaths.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: currentIndex == index ? 12 : 8,
                  height: currentIndex == index ? 16 : 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentIndex == index
                        ? Colors.green
                        : Colors.green[100],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
