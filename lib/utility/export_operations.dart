import 'package:Tablify/model/TabItem.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import '../data/database.dart';
import '../model/items.dart';

//Export Bulut link paylaş fonksiyonu #bulutt,paylaşş
Future<void> exportToFirebase(BuildContext context) async {
  // Depolama iznini kontrol ediyoruz
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    // Eğer Android 11 veya üzeri bir sürümde çalışıyorsak MANAGE_EXTERNAL_STORAGE iznini iste
    if (Platform.isAndroid &&
        await Permission.manageExternalStorage.request().isGranted) {
      status = PermissionStatus.granted;
    } else {
      status = await Permission.storage.request();
      if (status.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Depolama izni ayarlardan verilmelidir.')),
        );
        await openAppSettings();
        return;
      } else if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Depolama izni verilmedi.')),
        );
        return;
      }
    }
  }

  try {
    List<TabItem> allTabs = await SQLiteDatasource().getTabs();
    Map<String, dynamic> allData = {};

    for (TabItem tab in allTabs) {
      List<Item> tabNotes = await SQLiteDatasource().getNotes(tab.id);
      for (var note in tabNotes) {
        if (note.imageUrls != null && note.imageUrls!.isNotEmpty) {
          List<String> base64Images = [];
          for (String imageUrl in note.imageUrls!) {
            File imageFile = File(imageUrl);
            if (await imageFile.exists()) {
              String base64Image = base64Encode(imageFile.readAsBytesSync());
              base64Images.add(base64Image);
            }
          }
          note.imageUrls = base64Images;
        }
      }
      allData[tab.name] = tabNotes.map((e) => e.toMap()).toList();
    }

    String jsonData = jsonEncode(allData);
    final tempDir = await getTemporaryDirectory();
    String jsonFilePath = '${tempDir.path}/data.json';
    File jsonFile = File(jsonFilePath);
    await jsonFile.writeAsString(jsonData);

    // Dosyayı zip'leyin ve Firebase'e yükleyin
    final zipEncoder = ZipFileEncoder();
    String formattedDate =
        DateFormat('dd.MM.yyyy_HH.mm').format(DateTime.now());
    String zipFilePath = '${tempDir.path}/export_data_$formattedDate.zip';
    zipEncoder.create(zipFilePath);
    zipEncoder.addFile(jsonFile);
    zipEncoder.close();

    FirebaseStorage storage = FirebaseStorage.instance;
    File zipFile = File(zipFilePath);
    TaskSnapshot uploadTask = await storage
        .ref('tablify/exports/Tablify_dataExport_$formattedDate.zip')
        .putFile(zipFile);

    String downloadUrl = await uploadTask.ref.getDownloadURL();
    Clipboard.setData(ClipboardData(text: downloadUrl));
    await Share.share('Verileriniz burada: $downloadUrl');

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text(
          'Veriler başarıyla yüklendi ve paylaşılabilir link oluşturuldu.'),
    ));
  } catch (e) {
    print('Hata: $e');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Veri yüklenirken bir hata oluştu.'),
    ));
  }
}

