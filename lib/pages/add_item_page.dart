import 'package:Tablify/pages/aym_guide_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Tablify/data/database.dart';
import 'package:json2yaml/json2yaml.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../utility/list_box.dart';
import 'package:yaml/yaml.dart';
import 'package:uuid/uuid.dart';
import '../model/items.dart';
import 'dart:convert';
import 'dart:io';

class AddItemPage extends StatefulWidget {
  const AddItemPage({super.key});

  @override
  _AddItemPageState createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();
  final List<TextEditingController> _itemControllers = [
    TextEditingController()
  ];
  final TextEditingController _newOptionController = TextEditingController();
  final SQLiteDatasource _sqliteDatasource = SQLiteDatasource();

  final ImagePicker _picker = ImagePicker();
  final List<String?> _imagePaths = [null];
  bool _isAddingNewOption = false;
  List<GlobalKey> _menuKeys = [];
  bool _isTitleEmpty = false;
  List<String> options = [];
  String? selectedOption;
  late List<FocusNode> _focusNodes;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _menuKeys = List.generate(_itemControllers.length, (index) => GlobalKey());
    _loadOptionsFromDatabase();

    _focusNodes =
        List.generate(_itemControllers.length, (index) => FocusNode());
  }

  // seçenekler veritabanından yüklenir
  Future<void> _loadOptionsFromDatabase() async {
    List<String> dbOptions = await _sqliteDatasource.getOptions();
    setState(() {
      options = dbOptions;
      selectedOption = options.isNotEmpty ? options.first : null;
    });
  }

  //yeni tablo ekler #yenitabloeklee
  Future<void> _addNewTable() async {
    setState(() {
      _isTitleEmpty = _titleController.text.isEmpty;
    });

    if (_titleController.text.isNotEmpty && _itemControllers.isNotEmpty) {
      List<String> items =
          _itemControllers.map((controller) => controller.text).toList();
      List<String> imagePaths = _imagePaths.map((path) => path ?? "").toList();

      bool noteExists =
          await _sqliteDatasource.noteExistsWithTitle(_titleController.text);

      if (noteExists) {
        bool overwriteConfirmed = await _showOverwriteDialog();

        if (!overwriteConfirmed) {
          return;
        }
      }

      bool success = await _sqliteDatasource.addOrUpdateNote(
        Item(
          id: const Uuid().v4(),
          headerValue: _titleController.text,
          subtitle: _subtitleController.text,
          expandedValue: items,
          imageUrls: imagePaths, // Dosya yolu kaydediliyor
        ),
      );

      if (success) {
        _titleController.clear();
        for (var controller in _itemControllers) {
          controller.clear();
        }
        _itemControllers.clear();
        Navigator.pop(context, true);
      } else {
        print("Error adding note");
      }
    }
  }

  // overwrite dialogu #overwritedialogg,aynbaşlıkmevcutt
  Future<bool> _showOverwriteDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text(
                'Aynı Başlık Mevcut',
                style:
                    TextStyle(fontStyle: FontStyle.italic, color: Colors.green),
              ),
              content: const Text(
                'Bu başlıkta zaten bir not mevcut. Üzerine yazmak ister misiniz?',
                style: TextStyle(fontSize: 16),
              ),
              actions: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      child: const Text(
                        'İptal',
                        style: TextStyle(color: Colors.black),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[50],
                      ),
                      child: const Text(
                        'Üzerine Yaz',
                        style: TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        ) ??
        false;
  }

