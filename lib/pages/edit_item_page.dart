import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Tablify/utility/list_box.dart';
import 'package:json2yaml/json2yaml.dart';
import 'package:Tablify/model/items.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:yaml/yaml.dart';
import '../data/database.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

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
  late List<FocusNode> _focusNodes;
  final ImagePicker _picker = ImagePicker();
  List<String?> _existingImagePaths = [];
  List<File?> _selectedImages = [];
  List<GlobalKey> _menuKeys = [];
  final GlobalKey _moreVertKey = GlobalKey();
  List<String> options = [];
  String? selectedOption;
  bool _isAddingNewOption = false;
  final SQLiteDatasource _sqliteDatasource = SQLiteDatasource();
  final ScrollController _scrollController =
      ScrollController(); // ScrollController

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

    if (_itemControllers.length > _selectedImages.length) {
      for (int i = _selectedImages.length; i < _itemControllers.length; i++) {
        _selectedImages.add(null);
      }
    }
    if (_itemControllers.length > _existingImagePaths.length) {
      for (int i = _existingImagePaths.length;
          i < _itemControllers.length;
          i++) {
        _existingImagePaths.add("");
      }
    }

    _menuKeys = List.generate(_itemControllers.length, (index) => GlobalKey());
    _loadOptionsFromDatabase();
    _focusNodes =
        List.generate(_itemControllers.length, (index) => FocusNode());
  }

  //Seçenekler listboxu için veritabanından verileri yükler #listboxx
  Future<void> _loadOptionsFromDatabase() async {
    List<String> dbOptions = await _sqliteDatasource.getOptions();
    setState(() {
      options = dbOptions;
      selectedOption = options.isNotEmpty ? options.first : null;
    });
  }

  //Tablodaki düzenlenen verileri kaydeder #kaydett,savee
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

    bool success = await _sqliteDatasource.addOrUpdateNote(
      Item(
        id: widget.item.id, // Mevcut id'yi kullanın
        headerValue: _titleController.text,
        subtitle: _subtitleController.text,
        expandedValue: items,
        imageUrls: imagePaths,
        tabId: widget.item.tabId,
      ),
    );

    if (success) {
      Navigator.pop(context, "saved");
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Tablo düzenlenemedi!')));
    }
  }

  // Düzenleme sayfasındaki tümünü kopyala butonu #copyall,tümünükopyalaa
  Future<void> _copyAllToClipboard() async {
    // _existingImagePaths listesinin uzunluğunu kontrol edip senkronize ediyoruz
    if (_existingImagePaths.length < _itemControllers.length) {
      for (int i = _existingImagePaths.length;
          i < _itemControllers.length;
          i++) {
        _existingImagePaths.add("");
      }
    }

    var items = _itemControllers.asMap().entries.map((entry) {
      int index = entry.key;
      TextEditingController controller = entry.value;

      Map<String, dynamic> itemData = {'text': controller.text};

      itemData['image'] = _existingImagePaths[index] ?? '';

      return itemData;
    }).toList();

    var dataMap = {
      'title': _titleController.text,
      'subtitle':
          _subtitleController.text.isNotEmpty ? _subtitleController.text : '',
      'items': items,
    };

    String yamlData = json2yaml(dataMap);

    //Tümünü kopyalama işlemi için yaml önizlemesi pnceresi #yamll
    await _showYamlPreviewDialog(
      title: 'YAML Önizlemesi',
      content: yamlData,
      actionLabel: 'Kopyala',
      onActionPressed: () async {
        Clipboard.setData(ClipboardData(text: yamlData));
        Navigator.of(context).pop(); // Dialogu kapat
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
            content: Text('Veriler başarıyla panoya kopyalandı!'),
          ),
        );
      },
    );
  }

  // Düzenleme sayfasındaki tümünü yapıştır butonu #pasteall,tümünüyapıştırr
  Future<void> _pasteAllFromClipboard() async {
    ClipboardData? data = await Clipboard.getData('text/plain');

    if (data == null || data.text == null || data.text!.isEmpty) {
      print("Panoda geçerli veri yok.");
      _showInvalidClipboardSnackbar();
      return;
    }

    String yamlText = data.text!;
    bool hasMissingImages = false; // Eksik resim uyarısı için flag

    try {
      var yamlMap = loadYaml(yamlText);
      print("YAML başarıyla yüklendi: $yamlMap");

      // YAML'dan alınan verileri işleme
      String title = yamlMap['title'];
      String? subtitle = yamlMap['subtitle'] ?? '';
      List items = yamlMap['items'];

      List<String?> imagePaths = [];
      List<String> texts = [];

      for (var item in items) {
        texts.add(item['text'] ?? '');

        // Resim kontrolü
        if (item['image'] != null && item['image'].isNotEmpty) {
          File imageFile = File(item['image']);
          if (await imageFile.exists()) {
            imagePaths.add(item['image']);
          } else {
            imagePaths.add(null); // Resim bulunamazsa null olarak ekle
            if (!hasMissingImages) {
              hasMissingImages = true; // Uyarı göstermek için flag ayarla
            }
          }
        } else {
          imagePaths.add(null);
        }
      }

      // Eğer eksik resimler varsa uyarıyı bir kez göster
      if (hasMissingImages) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Bazı resimler bulunamadı'),
          backgroundColor: Colors.red,
        ));
      }

      await _showYamlPreviewDialog(
        title: 'YAML Önizlemesi',
        content: yamlText,
        actionLabel: 'Yapıştır',
        onActionPressed: () {
          setState(() {
            _titleController.text = title;
            _subtitleController.text = subtitle ?? '';

            _itemControllers.clear();
            _existingImagePaths.clear();
            _selectedImages.clear();
            _menuKeys.clear();
            _focusNodes.clear();

            for (int i = 0; i < texts.length; i++) {
              _itemControllers.add(TextEditingController(text: texts[i]));
              _existingImagePaths.add(
                  imagePaths[i] ?? ''); // Eğer null ise boş string atıyoruz
              _selectedImages.add(
                imagePaths[i] != null ? File(imagePaths[i]!) : null,
              );
              _menuKeys.add(GlobalKey());
              _focusNodes.add(FocusNode());
            }
          });

          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
              content: Text('Veriler başarıyla yapıştırıldı!'),
            ),
          );
        },
      );
    } catch (e) {
      print("YAML yüklenemedi: $e");
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

  //Yaml önizlemesi pnceresi #yamll
  Future<void> _showYamlPreviewDialog({
    required String title,
    required String content,
    required String actionLabel,
    required VoidCallback onActionPressed,
  }) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(child: Text(title)),
          content: SingleChildScrollView(
            child: SelectableText(
              content,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  child: const Text('İptal',
                      style: TextStyle(color: Colors.black)),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                ElevatedButton(
                  onPressed: onActionPressed,
                  child: Text(actionLabel,
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Resimleri kalıcı olarak kaydetme fonksiyonu1
  Future<String> _saveImagePermanently(File image) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = path.basename(image.path);
    final newPath = path.join(directory.path, fileName);

    final savedImage = await image.copy(newPath);
    return savedImage.path;
  }

  //Resim seçme fonksiyonu #resimm,img,resimseçmee
  Future<void> _pickImage(int index) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      File file = File(image.path);
      String savedImagePath =
          await _saveImagePermanently(file); // Resmi kalıcı kaydediyoruz
      print("Resim kaydedildi: $savedImagePath");

      setState(() {
        _selectedImages[index] = File(savedImagePath);
        _existingImagePaths[index] = savedImagePath;
      });
    }
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

// listeye item ekleme  fonksiyonu #itemeklee
  void _addItemField() {
    setState(() {
      _itemControllers.add(TextEditingController());
      _existingImagePaths.add("");
      _selectedImages.add(null);
      _focusNodes.add(FocusNode());
      _menuKeys.add(GlobalKey());
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _focusNodes.last.requestFocus();
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  //listeden item silme #listedenitemsilme #itemsilmee
  void _removeItemField(int index) async {
    // Eğer metin veya görsel yoksa doğrudan sil
    if (_itemControllers[index].text.isEmpty &&
        (_existingImagePaths[index] == null ||
            _existingImagePaths[index]!.isEmpty)) {
      await _sqliteDatasource.deleteItem(widget.item.id, index);

      setState(() {
        _itemControllers.removeAt(index);
        _existingImagePaths.removeAt(index);
        _selectedImages.removeAt(index);
        _menuKeys.removeAt(index);
        _focusNodes.removeAt(index);
      });
    } else {
      // Metin veya görsel varsa onay almak için dialog göster
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('İtemi silmek istediğinize emin misiniz?'),
            content: const Text('Bu işlem geri alınamaz.'),
            actions: <Widget>[
              TextButton(
                child: const Text('İptal'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Sil', style: TextStyle(color: Colors.white)),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (confirm == true) {
        await _sqliteDatasource.deleteItem(widget.item.id, index);

        setState(() {
          _itemControllers.removeAt(index);
          _existingImagePaths.removeAt(index);
          _selectedImages.removeAt(index);
          _menuKeys.removeAt(index);
          _focusNodes.removeAt(index);
        });

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

        bool success = await _sqliteDatasource.addOrUpdateNote(
          Item(
            id: const Uuid().v4(),
            headerValue: _titleController.text,
            subtitle: _subtitleController.text,
            expandedValue: items,
            imageUrls: imagePaths,
            tabId: widget.item.tabId,
          ),
        );
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('İtem başarıyla silindi!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  //Düzenleme sayfasında tabloyu silme #deletetablee,sill
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
      await _sqliteDatasource.deleteTable(widget.item.id);
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

    // Dispose all FocusNodes
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }

    super.dispose();
  }

  // Kaydet butonu yanındaki 3 noktaya basınca açılan "Tabloyu Klonla" menüsü #3noktaa,klonn
  void _showCloneMenu(BuildContext context, GlobalKey key) {
    final RenderBox renderBox =
        key.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + renderBox.size.height,
        offset.dx + renderBox.size.width,
        offset.dy,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      items: [
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Tabloyu klonla'),
            onTap: () async {
              Navigator.pop(context);
              await _cloneTable();
            },
          ),
        ),
      ],
    );
  }

// Tabloyu klonlamak için kullanılan fonksiyon
  Future<void> _cloneTable() async {
    var uuid = const Uuid().v4();
    String clonedTitle = await _getClonedTitle(_titleController.text);
    print(_existingImagePaths);

    //klonlanan tablo için yeni ıtem oluşturma işlemi
    Item clonedItem = Item(
      id: uuid,
      headerValue: clonedTitle,
      subtitle: _subtitleController.text,
      expandedValue:
          _itemControllers.map((controller) => controller.text).toList(),
      imageUrls: List<String>.from(_existingImagePaths),
      isExpanded: false,
      tabId: widget.item.tabId,
    );

    bool success = await _sqliteDatasource.addOrUpdateNote(clonedItem);

    if (success) {
      Navigator.pop(context, "pop");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$clonedTitle Tablosu başarıyla klonlandı!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tablo klonlanamadı!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

//Klonlaanan tablolar için title üretme
  Future<String> _getClonedTitle(String originalTitle) async {
    // Veritabanından mevcut öğeleri alın
    List<Item> existingItems =
        await _sqliteDatasource.getNotes(widget.item.tabId);
    String clonedTitle;
    String baseName = originalTitle;

    // İlk kopyalama için varsayılan ek
    String copySuffix = ' - Kopya';

    // İlk olarak, "baseName + copySuffix" adının mevcut olup olmadığını kontrol edin
    clonedTitle = '$baseName$copySuffix';

    int copyNumber = 2;

    // Eğer aynı isimde bir dosya varsa, numaralandırmayı artırın
    while (existingItems.any((item) => item.headerValue == clonedTitle)) {
      clonedTitle = '$baseName$copySuffix ($copyNumber)';
      copyNumber++;
    }

    return clonedTitle;
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
        offset.dx + renderBox.size.width,
        offset.dy + renderBox.size.height,
        offset.dx,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        shadowColor: Colors.green[10],
        surfaceTintColor: Colors.green[400],
        title: Center(
          child: Text(widget.item.headerValue),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop("pop");
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(Icons.delete_sweep,
                  color: Colors.red, size: 30), //çöpkutusuu,sill
              onPressed: () async {
                _deleteTable(context);
              },
            ),
          ),
        ],
      ),
      body: GestureDetector(
        child: Padding(
          padding: const EdgeInsets.only(right: 10, left: 10, top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
                  IconButton(
                    key: _moreVertKey,
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      _showCloneMenu(context, _moreVertKey);
                      // _cloneTable();
                    },
                    icon: const Icon(Icons.more_vert, color: Colors.green),
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
                  hintText: 'Başlık', //#başlıkk
                  hintStyle: TextStyle(fontStyle: FontStyle.italic),
                  icon: Icon(Icons.title),
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
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
                    hintText: 'Alt Başlık', //#altbaşlıkk
                    hintStyle: TextStyle(fontStyle: FontStyle.italic),
                    icon: Icon(Icons.subtitles),
                    isCollapsed: true,
                    isDense: true,
                  ),
                  style: const TextStyle(
                    color: Colors.black45,
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
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ReorderableListView.builder(
                      scrollController: _scrollController,
                      itemCount: _itemControllers.length,
                      onReorder: (int oldIndex, int newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }

                          final controller =
                              _itemControllers.removeAt(oldIndex);
                          final image = _selectedImages.removeAt(oldIndex);
                          final imagePath =
                              _existingImagePaths.removeAt(oldIndex);

                          _itemControllers.insert(newIndex, controller);
                          _selectedImages.insert(newIndex, image);
                          _existingImagePaths.insert(newIndex, imagePath);
                        });
                      },
                      itemBuilder: (context, index) {
                        if (_focusNodes.length <= index) {
                          _focusNodes.add(FocusNode());
                        }

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          key: ValueKey(index),
                          //Liste sıra değiştirme #Reorderablee,dragg,dropp
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
                            focusNode: _focusNodes[index],
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
                                        icon: const Icon(Icons.more_vert_sharp),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        // key: _menuKeys[index],
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
                      Text("Item Ekle", style: TextStyle(color: Colors.green)),
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