//Exporta dosya olarak paylaşma fonksiyonu #dosyaa,paylaşş
Future<void> exportAsFile(BuildContext context) async {
  // Sadece Android'de depolama izinlerini kontrol ediyoruz
  if (Platform.isAndroid) {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      if (await Permission.manageExternalStorage.request().isGranted) {
        status = PermissionStatus.granted;
      } else {
        status = await Permission.storage.request();
        if (status.isPermanentlyDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Depolama izni ayarlardan verilmelidir.')),
          );
          await openAppSettings();
          return;
        } else if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Depolama izni verilmedi.')),
          );
          return;
        }
      }
    }
  }

  try {
    List<TabItem> allTabs = await SQLiteDatasource().getTabs();
    Map<String, dynamic> allData = {};

    for (TabItem tab in allTabs) {
      List<Item> tabNotes = await SQLiteDatasource().getNotes(tab.id);
      for (var note in tabNotes) {
        if (note.imageUrls != null && note.imageUrls!.isNotEmpty) {
          List<String> base64Images = [];
          for (String imageUrl in note.imageUrls!) {
            File imageFile = File(imageUrl);
            if (await imageFile.exists()) {
              String base64Image = base64Encode(await imageFile.readAsBytes());
              base64Images.add(base64Image);
            }
          }
          note.imageUrls = base64Images;
        }
      }
      allData[tab.name] = tabNotes.map((e) => e.toMap()).toList();
    }

    String jsonData = jsonEncode(allData);
    List<int> binaryData = utf8.encode(jsonData);
    List<int>? compressedData = GZipEncoder().encode(binaryData);

    // Platforma uygun dizini belirliyoruz
    Directory? directory;

    if (Platform.isAndroid || Platform.isIOS) {
      // Mobil platformlarda uygulama belgeleri dizinini kullanıyoruz
      directory = await getApplicationDocumentsDirectory();
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Masaüstü platformlarda indirilenler dizinini kullanıyoruz
      directory = await getDownloadsDirectory();
      // Eğer indirilenler dizini bulunamazsa, uygulama belgeleri dizinini kullanıyoruz
      if (directory == null) {
        directory = await getApplicationDocumentsDirectory();
      }
    } else {
      // Diğer platformlarda geçici dizini kullanıyoruz
      directory = await getTemporaryDirectory();
    }

    if (directory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Dosya kaydedilecek dizin bulunamadı.'),
      ));
      return;
    }

    String formattedDate =
        DateFormat('dd.MM.yyyy_HH.mm').format(DateTime.now());
    String filePath =
        path.join(directory.path, 'Tablify_dataExport_$formattedDate.bin');
    final file = File(filePath);
    await file.writeAsBytes(compressedData!);

    // Dosyayı paylaşma işlemi
    await Share.shareXFiles([XFile(file.path)],
        text: 'Here is your data export');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Veriler başarıyla dışa aktarıldı.')),
    );
    Navigator.of(context).pop();
  } catch (e) {
    print('Veri dışa aktarılırken hata oluştu: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Veriler dışa aktarılırken bir hata oluştu.')),
    );
  }
}

//Export Dosyayı cihazın indirilenler klasörüne kaydetme #dosyalarımakaydett
Future<void> saveToDownloads(BuildContext context) async {
  try {
    // Sadece Android'de depolama izinlerini kontrol ediyoruz
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      print("Initial storage permission status: $status");

      if (!status.isGranted) {
        // Android 11 ve üzeri için MANAGE_EXTERNAL_STORAGE izni
        if (Platform.isAndroid &&
            await Permission.manageExternalStorage.request().isGranted) {
          status = PermissionStatus.granted;
        } else {
          status = await Permission.storage.request();
          print("After permission request: $status");
        }
      }

      if (!status.isGranted) {
        if (status.isPermanentlyDenied) {
          print("Permission permanently denied");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Depolama izni kalıcı olarak reddedildi. Lütfen ayarlardan etkinleştirin.')),
          );
          await openAppSettings();
        } else {
          print("Permission denied");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Depolama izni reddedildi.')),
          );
        }
        return;
      }
    }

    // Dosya kaydetme işlemleri
    List<TabItem> allTabs = await SQLiteDatasource().getTabs();
    Map<String, dynamic> allData = {};

    for (TabItem tab in allTabs) {
      List<Item> tabNotes = await SQLiteDatasource().getNotes(tab.id);

      for (var note in tabNotes) {
        if (note.imageUrls != null && note.imageUrls!.isNotEmpty) {
          List<String> base64Images = [];
          for (String imageUrl in note.imageUrls!) {
            File imageFile = File(imageUrl);
            if (await imageFile.exists()) {
              String base64Image = base64Encode(imageFile.readAsBytesSync());
              base64Images.add(base64Image);
            }
          }
          note.imageUrls = base64Images;
        }
      }

      allData[tab.name] = tabNotes.map((e) => e.toMap()).toList();
    }

    String jsonData = jsonEncode(allData);
    List<int> binaryData = utf8.encode(jsonData);
    List<int>? compressedData = GZipEncoder().encode(binaryData);

    // Platforma uygun dizini alıyoruz
    Directory? directory;

    if (Platform.isAndroid) {
      // Android'de indirilenler klasörünü alıyoruz
      directory = Directory('/storage/emulated/0/Download');
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Masaüstü platformlarda indirilenler klasörünü alıyoruz
      directory = await getDownloadsDirectory();
    } else if (Platform.isIOS) {
      // iOS'ta belgeler dizinini kullanıyoruz
      directory = await getApplicationDocumentsDirectory();
    } else {
      // Diğer platformlar için geçici dizini kullanıyoruz
      directory = await getTemporaryDirectory();
    }

    if (directory == null) {
      print('Dizin bulunamadı');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Dosya kaydedilecek dizin bulunamadı.'),
      ));
      return;
    }

    String formattedDate =
        DateFormat('dd.MM.yyyy_HH.mm').format(DateTime.now());
    String fileName = 'Tablify_dataExport_$formattedDate.bin';
    String filePath = path.join(directory.path, fileName);

    final file = File(filePath);
    await file.writeAsBytes(compressedData!);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Dosya başarıyla indirilenler klasörüne kaydedildi'),
    ));
    Navigator.of(context).pop();
  } catch (e) {
    print('Error saving file: $e');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Dosya indirilirken bir hata oluştu.'),
    ));
  }
}

