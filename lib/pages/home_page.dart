import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:motion_tab_bar/MotionTabBar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:proje1/data/database.dart';
import 'package:proje1/model/items.dart';
import 'package:proje1/pages/add_item_page.dart';
import 'package:share_plus/share_plus.dart';
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

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final SQLiteDatasource _sqliteDatasource = SQLiteDatasource();
  bool _allExpanded = true;
  List<Item> _data = [];
  Map<String, bool> _localExpandedStates = {};
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData(); // Sayfa açıldığında veriyi SQLite'dan yüklüyoruz
  }

  // SQLite'dan veriyi yüklüyoruz #dbb
  Future<void> _loadData() async {
    List<Item> items = await _sqliteDatasource.getNotes();
    setState(() {
      _data = items;
      _localExpandedStates = {
        for (var item in items)
          item.id: true // Tüm öğeleri genişletilmiş yapıyoruz
      };
    });
  }

  // Tüm öğeleri genişletiyoruz #expandall
  void _expandAll(List<Item> data) {
    setState(() {
      for (var item in data) {
        item.isExpanded = true;
        _sqliteDatasource.updateExpandedState(item.id, true);
        _localExpandedStates[item.id] = true;
      }
    });
  }

  // Tüm öğeleri daraltıyoruz #collapseall
  void _collapseAll(List<Item> data) {
    setState(() {
      for (var item in data) {
        item.isExpanded = false;
        _sqliteDatasource.updateExpandedState(item.id, false);
        _localExpandedStates[item.id] = false;
      }
    });
  }

  // Tüm öğeleri genişletme veya daraltma arasında geçiş yapıyoruz #toggleexpandcollapse
  void _toggleExpandCollapse() {
    setState(() {
      if (_allExpanded) {
        _collapseAll(_data); // Eğer tüm öğeler genişlemişse, daralt
      } else {
        _expandAll(_data); // Eğer daraltılmışsa, genişlet
      }

      _allExpanded = !_allExpanded;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Cihazdaki verileri dışarı aktarır #exportdataa,dışarıaktarr
  void _exportData() async {
    List<Item> data = await _sqliteDatasource.getNotes();
    String jsonData = jsonEncode(data.map((e) => e.toMap()).toList());
    List<int> binaryData = utf8.encode(jsonData);
    List<int>? compressedData = GZipEncoder().encode(binaryData);
    final directory = await getApplicationDocumentsDirectory();
    String formattedDate =
        DateFormat('dd.MM.yyyy_HH.mm').format(DateTime.now());
    final file = File('${directory.path}/data_export_$formattedDate.bin');
    await file.writeAsBytes(compressedData!);
    await Share.shareXFiles([XFile(file.path)],
        text: 'Here is your data export');
  }

  // Cihazdaki verileri içeri aktarır #importdataa,içeriarıaktarr
  void _importData() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['bin'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      List<int> binaryData = await file.readAsBytes();
      List<int> decompressedData = GZipDecoder().decodeBytes(binaryData);
      String contents = utf8.decode(decompressedData);
      List<dynamic> jsonData = jsonDecode(contents);

      for (var item in jsonData) {
        Item newItem = Item.fromMap(item);
        // Aynı başlıkta not var mı kontrol et
        bool noteExists =
            await _sqliteDatasource.noteExistsWithTitle(newItem.headerValue);
        if (noteExists) {
          // Eğer aynı başlıkta bir not varsa, kullanıcıdan onay alalım
          bool overwriteConfirmed =
              await _showOverwriteDialog(newItem.headerValue);

          if (!overwriteConfirmed) {
            // Eğer kullanıcı onaylamazsa bu notu atla
            continue;
          }
        }
        // Kullanıcıdan onay alındıysa veya aynı başlıkta not yoksa notu ekle/güncelle
        await _sqliteDatasource.addOrUpdateNote(newItem);
      }
      _loadData();
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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddItemPage()),
    );

    if (result == true) {
      _loadData();
    }
  }

  // veritabanındaki tümverileri silme #deletealldataa,verilerisill,hepsinisill,sill
  void _deleteAllData() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Tüm Verileri Sil',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.green),
          ),
          content:
              const Text('Tüm verileri silmek istediğinizden emin misiniz?'),
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
      await _sqliteDatasource.deleteAllItems(); // SQLite'den tüm verileri sil
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
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
                  ],
                ),
                if (_data.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          style: ButtonStyle(
                            foregroundColor:
                                WidgetStateProperty.all<Color>(Colors.white),
                            overlayColor:
                                WidgetStateProperty.resolveWith<Color?>(
                              (Set<WidgetState> states) {
                                if (states.contains(WidgetState.pressed)) {
                                  return Colors.green.withOpacity(0.1);
                                }
                                return null;
                              },
                            ),
                            shadowColor:
                                WidgetStateProperty.all<Color>(Colors.grey),
                            surfaceTintColor:
                                WidgetStateProperty.all<Color>(Colors.blue),
                          ),
                          onPressed: () => _toggleExpandCollapse(),
                          child: Text(
                            _allExpanded ? 'Tümünü Daralt' : 'Tümünü Genişlet',
                            style: const TextStyle(color: Colors.green),
                          )),
                    ],
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5.0, vertical: 8.0),
                child: _buildPanel(_data),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: MotionTabBar(
        initialSelectedTab: "Sil",
        labels: const ["İçeri Aktar", "Dışarı Aktar", "Sil"],
        icons: const [Icons.import_export, Icons.file_upload, Icons.delete],
        tabSize: 50,
        tabBarHeight: 55,
        tabIconColor: Colors.green[200],
        tabIconSize: 28.0,
        tabIconSelectedSize: 26.0,
        tabSelectedColor: Colors.green[300],
        tabIconSelectedColor: Colors.white,
        tabBarColor: Colors.green[50],
        textStyle: const TextStyle(
          fontSize: 12,
          color: Colors.green,
          fontWeight: FontWeight.w500,
        ),
        onTabItemSelected: (int index) {
          setState(() {
            _tabController.index = index;
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
          });
        },
      ),
    );
  }

  //listeyi oluşturmak için bir widget oluşturuyoruz
  Widget _buildPanel(List<Item> data) {
    return Column(
      children: data.map<Widget>((Item item) {
        return Padding(
          padding: const EdgeInsets.only(
              right: 2.0, left: 2.0, bottom: 10.0, top: 2.0),
          child: ListItem(
            item: item,
            isGlobalExpanded: _allExpanded,
            isLocalExpanded: _localExpandedStates[item.id] ?? false,
            onExpandedChanged: (bool isExpanded) {
              _sqliteDatasource.updateExpandedState(item.id, isExpanded);

              setState(() {
                _localExpandedStates[item.id] = isExpanded;
                _allExpanded = _data
                    .every((item) => _localExpandedStates[item.id] ?? false);
              });
            },
            onTableEdited: () {
              _loadData();
            },
          ),
        );
      }).toList(),
    );
  }
}
