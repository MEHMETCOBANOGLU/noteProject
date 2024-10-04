import 'dart:convert';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proje1/data/database.dart';
import 'package:proje1/pages/aym_guide_page.dart';
import 'package:uuid/uuid.dart';
import '../model/items.dart';
import '../utility/list_box.dart';

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

  @override
  void initState() {
    super.initState();
    _menuKeys = List.generate(_itemControllers.length, (index) => GlobalKey());
    _loadOptionsFromDatabase();
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
          imageUrls: imagePaths,
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
              title: const Text('Aynı Başlık Mevcut'),
              content: const Text(
                  'Bu başlıkta zaten bir not mevcut. Üzerine yazmak ister misiniz?'),
              actions: <Widget>[
                TextButton(
                  child: const Text(
                    'İptal',
                    style: TextStyle(color: Colors.black),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: const Text('Üzerine Yaz',
                      style: TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }

  //itemler için resim seçme #resimseçmee,itemresimm
  Future<void> _pickImage(int index) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      File file = File(image.path);

      String imagePath = file.path;

      if (_imagePaths.length > index) {
        setState(() {
          _imagePaths[index] = imagePath;
        });
      }
    }
  }

//listeye item ekleme #listeyeitemekleme
  void _addItemField() {
    setState(() {
      _itemControllers.add(TextEditingController());
      _imagePaths.add(null);
      _menuKeys.add(GlobalKey());
    });
  }

  //listeden item silme #listedenitemsilme
  void _removeItemField(int index) {
    setState(() {
      if (_itemControllers.length > 1) {
        _itemControllers.removeAt(index);
        _imagePaths.removeAt(index);
        _menuKeys.removeAt(index);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
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
            icon: const Icon(Icons.info_outline), //info ikonu
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
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _addNewTable,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(2.0)),
                      ),
                    ),
                    child: const Text(
                      'Ekle',
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
                decoration: InputDecoration(
                  hintText: 'Başlık',
                  hintStyle: const TextStyle(fontStyle: FontStyle.italic),
                  icon: const Icon(Icons.title),
                  errorText: _isTitleEmpty ? 'Başlık boş bırakılamaz' : null,
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
                  itemCount:
                      _itemControllers.length + 1, // +1 for the add button
                  itemBuilder: (context, index) {
                    if (index < _itemControllers.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _itemControllers[index],
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
                                      : Icon(
                                          Icons
                                              .image, //resim ikonu #resimikonuu
                                          size: 50,
                                          color: Colors.grey.shade400),
                                  suffixIcon: SizedBox(
                                    width: 70,
                                    height: 40,
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          left: 0,
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            key: _menuKeys[index],
                                            icon: const Icon(Icons
                                                .more_vert_sharp), //3 nokta ikonu #3noktaikonuu
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
                                            constraints: const BoxConstraints(),
                                            icon: const Icon(
                                                Icons
                                                    .remove_circle_outline, //item silme ikonu
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
                              Text('Add Item',
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