// Resmi kalıcı olarak saklayan fonksiyon
  Future<String> _saveImagePermanently(File image) async {
    final directory = await getApplicationDocumentsDirectory(); // Kalıcı dizin
    final fileName = image.path.split('/').last; // Dosya adını alıyoruz
    final newPath = '${directory.path}/$fileName'; // Yeni dosya yolu

    final savedImage =
        await image.copy(newPath); // Resmi yeni yola kopyalıyoruz
    return savedImage.path; // Kalıcı dosya yolunu döndürüyoruz
  }

  //itemler için resim seçme #resimseçmee,itemresimm
  Future<void> _pickImage(int index) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      File file = File(image.path);

      String imagePath =
          await _saveImagePermanently(file); // Resmi kaydediyoruz
      print("Image path: $imagePath");

      setState(() {
        if (_imagePaths.length > index) {
          _imagePaths[index] = imagePath; // Kalıcı dosya yolunu kaydediyoruz
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    // Dispose all FocusNodes
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
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

  //Tablo ekleme sayfasındaki tümünü kopyala butonu #copyall,tümünükopyalaa
  void _copyAllToClipboard() async {
    var items = await Future.wait(_itemControllers.map((controller) async {
      int index = _itemControllers.indexOf(controller);
      // Base64 yerine dosya yolunu kopyalıyoruz
      return {
        'text': controller.text,
        'image': _imagePaths[index], // Resim dosya yolunu ekliyoruz
      };
    }).toList());

    var dataMap = {
      'title': _titleController.text,
      'subtitle': _subtitleController.text,
      'items': items,
    };

    String yamlData = json2yaml(dataMap);
    Clipboard.setData(ClipboardData(text: yamlData));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Veriler panoya başarıyla kopyalandı!'),
        duration: Duration(seconds: 2),
      ),
    );

    print(yamlData);
  }

// Base64'ten resmi geçici bir dosya olarak kaydeden fonksiyon
  Future<String> _convertBase64ToImage(String base64String, int index) async {
    Uint8List imageBytes = base64Decode(base64String); // Base64 çözme işlemi
    Directory tempDir = await getTemporaryDirectory();
    String filePath = '${tempDir.path}/image_$index.png';

    // Dosyayı yazıyoruz
    File file = File(filePath);
    await file.writeAsBytes(imageBytes);
    return filePath;
  }
  // Tablo ekleme sayfasındaki tümünü yapıştır butonu #pasteall,tümünüyapıştırr

  Future<void> _pasteAllFromClipboard() async {
    ClipboardData? data =
        await Clipboard.getData('text/plain'); // Panodan veri alınır
    if (data != null) {
      try {
        // Gelen metin YAML formatına dönüştürülüyor
        var yamlMap = loadYaml(data.text!);

        // Eğer geçerli YAML ise işlemi yap
        String title = yamlMap['title'];
        String subtitle =
            yamlMap['subtitle'] ?? ''; // Eğer boşsa "" olarak ayarlıyoruz
        List items = yamlMap['items'];

        List<String?> imagePaths = [];
        for (int i = 0; i < items.length; i++) {
          var item = items[i];
          if (item['image'] != null) {
            if (isBase64(item['image'])) {
              String filePath = await _convertBase64ToImage(item['image'], i);
              imagePaths.add(filePath);
            } else {
              imagePaths.add(item['image']);
            }
          } else {
            imagePaths.add(null);
          }
        }

        // Yapıştırma işlemini gerçekleştiriyoruz
        setState(() {
          _titleController.text = title;
          _subtitleController.text = subtitle; // Alt başlık buraya atanıyor

          _itemControllers.clear();
          _menuKeys.clear();
          _imagePaths.clear();

          for (int i = 0; i < items.length; i++) {
            var item = items[i];
            _itemControllers.add(TextEditingController(text: item['text']));
            _imagePaths.add(imagePaths[i]);
            _menuKeys.add(GlobalKey());
          }
        });

        // Yapıştırma işlemi başarılı olursa Snackbar ile bildirim göster
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
            content: Text('Veriler başarıyla yapıştırıldı!'),
          ),
        );
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
        content: Text('Panoda geçerli bir YAML verisi bulunamadı!'),
      ),
    );
  }

// listeye item ekleme #listeyeitemekleme
  void _addItemField() {
    setState(() {
      _itemControllers.add(TextEditingController());
      _imagePaths.add(null);

      // Add a new FocusNode for the new TextField
      _focusNodes.add(FocusNode());
      _focusNodes.last.requestFocus();

      // Yeni item için GlobalKey ekle
      if (_menuKeys.length < _itemControllers.length) {
        _menuKeys.add(GlobalKey());
      }
    });
  }

