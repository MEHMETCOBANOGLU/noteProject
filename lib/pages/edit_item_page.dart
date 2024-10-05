import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:json2yaml/json2yaml.dart';
import 'package:path_provider/path_provider.dart';
import 'package:proje1/model/items.dart';
import 'package:proje1/utility/list_box.dart';
import 'package:yaml/yaml.dart';

import '../data/database.dart';
import 'package:image/image.dart' as img; // For image manipulation

class EditItemPage extends StatefulWidget {
  final Item item;

  const EditItemPage({super.key, required this.item});

  @override
  _EditItemPageState createState() => _EditItemPageState();
}

class _EditItemPageState extends State<EditItemPage> {
  final TextEditingController _newOptionController = TextEditingController();
  late List<TextEditingController> _itemControllers;
  late TextEditingController _subtitleController;
  late TextEditingController _titleController;
  final ImagePicker _picker = ImagePicker();
  List<String?> _existingImagePaths = [];
  List<File?> _selectedImages = [];
  List<GlobalKey> _menuKeys = [];
  List<String> options = [];
  String? selectedOption;
  bool _isAddingNewOption = false;
  final SQLiteDatasource _sqliteDatasource = SQLiteDatasource();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.headerValue);
    _subtitleController = TextEditingController(text: widget.item.subtitle);
    _itemControllers = widget.item.expandedValue
        .map((item) => TextEditingController(text: item))
        .toList();
    _existingImagePaths = widget.item.imageUrls ?? [];
    _selectedImages = List<File?>.generate(
      _existingImagePaths.length,
      (index) => null,
      growable: true,
    );

    _menuKeys = List.generate(_itemControllers.length, (index) => GlobalKey());
    bool _isAddingNewOption = false;
    _loadOptionsFromDatabase();
  }

  //Seçenekler listboxu için veritabanından verileri yükler
  Future<void> _loadOptionsFromDatabase() async {
    List<String> dbOptions = await _sqliteDatasource.getOptions();
    setState(() {
      options = dbOptions;
      selectedOption = options.isNotEmpty ? options.first : null;
    });
  }

  //Tablodaki düzenlenen verileri kaydeder
  Future<void> _saveEditedTable() async {
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
          .showSnackBar(const SnackBar(content: Text('Tablo düzenlenemedi!')));
    }
  }

// Resimleri kalıcı olarak kaydetme fonksiyonu
  Future<String> _saveImagePermanently(File image) async {
    final directory = await getApplicationDocumentsDirectory(); // Kalıcı dizin
    final fileName = image.path.split('/').last; // Resim adını alıyoruz
    final newPath = '${directory.path}/$fileName'; // Kalıcı dosya yolu

    final savedImage =
        await image.copy(newPath); // Resmi yeni yola kopyalıyoruz
    return savedImage.path; // Kalıcı dosya yolunu döndürüyoruz
  }

  //itemler için resim seçme #resimseçmee,itemresimm

  Future<void> _pickImage(int index) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      File file = File(image.path);
      String savedImagePath =
          await _saveImagePermanently(file); // Resmi kalıcı kaydediyoruz

      setState(() {
        _selectedImages[index] =
            File(savedImagePath); // Kalıcı dosya yolunu kaydediyoruz
        _existingImagePaths[index] =
            savedImagePath; // Veritabanına kalıcı dosya yolunu ekleyin
      });
    }
  }

  bool isBase64(String? string) {
    if (string == null || string.isEmpty) return false;
    try {
      base64Decode(string);
      return true; // Eğer decode edebiliyorsak, geçerli bir Base64 verisidir
    } catch (e) {
      return false; // Base64 decode başarısız olursa, geçersizdir
    }
  }

