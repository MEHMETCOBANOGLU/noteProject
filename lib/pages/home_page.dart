//////////////////////////////////////////////2///////////
library;

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

  List<ScrollController> _scrollControllers = [];

  @override
  void initState() {
    super.initState();
    _loadTabs();
    _scrollControllers = [];
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
        TabItem tabItem = TabItem(id: id, name: name);
        _tabs = [tabItem];
        _sqliteDatasource.addTab(tabItem);
      } else {
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
        TabItem tabItem = TabItem(id: id, name: name);
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

    setState(() {}); // TabController değişikliğini UI'ye bildir
  }

  void _addNewTab() async {
    int newTabIndex = _tabs.length + 1;
    String id = const Uuid().v4();
    String name = 'Tab $newTabIndex';
    TabItem tabItem = TabItem(id: id, name: name);

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

  @override
  void dispose() {
    for (var controller in _scrollControllers) {
      controller.dispose();
    }
    _tabController.dispose();
    super.dispose();
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
              Flexible(
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
                icon: Icon(
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
                  await _exportToFirebase();
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.zero, // Köşeleri dikdörtgen yapar
                  ),
                ),
                child: Align(
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
                  await _exportAsFile();
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.zero, // Köşeleri dikdörtgen yapar
                  ),
                ),
                child: Align(
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
                  await _saveToDownloads();
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.zero, // Köşeleri dikdörtgen yapar
                  ),
                ),
                child: Align(
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
                  await _exportAsHtml();
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.zero, // Köşeleri dikdörtgen yapar
                  ),
                ),
                child: Align(
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

  // Firebase'e dosya yükleme ve link paylaşma

  Future<void> _exportToFirebase() async {
    try {
      // SQLite veritabanından tüm sekmeleri ve notları alıyoruz
      List<TabItem> allTabs = await _sqliteDatasource.getTabs();
      Map<String, dynamic> allData = {};

      // Her sekmedeki notları topla
      for (TabItem tab in allTabs) {
        List<Item> tabNotes = await _sqliteDatasource.getNotes(tab.id);
        allData[tab.name] = tabNotes.map((e) => e.toMap()).toList();
      }

      // JSON formatına çevir
      String jsonData = jsonEncode(allData);

      // Geçici dizine JSON dosyasını kaydet
      final tempDir = await getTemporaryDirectory();
      String jsonFilePath = '${tempDir.path}/data.json';
      File jsonFile = File(jsonFilePath);
      await jsonFile.writeAsString(jsonData);

      // Zip dosyasını oluştur
      final zipEncoder = ZipFileEncoder();
      String zipFilePath = '${tempDir.path}/export_data.zip';
      zipEncoder.create(zipFilePath);

      // JSON dosyasını zip'e ekle
      zipEncoder.addFile(jsonFile);

      // Resimler için "images" klasörünü zip dosyası içinde oluşturun
      Directory imagesDir = Directory('${tempDir.path}/images');
      if (!imagesDir.existsSync()) {
        imagesDir.createSync(recursive: true);
      }

      for (var tab in allTabs) {
        List<Item> tabNotes = await _sqliteDatasource.getNotes(tab.id);
        for (var item in tabNotes) {
          if (item.imageUrls != null && item.imageUrls!.isNotEmpty) {
            for (String imageUrl in item.imageUrls!) {
              if (imageUrl.isNotEmpty) {
                try {
                  Uri uri = Uri.parse(imageUrl);
                  if (uri.scheme == 'http' || uri.scheme == 'https') {
                    // Eğer URL internetten ise görseli indir
                    final response =
                        await HttpClient().getUrl(Uri.parse(imageUrl));
                    final fileBytes = await response.close();
                    String fileName = imageUrl.split('/').last;
                    File imageFile = File('${imagesDir.path}/$fileName');
                    await fileBytes.pipe(imageFile.openWrite());

                    // Görseli "images" klasörü içinde zip dosyasına ekleyin
                    zipEncoder.addFile(imageFile, 'images/$fileName');
                  } else {
                    // Yerel dosya yolunu kontrol et ve zip'e ekle
                    File localImageFile = File(imageUrl);
                    if (await localImageFile.exists()) {
                      String fileName = localImageFile.path.split('/').last;
                      File imageFile = File('${imagesDir.path}/$fileName');
                      localImageFile.copySync(imageFile.path);

                      // Görseli "images" klasörü içinde zip dosyasına ekleyin
                      zipEncoder.addFile(imageFile, 'images/$fileName');
                    } else {
                      print('Yerel dosya bulunamadı: $imageUrl');
                    }
                  }
                } catch (e) {
                  print('Resim indirilemedi veya eklenemedi: $e');
                }
              } else {
                // Eğer URL boşsa, "resim yok" mesajı ekleyebilirsiniz
                print('Boş resim URL\'si bulundu.');
              }
            }
          }
        }
      }

      // Zip dosyasını kapat
      zipEncoder.close();

      String formattedDate =
          DateFormat('dd.MM.yyyy_HH.mm').format(DateTime.now());

      // Firebase'e zip dosyasını yükle
      FirebaseStorage storage = FirebaseStorage.instance;
      File zipFile = File(zipFilePath);
      TaskSnapshot uploadTask = await storage
          .ref('tablify/exports/Tablify_dataExport_$formattedDate.zip')
          .putFile(zipFile);

      // Paylaşılabilir link oluştur
      String downloadUrl = await uploadTask.ref.getDownloadURL();

      // Linki panoya kopyala ve paylaşma ekranını aç
      Clipboard.setData(ClipboardData(text: downloadUrl));
      await Share.share('Verileriniz burada: $downloadUrl');

      // Başarı mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Veriler başarıyla yüklendi ve paylaşılabilir link oluşturuldu.'),
      ));
    } catch (e) {
      // Hata mesajı
      print('Hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Veri yüklenirken bir hata oluştu.'),
      ));
    }
  }

  // Cihazdaki verileri dışarı aktarır #exportdataa,dışarıaktarr
