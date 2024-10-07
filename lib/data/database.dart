import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:proje1/model/items.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:convert';

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
        version: 2, // Yeni tablo eklediğimiz için versiyonu artırıyoruz
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
            "order" INTEGER
          )
        ''');

          // Yeni `options` tablosunu oluştur
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
          if (oldVersion < 2) {
            await db.execute('''
            CREATE TABLE IF NOT EXISTS options (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              option_text TEXT NOT NULL
            )
          ''');
          }
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
        'items': item.expandedValue.join('||'), // Listeyi string'e çeviriyoruz
        'imageUrls': item.imageUrls?.join('||') ?? '',
        'isExpanded': item.isExpanded ? 1 : 0,
        'order': order,
      });
      print("Note added successfully"); // Veri başarıyla eklendi
      return true;
    } catch (e) {
      print("Error adding note: $e");
      return false;
    }
  }

  // Notları almak için fonksiyon
  Future<List<Item>> getNotes() async {
    try {
      final List<Map<String, dynamic>> maps = await _database.query(
        'notes',
        orderBy: '"order"',
      );

      if (maps.isEmpty) {
        print("No data found in database.");
        return [];
      }

      return List.generate(maps.length, (i) {
        return Item(
          id: maps[i]['id'],
          headerValue: maps[i]['title'],
          expandedValue: maps[i]['items'].split('||'), // '||' ile ayırıyoruz
          subtitle: maps[i]['subtitle'],
          imageUrls: maps[i]['imageUrls']
              .split('||'), // imageUrls için de '||' kullanıyoruz
          isExpanded: maps[i]['isExpanded'] == 1,
        );
      });
    } catch (e) {
      print("Error fetching notes: $e");
      return [];
    }
  }

  // Notu güncelleme fonksiyonu
  Future<bool> updateNote(String id, String title, String subtitle,
      List<String> items, List<String> imageUrls) async {
    try {
      await _database.update(
        'notes',
        {
          'title': title,
          'subtitle': subtitle,
          'items': items.join('||'),
          'imageUrls': imageUrls.join('||'),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      return true;
    } catch (e) {
      print("Error updating note: $e");
      return false;
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
  Future<bool> noteExistsWithTitle(String title) async {
    try {
      List<Map<String, dynamic>> existingNotes = await _database.query(
        'notes',
        where: 'title = ?',
        whereArgs: [title],
      );
      return existingNotes.isNotEmpty;
    } catch (e) {
      print("Error checking for existing note: $e");
      return false; // Varsayılan olarak false döner, eğer bir hata oluşursa
    }
  }

  Future<bool> addOrUpdateNote(Item item) async {
    try {
      // Önce mevcut bir öğe var mı kontrol ediyoruz (title veya id üzerinden)
      List<Map<String, dynamic>> existingNotes = await _database.query(
        'notes',
        where: 'title = ?',
        whereArgs: [item.headerValue],
      );

      if (existingNotes.isNotEmpty) {
        // Eğer aynı başlığa sahip bir öğe varsa, güncelleriz
        await _database.update(
          'notes',
          {
            'title': item.headerValue,
            'subtitle': item.subtitle,
            'items': item.expandedValue
                .join('||'), // Listeyi '||' ile string'e çeviriyoruz
            'imageUrls': item.imageUrls?.join('||') ??
                '', // Aynı işlemi imageUrls için de yapıyoruz
          },
          where: 'title = ?',
          whereArgs: [item.headerValue],
        );
        print("Note updated successfully");
        return true;
      } else {
        // Aynı başlığa sahip öğe yoksa, yeni bir not ekleriz
        var uuid = const Uuid().v4();
        var order = DateTime.now().millisecondsSinceEpoch;

        await _database.insert('notes', {
          'id': uuid,
          'title': item.headerValue,
          'subtitle': item.subtitle,
          'items':
              item.expandedValue.join('||'), // Listeyi string'e çeviriyoruz
          'imageUrls': item.imageUrls?.join('||') ??
              '', // imageUrls için de '||' kullanıyoruz
          'isExpanded': item.isExpanded ? 1 : 0,
          'order': order,
        });
        print("Note added successfully");
        return true;
      }
    } catch (e) {
      print("Error adding or updating note: $e");
      return false;
    }
  }

  Future<void> createTables(Database _database) async {
    await _database.execute('''
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
}