// Resmi Base64 formatına çeviren fonksiyon
  Future<String?> _convertImageToBase64(String? imagePath) async {
    if (imagePath == null) return null;
    File imageFile = File(imagePath);
    if (await imageFile.exists()) {
      List<int> imageBytes = await imageFile.readAsBytes();
      return base64Encode(imageBytes);
    }
    return null;
  }

  Future<void> _copyAllToClipboard() async {
    var items = await Future.wait(_itemControllers.map((controller) async {
      int index = _itemControllers.indexOf(controller);
      String? base64Image;
      try {
        base64Image = await _convertImageToBase64(_existingImagePaths[index]);
      } catch (e) {
        print('Base64 dönüştürme hatası: $e');
        base64Image = null;
      }
      return {
        'text': controller.text,
        'image': base64Image,
      };
    }).toList());

    var dataMap = {
      'title': _titleController.text,
      'subtitle': _subtitleController.text,
      'items': items,
    };

    String yamlData = json2yaml(dataMap);
    Clipboard.setData(ClipboardData(text: yamlData));
    print("YAML kopyalandı: $yamlData");
  }

// Base64'ten resmi geçici bir dosya olarak kaydeden fonksiyon
  // Base64'ten resmi geçici bir dosya olarak kaydeden fonksiyon

// Base64'ten resmi geçici bir dosya olarak kaydeden fonksiyon
  Future<String> _convertBase64ToImage(String base64String, int index) async {
    Uint8List imageBytes = base64Decode(base64String); // Base64 çözme işlemi
    Directory tempDir = await getTemporaryDirectory();
    String filePath = '${tempDir.path}/image_$index.png';

    // Dosyayı yazıyoruz
    File file = File(filePath);
    await file.writeAsBytes(imageBytes);
    return filePath; // Geçici dosya yolunu geri döndürüyoruz
  }

  Future<void> _pasteAllFromClipboard() async {
    ClipboardData? data = await Clipboard.getData('text/plain');
    if (data != null) {
      try {
        var yamlMap = loadYaml(data.text!);

        String title = yamlMap['title'];
        String subtitle = yamlMap['subtitle'];
        List items = yamlMap['items'];

        List<String?> imagePaths = [];
        for (int i = 0; i < items.length; i++) {
          var item = items[i];
          if (item['image'] != null && isBase64(item['image'])) {
            try {
              String filePath = await _convertBase64ToImage(item['image'], i);
              imagePaths.add(filePath);
            } catch (e) {
              print('Base64 çözme hatası: $e');
              imagePaths.add(null);
            }
          } else {
            imagePaths.add(item['image']);
          }
        }

        setState(() {
          _titleController.text = title;
          _subtitleController.text = subtitle;
          _itemControllers.clear();
          _existingImagePaths.clear();
          _menuKeys.clear();

          for (int i = 0; i < items.length; i++) {
            var item = items[i];
            _itemControllers.add(TextEditingController(text: item['text']));
            _existingImagePaths.add(imagePaths[i]);
            _menuKeys.add(GlobalKey());
          }
        });
      } catch (e) {
        // Eğer YAML değilse Snackbar ile uyarı göster
        _showInvalidClipboardSnackbar();
      }
    } else {
      // Panoda veri yoksa Snackbar ile uyarı göster
      _showInvalidClipboardSnackbar();
    }
  }

// Panoda geçerli YAML yoksa Snackbar ile uyarı göster
  void _showInvalidClipboardSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
          content: Text('Panoda geçerli bir YAML verisi bulunamadı!')),
    );
  }

// listeye item ekleme #listeyeitemekleme
  void _addItemField() {
    setState(() {
      _itemControllers.add(TextEditingController());
      _existingImagePaths.add(null);

      // Yeni item için GlobalKey ekle
      if (_menuKeys.length < _itemControllers.length) {
        _menuKeys.add(GlobalKey());
      }
    });
  }

  //listeden item silme #listedenitemsilme
  void _removeItemField(int index) {
    setState(() {
      if (_itemControllers.length > 1) {
        _itemControllers.removeAt(index);
        _existingImagePaths.removeAt(index);

        // Silinen item için GlobalKey de kaldır
        if (_menuKeys.length > index) {
          _menuKeys.removeAt(index);
        }
      }
    });
  }

  //3 nokta ikonuna tıklandıgında açılan menu #3noktaikonmenüü,3noktaikonuu
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
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.list),
            title: const Text('Liste Kutusu'),
            onTap: () {
              Navigator.pop(context);
              showListBoxDialog(
                  context,
                  index,
                  _itemControllers,
                  options,
                  _newOptionController,
                  _isAddingNewOption,
                  setState,
                  _addNewOption, // Seçenek ekleme
                  _removeOption // Seçenek silme
                  );
            },
          ),
        ),
      ],
    );
  }

  //seçenekler listboxundan seçenek silme
  void _removeOption(int index) {
    setState(() {
      options.removeAt(index); // İlgili indeksteki elemanı sil
    });
  }