//Export HTML dosyası olarak Firebase'e yükleme #htmll
Future<void> exportAsHtml(BuildContext context) async {
  // Depolama iznini sadece Android'de kontrol ediyoruz
  if (Platform.isAndroid) {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      if (await Permission.manageExternalStorage.request().isGranted) {
        status = PermissionStatus.granted;
      } else {
        status = await Permission.storage.request();
        if (status.isPermanentlyDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Depolama izni ayarlardan verilmelidir.')),
          );
          await openAppSettings();
          return;
        } else if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Depolama izni verilmedi.')),
          );
          return;
        }
      }
    }
  }

  try {
    List<TabItem> allTabs = await SQLiteDatasource().getTabs();
    Map<String, dynamic> allData = {};

    for (TabItem tab in allTabs) {
      List<Item> tabNotes = await SQLiteDatasource().getNotes(tab.id);
      allData[tab.name] = tabNotes.map((e) => e.toMap()).toList();
    }

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

    for (var tab in allTabs) {
      htmlContent += "<fieldset><legend>${tab.name}</legend>";
      List<dynamic> items = allData[tab.name];
      for (var itemMap in items) {
        Item item = Item.fromMap(itemMap);
        htmlContent +=
            "<table border='1' cellpadding='5' style='width: 100%;'>";
        htmlContent +=
            "<tr><th style='text-align: left; width: 30%;'>Başlık</th><td>${item.headerValue}</td></tr>";
        htmlContent +=
            "<tr><th style='text-align: left;'>Alt Başlık</th><td>${item.subtitle ?? 'Yok'}</td></tr>";
        htmlContent +=
            "<tr><th style='text-align: left;'>Items</th><td><ul>${item.expandedValue.map((val) => "<li>$val</li>").join('')}</ul></td></tr>";
        htmlContent += "</table><br/>";
      }
      htmlContent += "</fieldset><br/>";
    }
    htmlContent += "</body></html>";

    // Platforma uygun dizini alıyoruz
    Directory? directory;
    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory();
      if (directory == null) {
        // Eğer getExternalStorageDirectory null dönerse, indirilenler klasörünü kullanabilirsiniz
        directory = Directory('/storage/emulated/0/Download');
      }
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      directory = await getDownloadsDirectory();
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    } else {
      directory = await getTemporaryDirectory();
    }

    if (directory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Dosya kaydedilecek dizin bulunamadı.'),
      ));
      return;
    }

    String fileName = 'export_${const Uuid().v4()}.html';
    String filePath = path.join(directory.path, fileName);
    File file = File(filePath);
    await file.writeAsString(htmlContent);

    final FirebaseStorage storage = FirebaseStorage.instance;
    TaskSnapshot uploadTask =
        await storage.ref('tablify/exports/html/$fileName').putFile(file);
    String downloadUrl = await uploadTask.ref.getDownloadURL();

    // URL'yi açıyoruz
    Uri url = Uri.parse(downloadUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL açılamadı.')),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('HTML linki kopyalandı ve tarayıcı açılıyor...'),
    ));
  } catch (e) {
    print('Hata: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('HTML export sırasında bir hata oluştu.')),
    );
  }
}