// listeden item silme #listedenitemsilme
  void _removeItemField(int index) {
    setState(() {
      if (_itemControllers.length > 1) {
        _itemControllers.removeAt(index);
        _imagePaths.removeAt(index);
        _focusNodes.removeAt(index);

        // Silinen item için GlobalKey de kaldır
        if (_menuKeys.length > index) {
          _menuKeys.removeAt(index);
        }
      }
    });
  }

// 3 nokta ikonuna tıklandıgında açılan menu #3noktaikonmenüü,3noktaikonuu
  void _showCustomMenu(BuildContext context, int index, GlobalKey key) {
    final RenderBox renderBox =
        key.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);

    showMenu(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + renderBox.size.height,
        offset.dx + renderBox.size.width,
        offset.dy,
      ),
      items: [
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.photo),
            title: const Text('Resim Ekle'),
            onTap: () async {
              Navigator.pop(context);
              await _pickImage(index);
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
                  _addNewOption,
                  _removeOption);
            },
          ),
        ),
      ],
    );
  }

  //seçenekler listboxundan seçenek silme
  void _removeOption(int index) {
    setState(() {
      options.removeAt(index);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        shadowColor: Colors.green[10],
        surfaceTintColor: Colors.green[400],
        title: const Center(child: Text('Yeni Tablo Ekle')),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AymGuidePage()),
              );
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.only(right: 10, left: 10, top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: ElevatedButton(
                        onPressed: _copyAllToClipboard,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(2.0)),
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
                    Flexible(
                      child: ElevatedButton(
                        onPressed: _pasteAllFromClipboard,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(2.0)),
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
                        onPressed: _addNewTable,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(2.0)),
                          ),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Ekle',
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                      ),
                    ),
                    // IconButton(
                    //   padding: EdgeInsets.zero,
                    //   onPressed: () {},
                    //   icon: const Icon(Icons.more_vert, color: Colors.green),
                    // ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: TextField(
                  controller: _titleController,
                  keyboardType: TextInputType.multiline,
                  minLines: 1,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'Başlık',
                    hintStyle: const TextStyle(fontStyle: FontStyle.italic),
                    icon: const Icon(Icons.title),
                    errorText: _isTitleEmpty ? 'Başlık boş bırakılamaz' : null,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 40.0, right: 10.0),
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
                child: Scrollbar(
                  radius: const Radius.circular(5.0),
                  scrollbarOrientation: ScrollbarOrientation.right,
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListView.builder(
                      controller: _scrollController,
                      shrinkWrap: true,
                      itemCount: _itemControllers.length,
                      itemBuilder: (context, index) {
                        if (_focusNodes.length <= index) {
                          _focusNodes.add(FocusNode()); // Add missing FocusNode
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _itemControllers[index],
                                  focusNode: _focusNodes[index],
                                  keyboardType: TextInputType.multiline,
                                  minLines: 1,
                                  maxLines: null,
                                  decoration: InputDecoration(
                                    hintText: 'Item ${index + 1}',
                                    prefixIcon: _imagePaths[index] != null
                                        ? Padding(
                                            padding: const EdgeInsets.only(
                                                right: 8.0, bottom: 3.0),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(3.0),
                                              child: Image.file(
                                                File(_imagePaths[index]!),
                                                width: 50,
                                                height: 50,
                                              ),
                                            ),
                                          )
                                        : IconButton(
                                            padding: EdgeInsets.zero,
                                            onPressed: () => _pickImage(index),
                                            icon: Icon(Icons.image,
                                                size: 50,
                                                color: Colors.grey.shade400),
                                          ),
                                    suffixIcon: SizedBox(
                                      width: 70,
                                      height: 40,
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            left: 0,
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              key: _menuKeys[index],
                                              icon: const Icon(
                                                  Icons.more_vert_sharp),
                                              onPressed: () => _showCustomMenu(
                                                context,
                                                index,
                                                _menuKeys[index],
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            left: 30,
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              icon: const Icon(
                                                  Icons.remove_circle_outline,
                                                  color: Colors.red),
                                              onPressed: () =>
                                                  _removeItemField(index),
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
                      },
                    ),
                  ),
                ),
              ),
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
                      Text('Item Ekle', style: TextStyle(color: Colors.green)),
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
