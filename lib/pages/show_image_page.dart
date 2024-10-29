import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Tablify/aym/isimDilVeSecenek_duzenleyici.dart';
import 'package:Tablify/model/items.dart';

class ShowImage extends StatefulWidget {
  final List<String> imagePaths;
  final Item item;
  final int initialIndex;

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
  List<Image> loadedImages = [];

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentIndex);
    _preloadImages(); // Resimleri önceden yükle
  }

  // Resimleri belleğe yükler
  void _preloadImages() {
    for (var imagePath in widget.imagePaths) {
      loadedImages.add(Image.file(File(imagePath)));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _copyText(String text) async {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          duration: Duration(seconds: 1),
          content: Text('Metin panoya kopyalandı!')),
    );
  }

  //Resim kopyalama işlemi #copyimgg
  Future<void> _copyImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        final result = await platform
            .invokeMethod('copyImageToClipboard', {'path': imagePath});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              duration: Duration(seconds: 1),
              content: Text('Görsel panoya kopyalandı!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              duration: Duration(seconds: 1),
              backgroundColor: Colors.red,
              content: Text('Dosya mevcut değil!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.red,
            content: Text('Resim kopyalanırken hata oluştu: $e')),
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
        offset.dx,
        offset.dy,
        offset.dx,
        offset.dy,
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
        offset.dx,
        offset.dy,
        offset.dx,
        offset.dy,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
          highlightColor: Colors.green[50],
        ),
        title: Center(
          child: Text(
            widget.item.headerValue,
            style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(Icons.copy),

              //İsim, dil, seçenekler ve resimgibi bilgileri düzenleme sayfasına gonderme #aymm,isimaymm,seçenekaymm,dilaymm
              onPressed: () {
                String text = widget.item.expandedValue[currentIndex];
                int idx = currentIndex;
                print(text);
                print(idx);

                handleTapOnText(
                  context,
                  text,
                  idx,
                  widget.item,
                  () {
                    setState(() {});
                  },
                );
              },
            ),
          ),
        ],
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
                String? itemText = widget.item.expandedValue.length > index
                    ? widget.item.expandedValue[index]
                    : null;

                return ListView(
                  children: [
                    // Yüklenmiş resmi göster
                    Padding(
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
                            child: loadedImages[index],
                          ),
                        ),
                      ),
                    ),

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
          // Noktalar ve ok işaretleri bölümü
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