// Dosya paylaşımı
  Future<void> _exportAsFile() async {
    try {
      // SQLite veritabanından tüm sekmeleri ve onlara ait notları alıyoruz
      List<TabItem> allTabs = await _sqliteDatasource.getTabs();
      Map<String, dynamic> allData =
          {}; // Tüm verileri tutmak için bir harita (map)

      for (TabItem tab in allTabs) {
        // Her sekmeye ait notları alıyoruz
        List<Item> tabNotes = await _sqliteDatasource.getNotes(tab.id);
        allData[tab.name] = tabNotes
            .map((e) => e.toMap())
            .toList(); // Her sekmenin notlarını ekliyoruz
      }

      // Veriyi JSON formatına çevir ve sıkıştır
      String jsonData = jsonEncode(allData);
      List<int> binaryData = utf8.encode(jsonData);
      List<int>? compressedData = GZipEncoder().encode(binaryData);

      // Dosya sistemine kaydet
      final directory = await getApplicationDocumentsDirectory();
      String formattedDate =
          DateFormat('dd.MM.yyyy_HH.mm').format(DateTime.now());
      final file =
          File('${directory.path}/Tablify_dataExport_$formattedDate.bin');
      await file.writeAsBytes(compressedData!);

      // Dosyayı paylaş
      await Share.shareXFiles([XFile(file.path)],
          text: 'Here is your data export');

      // Başarı mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veriler başarıyla dışa aktarıldı.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      // Hata mesajı göster
      print('Veri dışa aktarılırken hata oluştu: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veriler dışa aktarılırken bir hata oluştu.')),
      );
    }
  }

  // Dosyayı cihazın indirilenler klasörüne kaydetme
  Future<void> _saveToDownloads() async {
    try {
      // SQLite veritabanından tüm sekmeleri ve onlara ait notları alıyoruz
      List<TabItem> allTabs = await _sqliteDatasource.getTabs();
      Map<String, dynamic> allData =
          {}; // Tüm verileri tutmak için bir harita (map)

      for (TabItem tab in allTabs) {
        // Her sekmeye ait notları alıyoruz
        List<Item> tabNotes = await _sqliteDatasource.getNotes(tab.id);
        allData[tab.name] = tabNotes
            .map((e) => e.toMap())
            .toList(); // Her sekmenin notlarını ekliyoruz
      }

      // Veriyi JSON formatına çevir ve sıkıştır
      String jsonData = jsonEncode(allData);
      List<int> binaryData = utf8.encode(jsonData);
      List<int>? compressedData = GZipEncoder().encode(binaryData);

      // Dosya sistemine kaydet
      final directory = Directory(
          '/storage/emulated/0/Download'); // İndirilenler klasörü yolu
      String formattedDate =
          DateFormat('dd.MM.yyyy_HH.mm').format(DateTime.now());
      final file =
          File('${directory.path}/Tablify_dataExport_$formattedDate.bin');
      await file.writeAsBytes(compressedData!);

      // Başarı mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Dosya başarıyla indirilenler klasörüne kaydedildi.'),
      ));
      Navigator.of(context).pop();
    } catch (e) {
      // Hata mesajı göster
      print('Dosya kaydedilirken hata oluştu: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Dosya kaydedilirken bir hata oluştu.'),
      ));
    }
  }

  // HTML dosyası olarak Firebase'e yükleme

  Future<void> _exportAsHtml() async {
    try {
      // Verileri veritabanından al
      List<TabItem> allTabs = await _sqliteDatasource.getTabs();
      Map<String, dynamic> allData = {};

      // Her sekmedeki notları al
      for (TabItem tab in allTabs) {
        List<Item> tabNotes = await _sqliteDatasource.getNotes(tab.id);
        allData[tab.name] = tabNotes.map((e) => e.toMap()).toList();
      }

      // HTML içeriğini başlat
      String htmlContent = """
<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Export Edilen Veriler</title>
</head>
<body>
  <h1>Export Edilen Veriler</h1>
""";

      // Tüm sekmeler ve ilgili notları HTML'e ekle
      allTabs.forEach((tab) {
        htmlContent += "<h2>${tab.name}</h2>";
        htmlContent += "<table border='1' cellpadding='5'>";
        htmlContent +=
            "<tr><th>ID</th><th>Başlık</th><th>Alt Başlık</th><th>Items</th><th>Resim URL'leri</th></tr>";

        List<dynamic> items = allData[tab.name];
        for (var itemMap in items) {
          Item item = Item.fromMap(itemMap);
          htmlContent += "<tr>";
          htmlContent += "<td>${item.id}</td>";
          htmlContent += "<td>${item.headerValue}</td>";
          htmlContent += "<td>${item.subtitle ?? 'Yok'}</td>";
          // Genişletilmiş değerleri satır satır ve başında "-" işareti ile göster
          htmlContent +=
              "<td><ul>${item.expandedValue.map((val) => "<li>$val</li>").join('')}</ul></td>";
          if (item.imageUrls != null && item.imageUrls!.isNotEmpty) {
            htmlContent += "<td><ul>";
            item.imageUrls!.forEach((url) {
              if (url.isNotEmpty) {
                htmlContent += "<li>$url</li>"; // URL boş değilse göster
              } else {
                htmlContent +=
                    "<li>Resim Yok</li>"; // URL boşsa 'Resim Yok' yazdır
              }
            });
            htmlContent += "</ul></td>";
          } else {
            htmlContent +=
                "<td><ul><li>Resim Yok</li></ul></td>"; // URL listesi boş veya null ise 'Resim Yok' yazdır
          }

          htmlContent += "</tr>";
        }
        htmlContent += "</table><br/>";
      });

      htmlContent += "</body></html>";

      // HTML dosyasını kaydet
      final directory = await getApplicationDocumentsDirectory();
      String fileName = 'export_${Uuid().v4()}.html';
      File file = File('${directory.path}/$fileName');
      await file.writeAsString(htmlContent);

      // Firebase Storage'a yükle ve linki al
      TaskSnapshot uploadTask =
          await _storage.ref('tablify/exports/html/$fileName').putFile(file);
      String downloadUrl = await uploadTask.ref.getDownloadURL();

      // Linki doğrudan tarayıcıda aç
      await launch(downloadUrl);

      // İşlem tamamlandığında kullanıcıya bildirim göster
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('HTML linki kopyalandı ve tarayıcı açılıyor...'),
      ));
    } catch (e) {
      print('Hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('HTML export sırasında bir hata oluştu.'),
      ));
    }
  }

  //////////////export son/////////
  ///
  ///import başlangıç//////////////////////////////////

  // Cihazdaki verileri içeri aktarır #importdataa,içeriarıaktarr
  void _importData() async {
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

        for (String tabName in jsonData.keys) {
          // Mevcut sekme var mı kontrol et
          TabItem? existingTab = existingTabs.firstWhere(
            (tab) => tab.name == tabName,
            orElse: () => TabItem(id: const Uuid().v4(), name: ''),
          );

          // Eğer sekme zaten varsa, onu kullan, yoksa yeni sekme oluştur
          String tabId;
          if (existingTab.name.isNotEmpty) {
            tabId = existingTab.id;
          } else {
            tabId = const Uuid().v4();
            TabItem newTab = TabItem(id: tabId, name: tabName);
            await _sqliteDatasource.addTab(newTab);
            setState(() {
              _tabs.add(newTab);
              _tabDataList.add(TabData(
                  data: [], localExpandedStates: {}, allExpanded: true));
              _scrollControllers
                  .add(ScrollController()); // Yeni ScrollController ekliyoruz
            });
          }

          // İlgili sekmeye ait notları içeri aktar
          List<dynamic> notes = jsonData[tabName];
          for (var note in notes) {
            Item newItem = Item.fromMap(note);
            newItem.tabId = tabId; // Notu ait olduğu sekmeye bağla
            await _sqliteDatasource.addOrUpdateNote(newItem);
          }
        }

        // Başarı mesajı
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veriler başarıyla içe aktarıldı.')),
        );

        // Verileri yeniden yükle
        _loadTabs();
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

            for (String tabName in jsonData.keys) {
              // Mevcut sekme var mı kontrol et
              TabItem? existingTab = existingTabs.firstWhere(
                (tab) => tab.name == tabName,
                orElse: () => TabItem(id: const Uuid().v4(), name: ''),
              );

              // Eğer sekme zaten varsa, onu kullan, yoksa yeni sekme oluştur
              String tabId;
              if (existingTab.name.isNotEmpty) {
                tabId = existingTab.id;
              } else {
                tabId = const Uuid().v4();
                TabItem newTab = TabItem(id: tabId, name: tabName);
                await _sqliteDatasource.addTab(newTab);
                setState(() {
                  _tabs.add(newTab);
                  _tabDataList.add(TabData(
                      data: [], localExpandedStates: {}, allExpanded: true));
                  _scrollControllers.add(ScrollController());
                });
              }

              // İlgili sekmeye ait notları içeri aktar
              List<dynamic> notes = jsonData[tabName];
              for (var note in notes) {
                Item newItem = Item.fromMap(note);
                newItem.tabId = tabId;
                await _sqliteDatasource.addOrUpdateNote(newItem);
              }
            }
            _updateTabController();
          }

          // Resim dosyalarını ilgili klasöre kaydediyoruz
          if (filename.startsWith('images/')) {
            final imageFile = File('${tempDir.path}/$filename');
            await imageFile.writeAsBytes(file.content);
          }
        }
      }

      // İçe aktarma tamamlandıktan sonra başarı mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veriler başarıyla içe aktarıldı.')),
      );

      // Verileri yeniden yükle
      _loadTabs();
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

        for (String tabName in jsonData.keys) {
          // Mevcut sekme var mı kontrol et
          TabItem? existingTab = existingTabs.firstWhere(
            (tab) => tab.name == tabName,
            orElse: () => TabItem(id: const Uuid().v4(), name: ''),
          );

          // Eğer sekme zaten varsa, onu kullan, yoksa yeni sekme oluştur
          String tabId;
          if (existingTab.name.isNotEmpty) {
            tabId = existingTab.id;
          } else {
            tabId = const Uuid().v4();
            TabItem newTab = TabItem(id: tabId, name: tabName);
            await _sqliteDatasource.addTab(newTab);
            setState(() {
              _tabs.add(newTab);
              _tabDataList.add(TabData(
                  data: [], localExpandedStates: {}, allExpanded: true));
              _scrollControllers
                  .add(ScrollController()); // Yeni ScrollController ekliyoruz
            });
          }

          // İlgili sekmeye ait notları içeri aktar
          List<dynamic> notes = jsonData[tabName];
          for (var note in notes) {
            Item newItem = Item.fromMap(note);
            newItem.tabId = tabId; // Notu ait olduğu sekmeye bağla
            await _sqliteDatasource.addOrUpdateNote(newItem);
          }
        }

        // Başarı mesajı
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veriler başarıyla içe aktarıldı.')),
        );

        _updateTabController();
        // Verileri yeniden yükle
        _loadTabs();
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

  Future<void> _importDataFromFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      // Dosya verisini işleme kodları burada olacak.
      print('Dosya başarıyla içeri aktarıldı.');
    } catch (e) {
      print('Dosya içe aktarılırken hata oluştu: $e');
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
      TabItem tabItem = TabItem(id: id, name: name);
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

  void _onReorderTabs(int oldIndex, int newIndex) {
    setState(() {
      // Eğer yeniIndex, oldIndex'ten büyükse yeniIndex'i bir azaltmak gerekebilir
      // çünkü kaldırma işlemi sonrasında liste kısalır
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      // Sekmeyi ve ona ait veriyi listelerden kaldır ve yeni konuma ekle
      final TabItem movedTab = _tabs.removeAt(oldIndex);
      _tabs.insert(newIndex, movedTab);

      final TabData movedTabData = _tabDataList.removeAt(oldIndex);
      _tabDataList.insert(newIndex, movedTabData);

      // ScrollController'ı da aynı şekilde yeniden sırala
      final ScrollController movedScrollController =
          _scrollControllers.removeAt(oldIndex);
      _scrollControllers.insert(newIndex, movedScrollController);

      // TabController'ı güncelle
      _updateTabController(initialIndex: newIndex);
    });
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

    // Veri tabanında sekme ismini güncelle
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
              // Display the prompt in all tabs
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 5.0),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black),
                            children: <TextSpan>[
                              const TextSpan(
                                  text:
                                      'Yeni bir tablo eklemek ister misiniz? '),
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
                  ),
                ],
              ),
              if (currentTabData.data.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => _toggleExpandCollapse(),
                        child: Text(
                          currentTabData.allExpanded
                              ? 'Tümünü Daralt'
                              : 'Tümünü Genişlet',
                          style: const TextStyle(
                            color: Colors.green,
                          ),
                        )),
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
    return Column(
      children: tabData.data.map<Widget>((Item item) {
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