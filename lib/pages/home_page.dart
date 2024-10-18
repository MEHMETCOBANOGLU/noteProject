//////////////////////////////////////////////2///////////
library;

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:motion_tab_bar/MotionTabBar.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:Tablify/data/database.dart';
import 'package:Tablify/model/items.dart';
import 'package:Tablify/pages/add_item_page.dart';
import 'package:reorderables/reorderables.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../model/TabItem.dart';
import '../navigation/item_list.wiev.dart';
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:archive/archive_io.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../utility/export_operations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class TabData {
  List<Item> data;
  Map<String, bool> localExpandedStates;
  bool allExpanded;

  TabData({
    required this.data,
    required this.localExpandedStates,
    required this.allExpanded,
  });
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final SQLiteDatasource _sqliteDatasource = SQLiteDatasource();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final bool _allExpanded = true;
  final List<Item> _data = [];
  final Map<String, bool> _localExpandedStates = {};
  final int _selectedIndexTab = 0;

  List<TabItem> _tabs = [];
  late TabController _tabController;
  List<TabData> _tabDataList = [];
  bool _isLoading = true;

  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();

  List<ScrollController> _scrollControllers = [];

  @override
  void initState() {
    super.initState();
    _loadTabs();
    _scrollControllers = [];
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _tabController.dispose();
    for (var controller in _scrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      // The UI will rebuild and apply the search filter
    });
  }

  // _loadTabs fonksiyonunun güncellenmiş hali
  Future<void> _loadTabs() async {
    await _sqliteDatasource.init();
    List<TabItem> tabs = await _sqliteDatasource.getTabs();

    setState(() {
      if (tabs.isEmpty) {
        // Varsayılan 'Tab 1' oluştur
        String id = 'tab1';
        String name = 'Tab 1';
        TabItem tabItem = TabItem(id: id, name: name, order: 0);
        _tabs = [tabItem];
        _sqliteDatasource.addTab(tabItem);
      } else {
        // Sekmeleri 'order' alanına göre sıralıyoruz
        tabs.sort((a, b) => a.order.compareTo(b.order));
        _tabs = tabs;
      }

      _tabDataList = List.generate(_tabs.length, (index) {
        return TabData(data: [], localExpandedStates: {}, allExpanded: true);
      });

      // TabController'ı başlatıyoruz
      _tabController = TabController(length: _tabs.length, vsync: this);
      _loadData(_tabController.index);

      // TabController dinleyicisini ekliyoruz
      _tabController.addListener(() {
        if (_tabController.indexIsChanging) {
          if (_tabController.index == _tabs.length) {
            // '+' butonuna tıklandı, yeni sekme ekle
            _addNewTab();
          } else {
            _loadData(_tabController.index);
            setState(() {}); // Sekme vurgusunu güncelle
          }
        } else {
          // Kullanıcı sekmeler arasında kaydırma yaptı
          if (_tabController.index < _tabs.length) {
            _loadData(_tabController.index);
            setState(() {}); // Sekme vurgusunu güncelle
          }
        }
      });

      _isLoading = false; // Başlatma tamamlandı

      _scrollControllers =
          List.generate(_tabs.length, (index) => ScrollController());
    });
  }

  void _closeTab(int index) async {
    TabItem tabItem = _tabs[index];
    List<Item> data = _tabDataList[index].data;

    if (data.isNotEmpty) {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sekmeyi Kapat'),
          content: const Text(
              'Bu sekmeyi kapatmak ve içindeki tüm verileri silmek istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              child: const Text('İptal', style: TextStyle(color: Colors.black)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Sil', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    // Verileri sil
    await _sqliteDatasource.deleteItemsByTabId(tabItem.id);
    await _sqliteDatasource.deleteTab(tabItem.id);

    setState(() {
      _tabs.removeAt(index);
      _tabDataList.removeAt(index);

      // İlgili ScrollController'ı kaldır ve serbest bırak
      _scrollControllers[index].dispose();
      _scrollControllers.removeAt(index);

      // Yeni seçili index'i belirliyoruz
      int currentIndex = _tabController.index;
      if (currentIndex >= _tabs.length) {
        currentIndex = _tabs.length - 1;
        if (currentIndex < 0) currentIndex = 0;
      }

      if (_tabs.isEmpty) {
        // Tüm sekmeler kapatılmışsa varsayılan 'Tab 1' ekliyoruz
        String id = 'tab1';
        String name = 'Tab 1';
        TabItem tabItem = TabItem(id: id, name: name, order: 0);
        _tabs.add(tabItem);
        _tabDataList
            .add(TabData(data: [], localExpandedStates: {}, allExpanded: true));
        _sqliteDatasource.addTab(tabItem);
        _scrollControllers
            .add(ScrollController()); // Yeni ScrollController ekleniyor
      }

      // TabController'ı güncelliyoruz
      _updateTabController(initialIndex: currentIndex);
    });

    // Yeni seçili sekmeye geçiş yapıyoruz
    _tabController.index = _selectedIndexTab;
  }

  // Preserving state across hot reload
  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_tabController.length != _tabs.length) {
      _tabController.removeListener(_tabControllerListener);
      _tabController.dispose();
      _tabController = TabController(
        length: _tabs.length,
        vsync: this,
        initialIndex: _tabController.index.clamp(0, _tabs.length - 1),
      );
      _tabController.addListener(_tabControllerListener);
      setState(() {});
    }
  }

  void _tabControllerListener() {
    if (_tabController.indexIsChanging) {
      _loadData(_tabController.index);
    }
  }

  // SQLite'dan veriyi yüklüyoruz #dbb
  Future<void> _loadData(int index) async {
    String tabId = _tabs[index].id;
    List<Item> items = await _sqliteDatasource.getNotes(tabId);
    setState(() {
      _tabDataList[index].data = items;
      _tabDataList[index].localExpandedStates = {
        for (var item in items) item.id: item.isExpanded,
      };
    });
  }

  void _updateTabController({int? initialIndex}) {
    int newIndex = initialIndex ?? _tabController.index;
    if (newIndex >= _tabs.length) {
      newIndex = _tabs.length - 1;
      if (newIndex < 0) newIndex = 0;
    }

    _tabController.removeListener(_tabControllerListener);
    _tabController.dispose();

    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: newIndex,
    );

    _tabController.addListener(_tabControllerListener);

    setState(() {}); // UI'yi yeniden çizmek için
  }

  void _addNewTab() async {
    int newOrder = _tabs.length;
    String id = const Uuid().v4();
    String name = 'Tab ${newOrder + 1}';
    TabItem tabItem = TabItem(id: id, name: name, order: newOrder);

    await _sqliteDatasource.addTab(tabItem);

    setState(() {
      _tabs.add(tabItem);
      _tabDataList
          .add(TabData(data: [], localExpandedStates: {}, allExpanded: true));
      _scrollControllers
          .add(ScrollController()); // Yeni ScrollController ekleniyor

      // TabController'ı güncelliyoruz
      _updateTabController(initialIndex: _tabs.length - 1);
    });

    // Yeni sekmeye geçiş yapıyoruz
    _tabController.animateTo(_tabs.length - 1);
  }

  // Tüm öğeleri genişletiyoruz #expandall
  void _expandAll(TabData tabData) {
    setState(() {
      for (var item in tabData.data) {
        item.isExpanded = true;
        _sqliteDatasource.updateExpandedState(item.id, true);
        tabData.localExpandedStates[item.id] = true;
      }
    });
  }

  // Tüm öğeleri daraltıyoruz #collapseall
  void _collapseAll(TabData tabData) {
    setState(() {
      for (var item in tabData.data) {
        item.isExpanded = false;
        _sqliteDatasource.updateExpandedState(item.id, false);
        tabData.localExpandedStates[item.id] = false;
      }
    });
  }

  // Tüm öğeleri genişletme veya daraltma arasında geçiş yapıyoruz #toggleexpandcollapse
  void _toggleExpandCollapse() {
    setState(() {
      int currentIndex = _tabController.index;
      TabData currentTabData = _tabDataList[currentIndex];
      if (currentTabData.allExpanded) {
        _collapseAll(currentTabData);
      } else {
        _expandAll(currentTabData);
      }
      currentTabData.allExpanded = !currentTabData.allExpanded;
    });
  }

