import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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

class _HomePageState extends State<HomePage> {
  final SQLiteDatasource _sqliteDatasource =
      SQLiteDatasource(); // SQLite kullanımı için veritabanını başlatıyoruz
  bool _allExpanded = true; // Tüm panellerin durumu
  List<Item> _data = []; // Veriyi yerel olarak saklamak için liste
  Map<String, bool> _localExpandedStates = {};

  @override
  void initState() {
    super.initState();
    _loadData(); // Sayfa açıldığında veriyi SQLite'dan yüklüyoruz
  }

  // SQLite'dan veriyi yüklüyoruz
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

  void _expandAll(List<Item> data) {
    setState(() {
      for (var item in data) {
        item.isExpanded = true;
        _sqliteDatasource.updateExpandedState(item.id, true);

        // Yerel genişleme durumunu da açıyoruz
        _localExpandedStates[item.id] = true;
      }
    });
  }

  void _collapseAll(List<Item> data) {
    setState(() {
      for (var item in data) {
        item.isExpanded = false;
        _sqliteDatasource.updateExpandedState(item.id, false);

        // Yerel genişleme durumunu da kapatıyoruz
        _localExpandedStates[item.id] = false;
      }
    });
  }

  void _toggleExpandCollapse() {
    setState(() {
      if (_allExpanded) {
        _collapseAll(_data); // Eğer tüm öğeler genişlemişse, daralt
      } else {
        _expandAll(_data); // Eğer daraltılmışsa, genişlet
      }

      // Tüm öğelerin durumu değiştiği için bayrağı tersine çevirin
      _allExpanded = !_allExpanded;
    });
  }

  void _exportData() async {
    // SQLite'dan veri çekiyoruz
    List<Item> data = await _sqliteDatasource.getNotes();

    // JSON stringine dönüştürüyoruz
    String jsonData = jsonEncode(data.map((e) => e.toMap()).toList());

    // JSON verisini UTF-8 byte dizisine dönüştürün
    List<int> binaryData = utf8.encode(jsonData);

    // Veriyi GZIP ile sıkıştırın
    List<int>? compressedData = GZipEncoder().encode(binaryData);

    // Cihazın belgeler dizinini alın
    final directory = await getApplicationDocumentsDirectory();

    // Dosya ismi için tarih formatını hazırlıyoruz
    String formattedDate =
        DateFormat('dd.MM.yyyy_HH.mm').format(DateTime.now());

    // Binary bir dosya oluşturuyoruz
    final file = File('${directory.path}/data_export_$formattedDate.bin');

    // Sıkıştırılmış binary veriyi dosyaya yazıyoruz
    await file.writeAsBytes(compressedData!);

    // Dosyayı share_plus kullanarak paylaşıyoruz
    await Share.shareXFiles([XFile(file.path)],
        text: 'Here is your data export');

    print(compressedData);
  }

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

      // Veriyi yeniden yükleyerek UI'yi güncelle
      _loadData();
    }
  }

  Future<bool> _showOverwriteDialog(String title) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Aynı Başlık Mevcut'),
              content: Text.rich(
                TextSpan(
                  text: '', // İlk kısım boş
                  children: <TextSpan>[
                    TextSpan(
                      text: title, // Burada başlık yer alıyor
                      style: const TextStyle(
                          fontWeight:
                              FontWeight.bold), // Sadece başlık kalın yapılıyor
                    ),
                    const TextSpan(
                      text:
                          ' başlıklı bir not zaten var. Üzerine yazmak ister misiniz?', // Diğer metin normal stil
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('İptal',
                      style: TextStyle(color: Colors.black)),
                  onPressed: () {
                    Navigator.of(context).pop(false); // Kullanıcı iptal etti
                  },
                ),
                TextButton(
                  child: const Text('Üzerine Yaz',
                      style: TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.of(context).pop(true); // Kullanıcı onayladı
                  },
                ),
              ],
            );
          },
        ) ??
        false; // Eğer kullanıcı dialogu kapatırsa false döner
  }

  void _navigateAndAddItem() async {
    // AddItemPage'e giderken, dönüşte veriyi bekliyoruz.
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddItemPage()),
    );

    // Eğer sayfadan başarılı bir şekilde veri eklenmiş olarak dönersek veriyi yeniden yüklüyoruz.
    if (result == true) {
      _loadData(); // Veriyi yeniden yükleyerek güncelliyoruz.
    }
  }

  void _deleteAllData() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tüm Verileri Sil'),
          content:
              const Text('Tüm verileri silmek istediğinizden emin misiniz?'),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal', style: TextStyle(color: Colors.black)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text(
                'Sil',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _sqliteDatasource.deleteAllItems(); // SQLite'den tüm verileri sil
      _loadData(); // UI'yı güncelle
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
            child: Text('DEV SECURE', style: TextStyle(fontSize: 25))),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              // Column kullanarak iki Row'u alt alta yerleştiriyoruz
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
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor),
                                recognizer: TapGestureRecognizer()
                                  ..onTap =
                                      _navigateAndAddItem, // Ekle butonuna tıklayınca AddItemPage'e gidiyoruz
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
                        onPressed: () => _toggleExpandCollapse(),
                        child: Text(
                            _allExpanded ? 'Tümünü Daralt' : 'Tümünü Genişlet'),
                      ),
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
          BottomAppBar(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.import_export),
                  onPressed: _importData,
                ),
                IconButton(
                  icon: const Icon(Icons.file_upload),
                  onPressed: _exportData,
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: _deleteAllData,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel(List<Item> data) {
    return Column(
      children: data.map<Widget>((Item item) {
        return Padding(
          padding: const EdgeInsets.all(2.0),
          child: ListItem(
            item: item,
            isGlobalExpanded:
                _allExpanded, // Tümünü Genişlet/Daralt durumu buradan geliyor
            isLocalExpanded: _localExpandedStates[item.id] ??
                false, // Yerel genişleme durumu
            onExpandedChanged: (bool isExpanded) {
              // Genişletme durumunu SQLite'da güncelle
              _sqliteDatasource.updateExpandedState(item.id, isExpanded);

              setState(() {
                // Tıklanan öğenin genişletme durumunu güncelle
                _localExpandedStates[item.id] = isExpanded;

                // Tümünü Genişlet/Daralt bayrağını güncelle
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