//seçenekler listboxuna yeni seçenek ekleme
  void _addNewOption(String value) async {
    if (value.isNotEmpty && !options.contains(value)) {
      setState(() {
        options.add(value);
        _newOptionController.clear();
        _isAddingNewOption = false;
      });

      await _sqliteDatasource.addOption(value);
    }
  }

  // düzenleme sayfasında tabloyu silme
  void _deleteTable(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tablo silinsin mi?',
              style:
                  TextStyle(fontStyle: FontStyle.italic, color: Colors.green)),
          content: Text(
              '${widget.item.headerValue} tablosunu silmek istediğinizden emin misiniz?'),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  child: const Text('İptal',
                      style: TextStyle(color: Colors.black)),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text(
                    'Sil',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _sqliteDatasource.deleteItem(widget.item.id);
      Navigator.pop(context, "deleted");
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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        shadowColor: Colors.green[10],
        surfaceTintColor: Colors.green[400],
        title: Center(child: Text(widget.item.headerValue)),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(Icons.delete_sweep,
                  color: Colors.red, size: 30), //çöpkutusuu,ikonn
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: ElevatedButton(
                      onPressed: _copyAllToClipboard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4.0), // Smaller padding
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(2.0)),
                        ),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Tümünü Kopyala',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    ),
                  ),
                  // const SizedBox(width: 2),
                  Flexible(
                    child: ElevatedButton(
                      onPressed: _pasteAllFromClipboard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4.0), // Smaller padding
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(2.0)),
                        ),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Tümünü Yapıştır',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 30),
                  Flexible(
                    child: ElevatedButton(
                      onPressed: _saveEditedTable,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4.0), // Smaller padding
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(2.0)),
                        ),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Kaydet',
                          style: TextStyle(
                              color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ),
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
              const SizedBox(height: 10),
              Expanded(
                child: ReorderableListView.builder(
                  itemCount: _itemControllers.length,
                  onReorder: (int oldIndex, int newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }
                      final controller = _itemControllers.removeAt(oldIndex);
                      final image = _selectedImages.removeAt(oldIndex);
                      final imagePath = _existingImagePaths.removeAt(oldIndex);
                      _itemControllers.insert(newIndex, controller);
                      _selectedImages.insert(newIndex, image);
                      _existingImagePaths.insert(newIndex, imagePath);
                    });
                  },
                  itemBuilder: (context, index) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      key: ValueKey(index),
                      // #Reorderablee,dragg,dropp
                      leading: ReorderableDragStartListener(
                        index: index,
                        child: const Icon(
                          Icons.drag_handle,
                          size: 20,
                        ),
                      ),
                      title: TextField(
                        key: _menuKeys[index],
                        controller: _itemControllers[index],
                        keyboardType: TextInputType.multiline,
                        minLines: 1,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Item ${index + 1}',
                          prefixIcon: (index < _existingImagePaths.length &&
                                  _existingImagePaths[index] != null &&
                                  _existingImagePaths[index]!.isNotEmpty)
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
                                  size: 50, color: Colors.grey.shade400),
                          suffixIcon: SizedBox(
                            width: 70,
                            height: 40,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 0,
                                  child: IconButton(
                                    icon: const Icon(Icons.more_vert_sharp),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      _showCustomMenu(
                                          context, index, _menuKeys[index]);
                                    },
                                  ),
                                ),
                                Positioned(
                                  left: 30,
                                  child: IconButton(
                                    icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.red),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
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
                    );
                  },
                ),
              ),
              // Add Item button outside of ReorderableListView
              GestureDetector(
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
                      Text("İtem Ekle", style: TextStyle(color: Colors.green)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