///////////////////////

  // Export Popup açan fonksiyon
  Future<void> _showExportPopup(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Dışa Aktarma Seçenekleri',
                  style: TextStyle(
                      fontSize: 20), // Başlık font boyutunu küçültüyoruz
                  overflow: TextOverflow
                      .ellipsis, // Çok uzun olursa üç nokta gösterir
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(
                  Icons.close,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          content: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start, // İçeriği sola yaslamak için
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () async {
                  await exportToFirebase(context);
                },
                style: ElevatedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.zero, // Köşeleri dikdörtgen yapar
                  ),
                ),
                child: const Align(
                  alignment:
                      Alignment.centerLeft, // Buton içeriğini sola yaslar
                  child: Text(
                    'Bulut Link Paylaş',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await exportAsFile(context);
                },
                style: ElevatedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.zero, // Köşeleri dikdörtgen yapar
                  ),
                ),
                child: const Align(
                  alignment:
                      Alignment.centerLeft, // Buton içeriğini sola yaslar
                  child: Text(
                    'Dosya Olarak Paylaş',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await saveToDownloads(context);
                },
                style: ElevatedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.zero, // Köşeleri dikdörtgen yapar
                  ),
                ),
                child: const Align(
                  alignment:
                      Alignment.centerLeft, // Buton içeriğini sola yaslar
                  child: Text(
                    'Dosyalarıma Kaydet',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await exportAsHtml(context);
                },
                style: ElevatedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.zero, // Köşeleri dikdörtgen yapar
                  ),
                ),
                child: const Align(
                  alignment:
                      Alignment.centerLeft, // Buton içeriğini sola yaslar
                  child: Text(
                    'HTML Olarak Görüntüle',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showImportPopup(BuildContext context) async {
    final TextEditingController _cloudLinkController = TextEditingController();

    // Panodaki veriyi alıyoruz ve bulut linki olup olmadığını kontrol ediyoruz
    ClipboardData? clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData != null && clipboardData.text != null) {
      String clipboardText = clipboardData.text!;

      // Bulut linki için RegExp kontrolü (Firebase linki için örnek)
      RegExp cloudLinkRegExp = RegExp(
        r'https:\/\/firebasestorage\.googleapis\.com\/.*',
        caseSensitive: false,
      );

      // Eğer panodaki veri bulut linkiyse TextField'a otomatik yerleştiriyoruz
      if (cloudLinkRegExp.hasMatch(clipboardText)) {
        _cloudLinkController.text = clipboardText;
      }
    }

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'İçeri Aktarma Seçenekleri',
                  style: TextStyle(fontSize: 20), // Başlık boyutu
                  overflow:
                      TextOverflow.ellipsis, // Başlık uzun olursa üç nokta
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(
                  Icons.close,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bulut Linki Giriş Kısmı
              TextField(
                controller: _cloudLinkController,
                decoration: InputDecoration(
                  labelText: 'Bulut Linki',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.paste),
                    onPressed: () async {
                      ClipboardData? data =
                          await Clipboard.getData('text/plain');
                      if (data != null && data.text != null) {
                        String clipboardText = data.text!;
                        RegExp cloudLinkRegExp = RegExp(
                          r'https:\/\/firebasestorage\.googleapis\.com\/.*',
                          caseSensitive: false,
                        );

                        // Eğer panodaki veri bulut linkiyse otomatik yerleştir
                        if (cloudLinkRegExp.hasMatch(clipboardText)) {
                          _cloudLinkController.text = clipboardText;
                        } else {
                          // Geçerli bir bulut linki değilse uyarı ver
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Panodaki veri geçerli bir bulut linki değil.'),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ),
              SizedBox(height: 10),
              // Ekle Butonu
              Align(
                alignment: Alignment.topRight,
                child: ElevatedButton(
                  onPressed: () async {
                    String cloudLink = _cloudLinkController.text;
                    if (cloudLink.isNotEmpty) {
                      await _importDataFromCloud(cloudLink);
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text(
                    'Ekle',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Dosya Seç Butonu
              ElevatedButton(
                onPressed: () async {
                  await _importFromFile();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: const Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Dosya Seç',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Future<void> _importDataFromCloud(String cloudLink) async {
    try {
      // Firebase'den ZIP dosyasını indir
      final tempDir = await getTemporaryDirectory();
      String zipFilePath = '${tempDir.path}/import_data.zip';
      File zipFile = File(zipFilePath);

      // ZIP dosyasını bulut linkinden indiriyoruz
      final response = await HttpClient().getUrl(Uri.parse(cloudLink));
      final fileBytes = await response.close();
      await fileBytes.pipe(zipFile.openWrite());

      // ZIP dosyasını aç
      final bytes = zipFile.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      // JSON ve resim dosyalarını çıkartıyoruz
      for (var file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          final filePath = '${tempDir.path}/$filename';
          File outFile = File(filePath);
          await outFile.writeAsBytes(data);

          // JSON dosyasını işleme
          if (filename == 'data.json') {
            String contents = await outFile.readAsString();
            Map<String, dynamic> jsonData = jsonDecode(contents);

            // Veritabanındaki mevcut sekmeleri al
            List<TabItem> existingTabs = await _sqliteDatasource.getTabs();
            List<TabItem> newTabs = [];

            for (String tabName in jsonData.keys) {
              // Mevcut sekme var mı kontrol et
              TabItem? existingTab = existingTabs.firstWhereOrNull(
                (tab) => tab.name == tabName,
              );

              // Eğer sekme zaten varsa, onu kullan, yoksa yeni sekme oluştur
              String tabId;
              if (existingTab != null) {
                tabId = existingTab.id;
              } else {
                tabId = const Uuid().v4();
                int newOrder =
                    _tabs.length + newTabs.length; // Sıralamayı ayarla
                TabItem newTab =
                    TabItem(id: tabId, name: tabName, order: newOrder);
                await _sqliteDatasource.addTab(newTab);
                newTabs.add(newTab);
              }

              // İlgili sekmeye ait notları içeri aktar
              List<dynamic> notes = jsonData[tabName];
              for (var note in notes) {
                Item newItem = Item.fromMap(note);
                newItem.tabId = tabId;
                await _sqliteDatasource.addOrUpdateNote(newItem);
              }
            }

            // Tüm yeni sekmeleri ve verileri ekledikten sonra
            setState(() {
              _tabs.addAll(newTabs);
              _tabDataList.addAll(newTabs
                  .map((tab) => TabData(
                      data: [], localExpandedStates: {}, allExpanded: true))
                  .toList());
              _scrollControllers
                  .addAll(newTabs.map((tab) => ScrollController()).toList());

              // TabController'ı güncelle
              _updateTabController();
              _loadTabs();
            });

            // İçe aktarma tamamlandıktan sonra başarı mesajı göster
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Veriler başarıyla içe aktarıldı.')),
            );
          }
        }
      }
    } catch (e) {
      print('Veri içe aktarılırken hata oluştu: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veriler içe aktarılırken bir hata oluştu.')),
      );
    }
  }

  Future<void> _importFromFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['bin'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        List<int> binaryData = await file.readAsBytes();
        List<int> decompressedData = GZipDecoder().decodeBytes(binaryData);
        String contents = utf8.decode(decompressedData);
        Map<String, dynamic> jsonData =
            jsonDecode(contents); // Tüm sekmeler ve notlar

        // SQLite'den mevcut sekmeleri al
        List<TabItem> existingTabs = await _sqliteDatasource.getTabs();
        List<TabItem> newTabs = [];

        for (String tabName in jsonData.keys) {
          // Mevcut sekme var mı kontrol et
          TabItem? existingTab = existingTabs.firstWhereOrNull(
            (tab) => tab.name == tabName,
          );

          // Eğer sekme zaten varsa, onu kullan, yoksa yeni sekme oluştur
          String tabId;
          if (existingTab != null) {
            tabId = existingTab.id;
          } else {
            tabId = const Uuid().v4();
            int newOrder = _tabs.length + newTabs.length; // Sıralamayı ayarla
            TabItem newTab = TabItem(id: tabId, name: tabName, order: newOrder);
            await _sqliteDatasource.addTab(newTab);
            newTabs.add(newTab);
          }

          // İlgili sekmeye ait notları içeri aktar
          List<dynamic> notes = jsonData[tabName];
          for (var note in notes) {
            Item newItem = Item.fromMap(note);
            newItem.tabId = tabId; // Notu ait olduğu sekmeye bağla
            await _sqliteDatasource.addOrUpdateNote(newItem);
          }
        }

        // Tüm yeni sekmeleri ve verileri ekledikten sonra
        setState(() {
          _tabs.addAll(newTabs);
          _tabDataList.addAll(newTabs
              .map((tab) =>
                  TabData(data: [], localExpandedStates: {}, allExpanded: true))
              .toList());
          _scrollControllers
              .addAll(newTabs.map((tab) => ScrollController()).toList());

          // TabController'ı güncelle
          _updateTabController();
          _loadTabs();
        });

        // Başarı mesajı
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veriler başarıyla içe aktarıldı.')),
        );
      }
    } catch (e) {
      // Hata mesajı göster
      print('Veri içe aktarılırken hata oluştu: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veriler içe aktarılırken bir hata oluştu.')),
      );
    }
  }

/////////////////////import son//////////

  // overwrite dialogu #overwritedialogg,aynbaşlıkmevcutt
  Future<bool> _showOverwriteDialog(String title) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Aynı Başlık Mevcut'),
              content: Text.rich(
                TextSpan(
                  text: '',
                  children: <TextSpan>[
                    TextSpan(
                      text: title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(
                      text:
                          ' başlıklı bir not zaten var. Üzerine yazmak ister misiniz?',
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('İptal',
                      style: TextStyle(color: Colors.black)),
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

  // AddItemPage'e yönlendirme, dönüşte veri bekliyoruz. #navigateandadditemm

  void _navigateAndAddItem() async {
    int currentIndex = _tabController.index;
    String tabId = _tabs[currentIndex].id;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddItemPage(tabId: tabId)),
    );

    if (result == true) {
      _loadData(currentIndex);
    }
  }

  // veritabanındaki tümverileri silme #deletealldataa,verilerisill,hepsinisill,sill
  void _deleteAllData() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Verileri Sil',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.green),
          ),
          content: const Text(
              'Tüm sekmelerdeki verileri silmek istediğinizden emin misiniz?'),
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
      // Tüm verileri sil
      await _sqliteDatasource.deleteAllItems();
      await _sqliteDatasource.deleteAllTabs();

      // Tab 1 varsayılan sekmesini tekrar oluştur
      String id = 'tab1';
      String name = 'Tab 1';
      TabItem tabItem = TabItem(id: id, name: name, order: 0);
      await _sqliteDatasource.addTab(tabItem);

      setState(() {
        // Tüm verileri tab listelerinden temizliyoruz
        _tabDataList.clear();
        _tabs.clear();

        // Tab 1 sekmesini ve verisini tekrar ekliyoruz
        _tabs = [tabItem];
        _tabDataList = [
          TabData(data: [], localExpandedStates: {}, allExpanded: true),
        ];

        // TabController'ı tekrar başlatıyoruz
        _tabController.dispose();
        _tabController = TabController(
          length: _tabs.length,
          vsync: this,
          initialIndex: 0,
        );

        _tabController.addListener(_tabControllerListener);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tüm veriler silindi.')),
      );
    }
  }

  void _onReorderTabs(int oldIndex, int newIndex) async {
    print('ESKİ sıra: $_tabs');

    setState(() {
      final TabItem movedTab = _tabs.removeAt(oldIndex);
      _tabs.insert(newIndex, movedTab);

      final TabData movedTabData = _tabDataList.removeAt(oldIndex);
      _tabDataList.insert(newIndex, movedTabData);

      final ScrollController movedScrollController =
          _scrollControllers.removeAt(oldIndex);
      _scrollControllers.insert(newIndex, movedScrollController);
    });

    // 'order' alanlarını güncelleme ve veritabanına kaydetme
    for (int i = 0; i < _tabs.length; i++) {
      TabItem tab = _tabs[i];
      tab.order = i;
      await _sqliteDatasource.updateTabOrder(tab.id, tab.order);
    }

    // TabController'ı güncelleme
    _updateTabController(initialIndex: newIndex);

    print('Yeni sıra: $_tabs');
  }

  Future<void> _showRenameTabDialog(int index) async {
    TextEditingController textController =
        TextEditingController(text: _tabs[index].name);

    String? newName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sekme İsmini Değiştir'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(
              hintText: 'Yeni sekme ismi',
            ),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "İptal",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                ElevatedButton(
                  child: const Text(
                    'Kaydet',
                    style: TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    String inputName = textController.text.trim();
                    if (inputName.isNotEmpty) {
                      Navigator.of(context).pop(inputName);
                    }
                  },
                ),
              ],
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty) {
      _renameTab(index, newName);
    }
  }

  void _renameTab(int index, String newName) async {
    setState(() {
      _tabs[index].name = newName;
    });

    // Veritabanında sekme ismini güncelle
    await _sqliteDatasource.updateTabName(_tabs[index].id, newName);
  }

  Widget _buildTabContent(int index) {
    TabData currentTabData = _tabDataList[index];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(3.0),
          child: Column(
            children: [
              // Prompt kısmı
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: Center(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                              fontSize: 16, color: Colors.black),
                          children: <TextSpan>[
                            const TextSpan(
                                text: 'Yeni bir tablo eklemek ister misiniz? '),
                            TextSpan(
                              text: 'Ekle',
                              style: const TextStyle(
                                color: Colors.green,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = _navigateAndAddItem,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (currentTabData.data.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Arama ikonu ve metin alanı
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0,
                          end: _isSearching ? 1 : 0,
                        ),
                        duration: const Duration(milliseconds: 300),
                        builder: (context, value, child) {
                          return Container(
                            width: 50 + 200 * value,
                            decoration: BoxDecoration(
                              border: value > 0
                                  ? Border.all(color: Colors.green)
                                  : null,
                              borderRadius:
                                  BorderRadius.circular(20.0), // Daha yuvarlak
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.search),
                                  onPressed: () {
                                    setState(() {
                                      _isSearching = !_isSearching;
                                    });
                                  },
                                ),
                                if (value > 0)
                                  Expanded(
                                    child: Opacity(
                                      opacity: value,
                                      child: TextField(
                                        controller: _searchController,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          disabledBorder: InputBorder.none,
                                          errorBorder: InputBorder.none,
                                          focusedErrorBorder: InputBorder.none,
                                          hintText: 'Arama',
                                          suffixIcon: IconButton(
                                            icon: const Icon(Icons.close),
                                            onPressed: () {
                                              setState(() {
                                                _isSearching = false;
                                                _searchController.clear();
                                              });
                                            },
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
                    // Tümünü Genişlet/Daralt butonu
                    TextButton(
                      onPressed: () => _toggleExpandCollapse(),
                      child: Text(
                        currentTabData.allExpanded
                            ? 'Tümünü Daralt'
                            : 'Tümünü Genişlet',
                        style: const TextStyle(
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollControllers[index],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: _buildPanel(currentTabData),
            ),
          ),
        ),
      ],
    );
  }

  //listeyi oluşturmak için bir widget oluşturuyoruz
  Widget _buildPanel(TabData tabData) {
    String searchQuery = _searchController.text.toLowerCase();

    List<Item> filteredItems = tabData.data.where((item) {
      bool matchesTitle = item.headerValue.toLowerCase().contains(searchQuery);
      bool matchesSubtitle = item.subtitle!.toLowerCase().contains(searchQuery);

      bool matchesExpandValue = item.expandedValue
          .any((value) => value.toLowerCase().contains(searchQuery));

      return matchesTitle || matchesSubtitle || matchesExpandValue;
    }).toList();

    if (filteredItems.isEmpty) {
      if (searchQuery.isNotEmpty) {
        // Arama yapıldı ancak sonuç bulunamadı
        return Center(
          child: Text(
            'Aramanızla eşleşen sonuç bulunamadı.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        );
      } else {
        // Veri yok ve arama yapılmadı, boş bir widget döndürüyoruz
        return Container();
      }
    }

    return Column(
      children: filteredItems.map<Widget>((Item item) {
        return Padding(
          padding: const EdgeInsets.only(
              right: 2.0, left: 2.0, bottom: 5.0, top: 2.0),
          child: ListItem(
            item: item,
            isGlobalExpanded: tabData.allExpanded,
            isLocalExpanded: tabData.localExpandedStates[item.id] ?? false,
            onExpandedChanged: (bool isExpanded) {
              _sqliteDatasource.updateExpandedState(item.id, isExpanded);

              setState(() {
                tabData.localExpandedStates[item.id] = isExpanded;
                tabData.allExpanded = tabData.data.every(
                    (item) => tabData.localExpandedStates[item.id] ?? false);
              });
            },
            onTableEdited: () {
              _loadData(_tabController.index);
            },
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Yükleniyor...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          shadowColor: Colors.green[10],
          surfaceTintColor: Colors.green[400],
          title: const Center(
              child: Text(
            'DEV SECURE',
            style: TextStyle(
              fontSize: 25,
            ),
          )),
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: 5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 50,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ReorderableWrap(
                    needsLongPressDraggable: false,
                    spacing: 4.0,
                    runSpacing: 4.0,
                    direction: Axis.horizontal,
                    onReorder: _onReorderTabs,
                    children: _tabs.asMap().entries.map((entry) {
                          int index = entry.key;
                          TabItem tabItem = entry.value;
                          return GestureDetector(
                            key: ValueKey(tabItem.id),
                            onTap: () {
                              _tabController.animateTo(index);
                            },
                            onLongPress: () {
                              // Sekmeye uzun basıldığında isim değiştirme dialogunu aç
                              _showRenameTabDialog(index);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 5.0),
                              decoration: BoxDecoration(
                                color: _tabController.index == index
                                    ? Colors.green[300] // Seçili sekmenin rengi
                                    : Colors
                                        .green[100], // Diğer sekmelerin rengi
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(
                                        15.0)), // Köşe yuvarlama
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    tabItem.name,
                                    style: TextStyle(
                                      color: _tabController.index == index
                                          ? Colors
                                              .white // Seçili sekme metin rengi
                                          : Colors
                                              .black, // Diğer sekme metin rengi
                                    ),
                                  ),
                                  const SizedBox(width: 10.0),
                                  if (index != 0) // İlk sekme hariç 'X' göster
                                    GestureDetector(
                                      onTap: () {
                                        // 'X' ikonuna tıklanırsa sekmeyi kapat
                                        _closeTab(index);
                                      },
                                      child: Icon(
                                        Icons.close,
                                        size: 16.0,
                                        color: _tabController.index == index
                                            ? Colors
                                                .white // Seçili sekme 'X' ikonu rengi
                                            : Colors
                                                .black, // Diğer sekme 'X' ikonu rengi
                                      ),
                                    )
                                  else
                                    const SizedBox(width: 16.0),
                                ],
                              ),
                            ),
                          );
                        }).toList() +
                        [
                          GestureDetector(
                            onTap: _addNewTab,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 5.0),
                              decoration: const BoxDecoration(
                                // color: Colors.green[100],
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(15.0)),
                              ),
                              child: const Icon(Icons.add, color: Colors.green),
                            ),
                          ),
                        ],
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _tabs.asMap().entries.map((entry) {
                    int index = entry.key;
                    return _buildTabContent(index); // Sekme içerikleri
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.green[100],
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.green[50],
            selectedItemColor: Colors.green[300],
            unselectedItemColor: Colors.green[200],
            type: BottomNavigationBarType.fixed, // Kayma davranışını önler
            items: [
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[200],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.import_export, color: Colors.white),
                ),
                label: 'İçeri Aktar',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[200],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.file_upload, color: Colors.white),
                ),
                label: 'Dışarı Aktar',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[200],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                label: 'Sil',
              ),
            ],
            currentIndex: 0, // Hiçbir öğe seçili olarak vurgulanmamış
            onTap: (index) {
              switch (index) {
                case 0:
                  _showImportPopup(context);
                  break;
                case 1:
                  _showExportPopup(context);
                  break;
                case 2:
                  _deleteAllData();
                  break;
              }
            },
          ),
        ),
      );
    }
  }
}
////////////////////////////////////////////////
///
///
///