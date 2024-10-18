import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:Tablify/model/items.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../model/TabItem.dart';

class SQLiteDatasource {
  static final SQLiteDatasource _instance = SQLiteDatasource._internal();
  late Database _database;

  factory SQLiteDatasource() {
    return _instance;
  }

  SQLiteDatasource._internal();

  // Veritabanı oluşturma
  Future<void> init() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'app_database.db');
      print("Database path: $path");

      _database = await openDatabase(
        path,
        version: 6,
        onCreate: (db, version) async {
          print("Creating tables...");
          await db.execute('''
          CREATE TABLE notes (
            id TEXT PRIMARY KEY,
            title TEXT,
            subtitle TEXT,
            items TEXT,
            imageUrls BLOB,
            isExpanded INTEGER,
            "order" INTEGER,
            tabId TEXT
          )
        ''');

          // Yeni options tablosunu oluştur
          await db.execute('''
          CREATE TABLE IF NOT EXISTS options (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            option_text TEXT NOT NULL
          )
        ''');

          // Yeni tabs tablosunu oluştur
          await db.execute('''
          CREATE TABLE IF NOT EXISTS tabs (
            id TEXT PRIMARY KEY,
            name TEXT,
            "order" INTEGER
          )
        ''');

          // Varsayılan seçenekleri ekleyin
          await db.insert('options', {
            'option_text':
                'Bugün [Dil:ingilizce] dilbilgisi üzerine çalışıyorum.'
          });
          await db.insert('options', {
            'option_text': '[İsim:Mehmet], bugün yeni bir spor rutini deniyor.'
          });
          await db.insert('options', {
            'option_text':
                '[İsim:Ahmet], [Dil:ingilizce] bir film izleyerek dinleme becerilerini geliştiriyor.'
          });
          await db.insert('options', {
            'option_text':
                'Görev Durumu: [Seçenekler:Başlamadı|Devam Ediyor|Tamamlandı]'
          });

          print("Tables and default options created successfully");
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          print("Upgrading database from version $oldVersion to $newVersion");

          // Sürüm 2'ye yükseltme işlemleri
          if (oldVersion < 2) {
            print("Applying upgrade to version 2: Creating 'options' table.");
            await db.execute('''
            CREATE TABLE IF NOT EXISTS options (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              option_text TEXT NOT NULL
            )
          ''');
            // Varsayılan seçenekleri ekleyin
            await db.insert('options', {
              'option_text':
                  'Bugün [Dil:ingilizce] dilbilgisi üzerine çalışıyorum.'
            });
            await db.insert('options', {
              'option_text':
                  '[İsim:Mehmet], bugün yeni bir spor rutini deniyor.'
            });
            await db.insert('options', {
              'option_text':
                  '[İsim:Ahmet], [Dil:ingilizce] bir film izleyerek dinleme becerilerini geliştiriyor.'
            });
            await db.insert('options', {
              'option_text':
                  'Görev Durumu: [Seçenekler:Başlamadı|Devam Ediyor|Tamamlandı]'
            });
          }

          // Sürüm 3'e yükseltme işlemleri
          if (oldVersion < 3) {
            print(
                "Applying upgrade to version 3: Adding 'tabId' column to 'notes' table.");
            await db.execute('ALTER TABLE notes ADD COLUMN tabId TEXT');
            // Mevcut notlara varsayılan 'tab1' değerini atayın
            await db.execute('UPDATE notes SET tabId = ?', ['tab1']);
          }

          // Sürüm 4'e yükseltme işlemleri
          if (oldVersion < 4) {
            print(
                "Applying upgrade to version 4: Creating 'tabs' table and inserting default tab.");
            await db.execute('''
            CREATE TABLE IF NOT EXISTS tabs (
              id TEXT PRIMARY KEY,
              name TEXT,
              "order" INTEGER
            )
          ''');
            // Varsayılan 'Tab 1' sekmesini oluşturun
            await db
                .insert('tabs', {'id': 'tab1', 'name': 'Tab 1', 'order': 0});
          }

          // Sürüm 5'e yükseltme işlemleri (Yeni düzeltmeler için)
          if (oldVersion < 5) {
            print(
                "Applying upgrade to version 5: Correcting 'notes' table schema.");
            // 'notes' tablosunu yedeklemek için geçici tablo oluşturun
            await db.execute('''
            CREATE TABLE notes_backup (
              id TEXT PRIMARY KEY,
              title TEXT,
              subtitle TEXT,
              items TEXT,
              imageUrls BLOB,
              isExpanded INTEGER,
              "order" INTEGER,
              tabId TEXT
            )
          ''');

            // Verileri yedek tabloya taşıyın
            await db.execute('''
            INSERT INTO notes_backup (id, title, subtitle, items, imageUrls, isExpanded, "order", tabId)
            SELECT id, title, subtitle, items, imageUrls, isExpanded, "order", tabId FROM notes
          ''');

            // Orijinal 'notes' tablosunu silin
            await db.execute('DROP TABLE notes');

            // Doğru şemaya sahip yeni 'notes' tablosunu oluşturun
            await db.execute('''
            CREATE TABLE notes (
              id TEXT PRIMARY KEY,
              title TEXT,
              subtitle TEXT,
              items TEXT,
              imageUrls BLOB,
              isExpanded INTEGER,
              "order" INTEGER,
              tabId TEXT
            )
          ''');

            // Verileri yedek tablodan yeni tabloya geri taşıyın
            await db.execute('''
            INSERT INTO notes (id, title, subtitle, items, imageUrls, isExpanded, "order", tabId)
            SELECT id, title, subtitle, items, imageUrls, isExpanded, "order", tabId FROM notes_backup
          ''');

            // Yedek tabloyu silin
            await db.execute('DROP TABLE notes_backup');

            print("'notes' tablosu başarıyla güncellendi.");
          }

          if (oldVersion < 6) {
            print(
                "Applying upgrade to version 6: Adding 'order' column to 'tabs' table.");
            await db.execute(
                'ALTER TABLE tabs ADD COLUMN "order" INTEGER DEFAULT 0');
            print("'order' column added to 'tabs' table.");
          }

          print(
              "Database upgrade to version $newVersion completed successfully.");
        },
      );
    } catch (e) {
      print("Error initializing database: $e");
    }
  }

  Future<String> getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'UnknownIOSDevice';
    }
    return 'UnknownDevice';
  }

  // Resim yükleme fonksiyonu (base64 olarak kaydediyoruz)
  Future<String?> uploadImage(File image) async {
    final imagePath = image.path; // Save the image path instead of base64
    return imagePath;
  }

  // Not ekleme fonksiyonu
  Future<bool> addNote(Item item) async {
    try {
      var uuid = const Uuid().v4();
      var order = DateTime.now().millisecondsSinceEpoch;

      await _database.insert('notes', {
        'id': uuid,
        'title': item.headerValue,
        'subtitle': item.subtitle,
        'items': item.expandedValue.join('||'),
        'imageUrls': item.imageUrls?.join('||') ?? '',
        'isExpanded': item.isExpanded ? 1 : 0,
        'order': order,
        'tabId': item.tabId, // 'tabId'yi ekliyoruz
      });
      print("Note added successfully");
      return true;
    } catch (e) {
      print("Error adding note: $e");
      return false;
    }
  }

  // Notları almak için fonksiyon
  Future<List<Item>> getNotes(String tabId) async {
    try {
      final List<Map<String, dynamic>> maps = await _database.query(
        'notes',
        where: 'tabId = ?',
        whereArgs: [tabId],
        orderBy: '"order"',
      );

      if (maps.isEmpty) {
        print("No data found in database for tab $tabId.");
        return [];
      }

      return List.generate(maps.length, (i) {
        return Item(
          id: maps[i]['id'],
          headerValue: maps[i]['title'],
          expandedValue: maps[i]['items'].split('||'),
          subtitle: maps[i]['subtitle'],
          imageUrls: maps[i]['imageUrls'] != ''
              ? maps[i]['imageUrls'].split('||')
              : [],
          isExpanded: maps[i]['isExpanded'] == 1,
          tabId: maps[i]['tabId'], // 'tabId'yi ekliyoruz
        );
      });
    } catch (e) {
      print("Error fetching notes for tab $tabId: $e");
      return [];
    }
  }

  // Not silme fonksiyonu
  Future<bool> deleteTable(String id) async {
    try {
      await _database.delete(
        'notes',
        where: 'id = ?',
        whereArgs: [id],
      );
      print("Note deleted successfully"); // Başarıyla silindi
      return true;
    } catch (e) {
      print("Error deleting note: $e");
      return false;
    }
  }

  // Genişletme/daraltma durumu güncelleme fonksiyonu
  Future<void> updateExpandedState(String id, bool isExpanded) async {
    try {
      await _database.update(
        'notes',
        {'isExpanded': isExpanded ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print("Error updating expanded state: $e");
    }
  }

  // Notların sırasını güncelleme fonksiyonu
  Future<void> updateNoteOrder(List<Item> data) async {
    try {
      for (int i = 0; i < data.length; i++) {
        await _database.update(
          'notes',
          {'order': i},
          where: 'id = ?',
          whereArgs: [data[i].id],
        );
      }
    } catch (e) {
      print("Error updating note order: $e");
    }
  }

  // Tüm notları silme fonksiyonu
  Future<void> deleteAllItems() async {
    try {
      await _database.delete('notes');
      print("All items deleted successfully.");
    } catch (e) {
      print("Error deleting all items: $e");
    }
  }

  // Tüm sekmeleri silme fonksiyonu
  Future<void> deleteAllTabs() async {
    try {
      await _database.delete('tabs');
      print("All tabs deleted successfully.");
    } catch (e) {
      print("Error deleting all tabs: $e");
    }
  }

// Tüm veritabanı elemanlarını (sekme ve notlar) silme fonksiyonu
  Future<void> deleteAllData() async {
    await deleteAllItems();
    await deleteAllTabs();
  }

  // Belirli bir item'ı silme fonksiyonu
  Future<bool> deleteItem(String noteId, int itemIndex) async {
    try {
      // Önce notu veritabanından çekiyoruz
      List<Map<String, dynamic>> maps = await _database.query(
        'notes',
        where: 'id = ?',
        whereArgs: [noteId],
      );

      if (maps.isNotEmpty) {
        // Notu aldık, şimdi item'ları ayırıyoruz
        String itemsString = maps.first['items'];
        List<String> items = itemsString.split('||'); // '||' ile ayırıyoruz

        // Eğer itemIndex geçerli bir index değilse silmiyoruz
        if (itemIndex >= 0 && itemIndex < items.length) {
          // Belirtilen item'ı listeden çıkarıyoruz
          items.removeAt(itemIndex);

          // Güncellenen item listesiyle notu güncelliyoruz
          await _database.update(
            'notes',
            {
              'items':
                  items.join('||'), // Listeyi tekrar '||' ile birleştiriyoruz
            },
            where: 'id = ?',
            whereArgs: [noteId],
          );
          print("Item deleted successfully from note");
          return true;
        } else {
          print("Invalid item index");
          return false;
        }
      } else {
        print("Note not found");
        return false;
      }
    } catch (e) {
      print("Error deleting item: $e");
      return false;
    }
  }

  // Aynı başlıkta bir not olup olmadığını kontrol eden fonksiyon
  Future<bool> noteExistsWithTitle(String title, String tabId) async {
    try {
      List<Map<String, dynamic>> existingNotes = await _database.query(
        'notes',
        where: 'title = ? AND tabId = ?',
        whereArgs: [title, tabId],
      );
      return existingNotes.isNotEmpty;
    } catch (e) {
      print("Error checking for existing note: $e");
      return false;
    }
  }

  Future<bool> addOrUpdateNote(Item item) async {
    try {
      // Check if a note with the same title and tabId exists
      List<Map<String, dynamic>> existingNotes = await _database.query(
        'notes',
        where: 'title = ? AND tabId = ?',
        whereArgs: [item.headerValue, item.tabId],
      );

      if (existingNotes.isNotEmpty) {
        // Update existing note
        await _database.update(
          'notes',
          {
            'title': item.headerValue,
            'subtitle': item.subtitle,
            'items': item.expandedValue.join('||'),
            'imageUrls': item.imageUrls?.join('||') ?? '',
            'isExpanded': item.isExpanded ? 1 : 0,
            'tabId': item.tabId,
          },
          where: 'title = ? AND tabId = ?',
          whereArgs: [item.headerValue, item.tabId],
        );
        print("Note updated successfully");
        return true;
      } else {
        // Insert new note
        var uuid = const Uuid().v4();
        var order = DateTime.now().millisecondsSinceEpoch;

        await _database.insert('notes', {
          'id': uuid,
          'title': item.headerValue,
          'subtitle': item.subtitle,
          'items': item.expandedValue.join('||'),
          'imageUrls': item.imageUrls?.join('||') ?? '',
          'isExpanded': item.isExpanded ? 1 : 0,
          'order': order,
          'tabId': item.tabId,
        });
        print("Note added successfully");
        return true;
      }
    } catch (e) {
      print("Error adding or updating note: $e");
      return false;
    }
  }

  Future<void> createTables(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS options (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        option_text TEXT NOT NULL
      )
    ''');
  }

  // Seçenek ekleme fonksiyonu
  Future<void> addOption(String option) async {
    await _database.insert('options', {'option_text': option});
  }

  // Tüm seçenekleri alma fonksiyonu
  Future<List<String>> getOptions() async {
    final List<Map<String, dynamic>> maps = await _database.query('options');
    return List.generate(maps.length, (i) {
      return maps[i]['option_text'] as String;
    });
  }

  // Sekme ekleme fonksiyonu
  Future<void> addTab(TabItem tabItem) async {
    await _database.insert(
      'tabs',
      tabItem.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Sekmeleri alma fonksiyonu
  Future<List<TabItem>> getTabs() async {
    final List<Map<String, dynamic>> maps = await _database.query(
      'tabs',
      orderBy: '"order" ASC', // 'order' sütununu çift tırnak içine aldık
    );
    return List.generate(maps.length, (i) {
      return TabItem.fromMap(maps[i]);
    });
  }

  // Sekme silme fonksiyonu
  Future<void> deleteTab(String id) async {
    await _database.delete('tabs', where: 'id = ?', whereArgs: [id]);
  }

  // Belirli bir sekmeye ait tüm notları silme fonksiyonu
  Future<void> deleteItemsByTabId(String tabId) async {
    try {
      await _database.delete(
        'notes',
        where: 'tabId = ?',
        whereArgs: [tabId],
      );
      print("All items deleted successfully for tab $tabId.");
    } catch (e) {
      print("Error deleting items for tab $tabId: $e");
    }
  }

  Future<void> updateTabName(String tabId, String newName) async {
    await _database.update(
      'tabs',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [tabId],
    );
  }

  Future<void> updateTabOrder(String tabId, int order) async {
    await _database.update(
      'tabs',
      {'order': order},
      where: 'id = ?',
      whereArgs: [tabId],
    );
  }
}
