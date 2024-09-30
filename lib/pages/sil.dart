import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proje1/model/items.dart';

import '../data/database.dart';
import 'package:image/image.dart' as img; // For image manipulation

class EditItemPage extends StatefulWidget {
  final Item item;

  const EditItemPage({super.key, required this.item});

  @override
  _EditItemPageState createState() => _EditItemPageState();
}

class _EditItemPageState extends State<EditItemPage> {
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late List<TextEditingController> _itemControllers;
  final ImagePicker _picker = ImagePicker();
  List<File?> _selectedImages = [];
  List<String?> _existingImagePaths = []; // Dosya yollarını saklamak için liste
  List<GlobalKey> _menuKeys = [];

  final SQLiteDatasource _sqliteDatasource =
      SQLiteDatasource(); // SQLite veritabanı kullanımı

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.headerValue);
    _subtitleController = TextEditingController(text: widget.item.subtitle);
    _itemControllers = widget.item.expandedValue
        .map((item) => TextEditingController(text: item))
        .toList();
    _existingImagePaths =
        widget.item.imageUrls ?? []; // Resim yollarını saklıyoruz
    _selectedImages = List<File?>.generate(
      _existingImagePaths.length,
      (index) => null,
      growable: true,
    );

    _menuKeys = List.generate(_itemControllers.length, (index) => GlobalKey());
  }

  Future<void> _saveNote() async {
    List<String> items =
        _itemControllers.map((controller) => controller.text).toList();
    List<String> imagePaths = [];

    for (int i = 0; i < _selectedImages.length; i++) {
      if (_selectedImages[i] != null) {
        imagePaths.add(_selectedImages[i]!.path);
        _existingImagePaths[i] = _selectedImages[i]!.path;
      } else {
        imagePaths.add(_existingImagePaths[i]!);
      }
    }

    bool success = await _sqliteDatasource.updateNote(
      widget.item.id,
      _titleController.text,
      _subtitleController.text,
      items,
      imagePaths,
    );

    if (success) {
      Navigator.pop(context,
          "saved"); // Düzenleme başarılı olduğunda "saved" döndürüyoruz.
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to update note')));
    }
  }

  Future<void> _pickImage(int index) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      File file = File(image.path);

      setState(() {
        _selectedImages[index] =
            file; // Resim dosyasını seçip listeye ekliyoruz
        _existingImagePaths[index] = file.path; // Dosya yolunu güncelliyoruz
      });
    }
  }

  void _addItemField() {
    setState(() {
      _itemControllers.add(TextEditingController());
      _selectedImages.add(null); // Yeni resim placeholder'ı ekliyoruz
      _existingImagePaths.add(''); // Yeni öğe için boş dosya yolu ekliyoruz
      _menuKeys.add(GlobalKey()); // Yeni GlobalKey ekliyoruz
    });
  }

  void _removeItemField(int index) {
    if (index < _itemControllers.length) {
      setState(() {
        _itemControllers.removeAt(index);
        _selectedImages.removeAt(index);
        _existingImagePaths.removeAt(index);
        _menuKeys.removeAt(index); // GlobalKey'i de siliyoruz
      });
    }
  }

  void _showCustomMenu(BuildContext context, int index, GlobalKey key) {
    final RenderBox renderBox =
        key.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);

    showMenu(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx +
            renderBox.size.width, // Shift the menu to the right of the widget
        offset.dy + renderBox.size.height, // Position it below the widget
        offset
            .dx, // Adjust this to the left side of the screen for the "right" alignment
        offset.dy,
      ),
      items: [
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.photo),
            title: const Text('Resim Ekle'),
            onTap: () async {
              Navigator.pop(context);
              await _pickImage(index); // Resim seçme fonksiyonunu kullanıyoruz
            },
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.paste),
            title: const Text('Yapıştır'),
            onTap: () async {
              Navigator.pop(context);
              ClipboardData? data = await Clipboard.getData('text/plain');
              if (data != null) {
                setState(() {
                  _itemControllers[index].text = data.text ?? '';
                });
              }
            },
          ),
        ),
      ],
    );
  }

  void _deleteTable(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tablo silinsin mi?'),
          content: Text(
              '${widget.item.headerValue} tablosunu silmek istediğinizden emin misiniz?'),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal', style: TextStyle(color: Colors.black)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Sil',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _sqliteDatasource.deleteItem(widget.item.id);
      Navigator.pop(context,
          "deleted"); // Silme işlemi başarılı olduğunda "deleted" döndürüyoruz.
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Center(child: Text(widget.item.headerValue)),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.red, size: 30),
              onPressed: () async {
                _deleteTable(context);
              },
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _saveNote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(2.0)),
                      ),
                    ),
                    child: const Text(
                      'Düzenlemeleri Kaydet',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _titleController,
                keyboardType: TextInputType.multiline,
                minLines: 1,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Başlık',
                  hintStyle: TextStyle(fontStyle: FontStyle.italic),
                  icon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 40.0),
                child: TextField(
                  controller: _subtitleController,
                  keyboardType: TextInputType.multiline,
                  minLines: 1,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: 'Alt Başlık',
                    hintStyle: TextStyle(fontStyle: FontStyle.italic),
                    icon: Icon(Icons.subtitles),
                    isCollapsed: true,
                    isDense: true,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _itemControllers.length + 1,
                  itemBuilder: (context, index) {
                    if (index < _itemControllers.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                key: _menuKeys[index],
                                controller: _itemControllers[index],
                                keyboardType: TextInputType.multiline,
                                minLines: 1,
                                maxLines: null,
                                decoration: InputDecoration(
                                  hintText: 'Item ${index + 1}',
                                  prefixIcon: (index <
                                              _existingImagePaths.length &&
                                          _existingImagePaths[index] != null &&
                                          _existingImagePaths[index]!
                                              .isNotEmpty)
                                      ? Padding(
                                          padding: const EdgeInsets.only(
                                              right: 8.0, bottom: 8.0),
                                          child: Image.file(
                                            File(_existingImagePaths[index]!),
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(Icons.error),
                                          ),
                                        )
                                      : Icon(Icons.image,
                                          size: 50,
                                          color: Colors.grey.shade400),
                                  suffixIcon: SizedBox(
                                    width:
                                        70, // Ensures the Stack has a finite width
                                    height:
                                        40, // Ensures the Stack has a finite height
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          left:
                                              0, // First icon positioned at the start
                                          child: IconButton(
                                            icon: const Icon(
                                                Icons.more_vert_sharp),
                                            padding: EdgeInsets
                                                .zero, // No padding around the icon
                                            constraints:
                                                const BoxConstraints(), // No extra space constraints
                                            onPressed: () {
                                              _showCustomMenu(context, index,
                                                  _menuKeys[index]);
                                            },
                                          ),
                                        ),
                                        Positioned(
                                          left:
                                              30, // Position the second icon close to the first
                                          child: IconButton(
                                            icon: const Icon(
                                                Icons.remove_circle_outline,
                                                color: Colors.red),
                                            padding: EdgeInsets
                                                .zero, // No padding around the icon
                                            constraints:
                                                const BoxConstraints(), // No extra space constraints
                                            onPressed: () {
                                              _removeItemField(index);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return GestureDetector(
                        onTap: _addItemField,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, color: Colors.green),
                              SizedBox(width: 8),
                              Text("Add Item",
                                  style: TextStyle(color: Colors.green)),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
