//////////////////////////////////////////////2///////////
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:motion_tab_bar/MotionTabBar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:Tablify/data/database.dart';
import 'package:Tablify/model/items.dart';
import 'package:Tablify/pages/add_item_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../model/TabItem.dart';
import '../navigation/item_list.wiev.dart';
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:archive/archive_io.dart';

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
  bool _allExpanded = true;
  List<Item> _data = [];
  Map<String, bool> _localExpandedStates = {};
  int _selectedIndexTab = 0;

  List<TabItem> _tabs = [];
  late TabController _tabController;
  List<TabData> _tabDataList = [];
  bool _isLoading = true;

  // @override
  // void initState() {
  //   super.initState();

  //    _loadTabs();

  //   // Initialize tabs only if they are empty
  //   if (_tabs.isEmpty) {
  //     _tabs = [Tab(text: 'Tab 1')];
  //     _tabDataList = [
  //       TabData(data: [], localExpandedStates: {}, allExpanded: true),
  //     ];
  //   }

  //   _tabController = TabController(length: _tabs.length, vsync: this);
  //   _loadData(0); // Load data for Tab 1

  //   _tabController.addListener(() {
  //     if (_tabController.indexIsChanging) {
  //       _loadData(_tabController.index);
  //     }
  //   });
  // }

  @override
  void initState() {
    super.initState();
    _loadTabs();
  }

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

      // TabController'ı _tabs.length + 1 olarak başlatıyoruz
      _tabController = TabController(length: _tabs.length + 1, vsync: this);
      _loadData(_tabController.index);

      _tabController.addListener(() {
        if (_tabController.indexIsChanging) {
          if (_tabController.index == _tabs.length) {
            // '+' butonuna tıklandı, yeni sekme ekle
            _addNewTab();
          } else {
            _loadData(_tabController.index);
          }
        }
      });

      _isLoading = false; // Başlatma tamamlandı
    });
  }

  void _closeTab(int index) async {
    TabItem tabItem = _tabs[index];
    List<Item> data = _tabDataList[index].data;

    if (data.isNotEmpty) {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Sekmeyi Kapat'),
          content: Text(
              'Bu sekmeyi kapatmak ve içindeki tüm verileri silmek istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              child: Text('İptal', style: TextStyle(color: Colors.black)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('Sil', style: TextStyle(color: Colors.white)),
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

      // Eski TabController'ı dispose ediyoruz
      _tabController.dispose();

      // Yeni TabController oluşturuyoruz
      _tabController = TabController(length: _tabs.length + 1, vsync: this);

      _tabController.addListener(() {
        if (_tabController.indexIsChanging) {
          _loadData(_tabController.index);
        }
      });

      // Kapatılan sekme son sekmeyse, bir önceki sekmeye git
      if (index == _tabs.length) {
        _selectedIndexTab = _tabs.length - 1;
      } else {
        // Kapatılan sekme ortadaysa, aynı indekste kal (bir sonraki sekmeye geç)
        _selectedIndexTab = index;
      }
    });

    // Sekmeye doğrudan geçiş yapıyoruz (animasyonsuz)
    _tabController.index = _selectedIndexTab;
  }

  // Preserving state across hot reload
  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_tabController.length != _tabs.length) {
      _tabController.dispose();
      _tabController = TabController(length: _tabs.length, vsync: this);
      _tabController.addListener(() {
        if (_tabController.indexIsChanging) {
          _loadData(_tabController.index);
        }
      });
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

  void _updateTabController() {
    _tabController.dispose();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _loadData(_tabController.index);
      }
    });
    setState(() {});
  }

  void _addNewTab() async {
    int newTabIndex = _tabs.length + 1;
    String id = Uuid().v4();
    String name = 'Tab $newTabIndex';
    TabItem tabItem = TabItem(id: id, name: name);

    await _sqliteDatasource.addTab(tabItem);

    setState(() {
      _tabs.add(tabItem);
      _tabDataList
          .add(TabData(data: [], localExpandedStates: {}, allExpanded: true));

      // Eski TabController'ı dispose ediyoruz
      _tabController.dispose();

      // Yeni TabController oluşturuyoruz
      _tabController = TabController(length: _tabs.length + 1, vsync: this);

      _tabController.addListener(() {
        if (_tabController.indexIsChanging) {
          _loadData(_tabController.index);
        }
      });

      // Yeni sekmeye geçiş yapıyoruz
      _tabController.animateTo(_tabs.length - 1);
    });
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
    _tabController.dispose();
    super.dispose();
  }

  // Cihazdaki verileri dışarı aktarır #exportdataa,dışarıaktarr
  void _exportData() async {
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
        SnackBar(content: Text('Veriler başarıyla dışa aktarıldı.')),
      );
    } catch (e) {
      // Hata mesajı göster
      print('Veri dışa aktarılırken hata oluştu: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veriler dışa aktarılırken bir hata oluştu.')),
      );
    }
  }

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
            orElse: () => TabItem(id: Uuid().v4(), name: ''),
          );

          // Eğer sekme zaten varsa, onu kullan, yoksa yeni sekme oluştur
          String tabId;
          if (existingTab.name.isNotEmpty) {
            tabId = existingTab.id;
          } else {
            tabId = Uuid().v4();
            TabItem newTab = TabItem(id: tabId, name: tabName);
            await _sqliteDatasource.addTab(newTab);
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
          SnackBar(content: Text('Veriler başarıyla içe aktarıldı.')),
        );

        // Verileri yeniden yükle
        _loadTabs();
      }
    } catch (e) {
      // Hata mesajı göster
      print('Veri içe aktarılırken hata oluştu: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veriler içe aktarılırken bir hata oluştu.')),
      );
    }
  }

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
          content: Text(
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
        _tabController = TabController(length: _tabs.length + 1, vsync: this);

        _tabController.addListener(() {
          if (_tabController.indexIsChanging) {
            _loadData(_tabController.index);
          }
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tüm veriler silindi.')),
      );
    }
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
                              ? 'Tümünü Daralt    '
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
          title: Text('Yükleniyor...'),
        ),
        body: Center(
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
        body: Column(
          children: [
            Container(
              height: 50,
              child: Row(
                children: [
                  Expanded(
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: Colors.green,
                      unselectedLabelColor: Colors.white,
                      indicatorColor: Colors.green,
                      labelPadding: const EdgeInsets.only(
                          left: 3.0, right: 3.0, top: 5.0),
                      tabAlignment:
                          TabAlignment.start, // Sekmeler sol tarafa hizalanıyor
                      splashFactory: NoSplash.splashFactory,
                      tabs: [
                        ..._tabs.map((tabItem) {
                          return ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(15.0)),
                            child: Container(
                              color: Colors.green[100],
                              child: Tab(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        tabItem.name,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    SizedBox(width: 15),
                                    if (_tabs.indexOf(tabItem) !=
                                        0) // Tab 1 için çarpı işaretini gizliyoruz
                                      GestureDetector(
                                        onTap: () =>
                                            _closeTab(_tabs.indexOf(tabItem)),
                                        child: const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(Icons.close, size: 16),
                                        ),
                                      )
                                    else
                                      SizedBox(
                                        width:
                                            24, // Çarpı ikonunun yerine boşluk ekliyoruz
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        // '+' butonu
                        Tab(
                          child: IconButton(
                            icon: Icon(Icons.add, color: Colors.green),
                            onPressed: _addNewTab,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ..._tabs.asMap().entries.map((entry) {
                    int index = entry.key;
                    return _buildTabContent(index);
                  }).toList(),
                  // '+' butonu için boş sayfa
                  Container(),
                ],
              ),
            ),
          ],
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
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.import_export, color: Colors.white),
                ),
                label: 'İçeri Aktar',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.file_upload, color: Colors.white),
                ),
                label: 'Dışarı Aktar',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                label: 'Sil',
              ),
            ],
            currentIndex: 0, // Hiçbir öğe seçili olarak vurgulanmamış
            onTap: (index) {
              switch (index) {
                case 0:
                  _importData();
                  break;
                case 1:
                  _exportData();
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
